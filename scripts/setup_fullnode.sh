#!/bin/bash
##Setup & Upgrade IoTeX MainNet / TestNet
## User local: source/bash/sh $0 [$1=testnet]
## User local: source/bash/sh $0 [$1=testnet $2=plugin=gateway]
## User local: source/bash/sh $0 [$1=testnet $2=plugin=gateway $3=auto-update=on]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) [$1=testnet]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) [$1=testnet $2=plugin=gateway]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) [$1=testnet $2=plugin=gateway $3=auto-update=on]

# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

_AUTO_UPDATE_=N
_NEED_INSTALL_=0
_PLUGINS_CHANGE_=0

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

function sedCheck() {
    sed --version > /dev/null 2>&1
    if [ $? -eq 0 ];then
        sed --version|grep 'GNU sed' > /dev/null 2>&1
        if [ $? -eq 0 ];then
            SED_IS_GNU=1
        fi
    fi
}

function checkDockerPermissions() {
    docker ps > /dev/null 2>&1
    if [ $? = 1 ];then
        echo -e "your $RED [$USER] $NC not privilege docker" 
        echo -e "please run $RED [sudo bash] $NC first"
        echo -e "Or docker not install "
        exit 1
    fi
}

function checkDockerCompose() {
    docker-compose --version > /dev/null 2>&1
    if [ $? -eq 127 ];then
        echo -e "$RED docker-compose command not found $NC"
        echo -e "Please install it first"
        exit 1
    fi
}

function setVar() {
    producerPrivKey=""
    externalHost=""
    defaultdatadir="$HOME/iotex-var"

    processParam $@
}

function processParam() {
    _ENV_=mainnet
    _GREP_STRING_=MainNet
    if [ $# -gt 0 ];then
        if [ "$1"X = "testnet"X ];then
            _ENV_=testnet
            _GREP_STRING_=TestNet
        elif [ "$1"X = "plugin=gateway"X ];then
            _PLUGINS_=gateway
        fi
    fi
    if [ $# -gt 1 ];then
        if [ "$2"X = "testnet"X ];then
            _ENV_=testnet
            _GREP_STRING_=TestNet
        elif [ "$2"X = "plugin=gateway"X ];then
            _PLUGINS_=gateway
        fi
    fi
    env=$_ENV_

    # Use for auto-update
    export _GREP_STRING_ _ENV_
}

function determinePluginIsChanged() {
    if [ $_PLUGINS_ ] && [ "$_PLUGINS_"X = "gateway"X ];then
        docker ps|grep 14014 > /dev/null 2>&1
        if [ $? -ne 0 ];then
            _PLUGINS_CHANGE_=1
        fi
    else
        docker ps|grep 14014 > /dev/null 2>&1
        if [ $? -eq 0 ];then
            _PLUGINS_CHANGE_=1
        fi
    fi
}

function determinIotexHome() {
    ##Input Data Dir
    echo "The current user of the input directory must have write permission!!!"
    echo -e "${RED} If Upgrade ; input your old directory \$IOTEX_HOME !!! ${NC}"
    
    #while True: do
    read -p "Input your \$IOTEX_HOME [e.g., $defaultdatadir]: " inputdir
    IOTEX_HOME=${inputdir:-"$defaultdatadir"}
}

function deleteOldFile() {
    if [ -f "${IOTEX_HOME}/data/poll.db.bolt" ];then
        rm -f ${IOTEX_HOME}/data/poll.db.bolt > /dev/null 2>&1
    fi
}

function preDockerCompose() {
    # set monitor home
    IOTEX_MONITOR_HOME=$IOTEX_HOME/monitor
    IOTEX_IMAGE=iotex/iotex-core:${version}
    mkdir -p $IOTEX_MONITOR_HOME

    export IOTEX_HOME IOTEX_MONITOR_HOME IOTEX_IMAGE

    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/docker-compose.yml.gateway > $IOTEX_MONITOR_HOME/docker-compose.yml.gateway
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/docker-compose.yml > $IOTEX_MONITOR_HOME/docker-compose.yml.default
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/.env > $IOTEX_MONITOR_HOME/.env
}

function enableMonitor() {
    echo "Download config files for monitor"
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/prometheus.yml > $IOTEX_MONITOR_HOME/prometheus.yml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/alert.rules > $IOTEX_MONITOR_HOME/alert.rules
}

function checkPrivateKey() {
    if [ -f ${IOTEX_HOME}/etc/config.yaml ];then
        grep '^  producerPrivKey:' ${IOTEX_HOME}/etc/config.yaml > /dev/null
        if [ $? -ne 0 ];then
            _NEED_INSTALL_=1
        fi
    fi
}


function procssNotUpdate() {
    echo "Not Upgrade!! current plugin is not changed, current ${runversion} is running....!"
    docker start iotex
    if [ "${wantmonitor}"X = "Y"X -o "${wantmonitor}"X = "y"X -o \
                         "${wantmonitor}"X = "yes"X -o "${wantmonitor}"X = "Yes"X ];then
        preDockerCompose

        docker ps -a |grep "iotex-monitor" > /dev/null 2>&1
        if [ $? -eq 0 ];then
            echo "iotex-monitor is running....!"
            docker start iotex-monitor
        else
            enableMonitor
            pushd $IOTEX_MONITOR_HOME
            docker-compose up -d --no-deps monitor
            if [ $? -eq 0 ];then
                echo -e "${YELLOW} You can access 'localhost:3000' to view node monitoring ${NC}"
                echo -e "${YELLOW} Default User/Pass: admin/admin. ${NC}"
            fi
            popd
        fi
    else
        echo "iotex-monitor is stopping....!"
        docker ps -a |grep "iotex-monitor" > /dev/null 2>&1
        if [ $? -eq 0 ];then
            docker stop iotex-monitor
        fi
    fi
}

function cleanOldVersion() {
    echo "Stop old iotex-core"
    docker stop iotex
    echo "delete old iotex docker container"
    docker rm iotex
    if [ $_NEED_INSTALL_ -eq 0 ];then
        echo -e "${YELLOW} ******  Upgrade IoTeX Node ******* ${NC}"
        echo -e "${YELLOW} ***  Will stop, delete old iotex container; ${NC}"
        echo -e "${YELLOW} *** download new config and recover your externalHost producerPrivKey ${NC}"
        read -p "******* Press any key to continue ... [Ctrl + c exit!] " upgreadekey

        # Has old producerPrivKey and externalHost
        producerPrivKey=$(grep '^  producerPrivKey:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
        externalHost=$(grep '^  externalHost:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
        privKey=$(echo $producerPrivKey|awk -F':' '{print$2}')
        ip=$(echo $externalHost|awk -F':' '{print$2}')
    else
        # No old producerPrivKey and externalHost
        determineExtIp
        determinPrivKey
    fi
}

function determineExtIp() {
    findip=$(curl -Ss ip.sb)
    read -p "SET YOUR EXTERNAL IP HERE [$findip]: " inputip
    ip=${inputip:-$findip}
    externalHost="externalHost: $ip"
}

function determinPrivKey() {
    echo "If you are a delegate, make sure producerPrivKey is the key for the operator address you have registered."
    echo  "SET YOUR PRIVATE KEY HERE(e.g., 96f0aa5e8523d6a28dc35c927274be4e931e74eaa720b418735debfcbfe712b8)"
    read -p ": " inputkey
    privKey=${inputkey:-"96f0aa5e8523d6a28dc35c927274be4e931e74eaa720b418735debfcbfe712b8"}
    producerPrivKey="producerPrivKey: $privKey"
}

function downloadConfig() {
    echo "download new config"
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/config_${env}.yaml > $IOTEX_HOME/etc/config.yaml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/genesis_${env}.yaml > $IOTEX_HOME/etc/genesis.yaml
    # https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v0.9.2/config_mainnet.yaml

    SED_IS_GNU=0
    sedCheck
    echo "Update your externalHost,producerPrivKey to config.yaml"
    if [ $SED_IS_GNU -eq 1 ];then
        sed -i "/^network:/a\ \ $externalHost" $IOTEX_HOME/etc/config.yaml
        sed -i "/^chain:/a\ \ $producerPrivKey" $IOTEX_HOME/etc/config.yaml
    else
        sed -i '' "/^network:/a\ 
\ \ $externalHost
" $IOTEX_HOME/etc/config.yaml
        sed -i '' "/^chain:/a\ 
\ \ $producerPrivKey
" $IOTEX_HOME/etc/config.yaml
    fi
}

function enableGateway() {
    pushd $IOTEX_MONITOR_HOME
    \cp docker-compose.yml.gateway docker-compose.yml
    popd
}

function disableGateway() {
    pushd $IOTEX_MONITOR_HOME
    \cp docker-compose.yml.default docker-compose.yml
    popd
}

function donwloadBlockDataFile() {
    NODE_GATEWAY_MAINNET_DATA_URL=https://t.iotex.me/mainnet-data-with-idx-latest
    NODE_GATEWAY_TESTNET_DATA_URL=https://t.iotex.me/testnet-data-with-idx-latest
    NODE_MAINNET_DATA_URL=https://t.iotex.me/mainnet-data-latest
    NODE_TESTNET_DATA_URL=https://t.iotex.me/testnet-data-latest

    SAVE_DIR=$IOTEX_HOME/tmp
    mkdir -p $SAVE_DIR
    DATA_FILE_PATH=$SAVE_DIR/data.tar.gz

    UNZIP_FILE_CMD="tar xvf $SAVE_DIR/data.tar.gz -C $IOTEX_HOME"

    echo -e "${YELLOW} Downloading the db file from a snapshot...${NC}"
    if [ "${_PLUGINS_}X" = "gatewayX" ];then
        if [ "${_ENV_}X" = "mainnetX" ];then
            curl -sSL $NODE_GATEWAY_MAINNET_DATA_URL > $DATA_FILE_PATH
        else
            curl -sSL $NODE_GATEWAY_TESTNET_DATA_URL > $DATA_FILE_PATH
        fi
    else
        if [ "${_ENV_}X" = "mainnetX" ];then
            curl -sSL $NODE_MAINNET_DATA_URL > $DATA_FILE_PATH
        else
            curl -sSL $NODE_TESTNET_DATA_URL > $DATA_FILE_PATH
        fi
    fi
    echo -e "${YELLOW} Unzipping...${NC}"
    $UNZIP_FILE_CMD
    echo -e "${YELLOW} Done.${NC}"
}

function startupWithMonitor() {
    echo -e "Start iotex-server and monitor."
    pushd $IOTEX_MONITOR_HOME
    docker-compose up -d --no-recreate
    if [ $? -eq 0 ];then
        echo -e "${YELLOW} If you first create monitor, you can access 'localhost:3000' to view node monitoring ${NC}"
        echo -e "${YELLOW} Default User/Pass: admin/admin. ${NC}" 
    fi
    popd
}

function startup() {
    echo -e "Start iotex-server."
    pushd $IOTEX_MONITOR_HOME
    docker-compose up -d iotex
    docker ps | grep iotex-monitor|grep -v grep > /dev/null 2>&1
    if [ $? -eq 0 ];then
        docker stop iotex-monitor
    fi
    popd
}

function startupNode() {
    if [ "${wantmonitor}"X = "Y"X -o "${wantmonitor}"X = "y"X -o \
                         "${wantmonitor}"X = "yes"X -o "${wantmonitor}"X = "Yes"X ];then
        enableMonitor
        startupWithMonitor
        #check node running
        sleep 5
        pushd $IOTEX_MONITOR_HOME
        docker-compose ps
        popd
    else
        startup
        #check node running
        sleep 5
        pushd $IOTEX_MONITOR_HOME
        docker-compose ps iotex
        popd
    fi

}

function checkAndCleanAutoUpdate() {
    ps -ef | grep "$IOTEX_HOME/bin/auto-update"| grep -v grep > /dev/null 2>&1
    if [ $? -eq 0 ];then
        pid=$(ps -ef | grep "$IOTEX_HOME/bin/auto-update" | grep -v grep | awk '{print $2}')
        kill -9 $pid > /dev/null 2>&1
        rm -f $IOTEX_HOME/bin/auto-update $IOTEX_HOME/bin/update_silence.sh
        _AUTO_UPDATE_=Y
    fi
}

function startAutoUpdate() {
    # Download auto-update command
    mkdir -p $IOTEX_HOME/bin
    if [ "$(uname)"X = "Darwin"X ];then
        curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/tools/auto-update/auto-update_darwin-amd64 > $IOTEX_HOME/bin/auto-update || exit 1
    else
        curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/tools/auto-update/auto-update_linux-amd64 > $IOTEX_HOME/bin/auto-update || exit 1
    fi

    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/update_silence.sh > $IOTEX_HOME/bin/update_silence.sh || exit 1
    chmod +x $IOTEX_HOME/bin/auto-update $IOTEX_HOME/bin/update_silence.sh

    # Run background
    nohup $IOTEX_HOME/bin/auto-update > $IOTEX_HOME/log/update.log 2>&1 &
    echo -e "${YELLOW} Auto-update is on. it will auto update every 3 days. ${NC}"
}

function main() {
    # Check and clean
    checkDockerPermissions     # Determine the current user can run docker
    checkDockerCompose         # Determin the docker-compose is installed
    setVar $@                  # Set global variable
    determinIotexHome          # Determine the $IOTEX_HOME
    checkPrivateKey            # Determine the producerPrivKey in the config file is exist.
    checkAndCleanAutoUpdate    # Check if auto-update is installed, then kill and clean it.

    deleteOldFile              # Clean up historical legacy files
    
    # Interactive setup phase
    read -p "Do you want to monitor the status of the node [Y/N] (Default: N)? " wantmonitor
    if [ "${_AUTO_UPDATE_}X" != "YX" ];then
        read -p "Do you want to auto update the node [Y/N] (Default: Y)? " _AUTO_UPDATE_
        # To upper
        if [ "${_AUTO_UPDATE_}X" = "nX" ];then
            _AUTO_UPDATE_=N
        fi
          if [ "${_AUTO_UPDATE_}X" = "yX" ];then
            _AUTO_UPDATE_=Y
        fi
    fi

    # Get the latest version.
    lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "^- $_GREP_STRING_:"|awk '{print $3}')

    echo -e "Current operating environment: ${YELLOW}  $env ${NC}"
    read -p "Install or Upgrade Version; if null the latest [$lastversion]: " ver
    version=${ver:-"$lastversion"}   # if $ver ;then version=$ver;else version=$lastversion"

    # Get the running version.
    docker ps -a |grep "iotex/iotex-core:v" > /dev/null 2>&1
    if [ $? -eq 0 ];then
        runversion=$(docker ps -a |grep "iotex/iotex-core:v"|awk '{print$2}'|awk -F'[:]' '{print$2}')
    fi

    # Determine is need to update or install or do nothing.
    if [ $_NEED_INSTALL_ -eq 0 ];then
        # the producerPrivKey in the config file is exist. Normal
        # Check if the plugin needs to be changed
        determinePluginIsChanged

        if [ "$version"X = "$runversion"X ] && [ $_PLUGINS_CHANGE_ -eq 0 ];then
            # Do nothing
            procssNotUpdate
            if [ "$_AUTO_UPDATE_"X = "Y"X ];then
                # Need set auto-update
                echo -e "${YELLOW} Restarting auto-update..."
                startAutoUpdate
            fi
            exit 0
        fi
    fi

    # Need update or install
    if [ -f "${IOTEX_HOME}/data/chain.db" ];then
        # Clean old version.
        cleanOldVersion
    else
        determineExtIp
        determinPrivKey

        echo -e "${YELLOW} ****** Install IoTeX Node  ***** ${NC}"
        echo -e "${YELLOW} if installed, Confirm Input IOTEX_HOME directory $IOTEX_HOME True ${NC};"
        read -p "[Ctrl + c exit!]; else Enter anykey ..." anykey
        
        mkdir -p ${IOTEX_HOME}
        pushd ${IOTEX_HOME}
        mkdir data log etc > /dev/null 2>&1
        popd

        wantdownload=N
        read -p "Do you prefer to start from a snapshot, Download the db file. [Y/N] (Default: N)? " wantdownload
        if [ "${wantdownload}X" = "YX" ] || [ "${wantdownload}X" = "yX" ];then
            # Download db file
            donwloadBlockDataFile
        fi
    fi

    echo -e "Confirm your externalHost: ${YELLOW} $ip ${NC}"
    echo -e "Confirm your producerPrivKey: ${RED} $privKey ${NC}"
    read -p "Press any key to continue ... [Ctrl + c exit!] " key2

    echo "docker pull iotex-core ${version}"
    docker pull iotex/iotex-core:${version}
    # or use gcr.io/iotex-servers/iotex-core:${version}
    #Set the environment with the following commands:

    downloadConfig
    preDockerCompose
    if [ $_PLUGINS_ ] && [ "$_PLUGINS_"X = "gateway"X ];then
        enableGateway
    else
        disableGateway
    fi

    startupNode

    if [ "$_AUTO_UPDATE_"X != "N"X ];then
        startAutoUpdate
    fi
}

main $@
