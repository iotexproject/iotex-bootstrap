#!/bin/bash
##Setup & Upgrade Iotex MainNet / TestNet
## User local: source/bash/sh $0 [$1=testnet]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) [$1=testnet]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) [$1=testnet $2=plugin=gateway]

# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

function checkDockerPermissions() {
    docker ps > /dev/null
    if [ $? = 1 ];then
        echo -e "your $RED [$USER] $NC not privilege docker" 
        echo -e "please run $RED [sudo bash] $NC first"
        echo -e "Or docker not install "
        exit 1
    fi
}

function setVar() {
    CUR_PWD=${PWD}
    producerPrivKey=""
    externalHost=""
    defaultdatadir="$HOME/iotex-var"

    processParam $@
}

function processParam() {
    _ENV_=mainnet
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
}

function determinePluginIsChanged() {
    if [ $_PLUGINS_ ] && [ "$_PLUGINS_"X = "gateway"X ];then
        docker ps|grep 14014 > /dev/null
        if [ $? -ne 0 ];then
            _PLUGINS_CHANGE_=1
        fi
    else
        docker ps|grep 14014 > /dev/null
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

function confirmEnvironmentVariable() {
    echo -e "Confirm version: ${RED} ${version} ${NC}"
    echo -e "Confirm IOTEX_HOME directory: ${RED} ${IOTEX_HOME} ${NC}"
    read -p "Press any key to continue ... [Ctrl + c exit!] " key1
}

function deleteOldFile() {
    if [ -f "${IOTEX_HOME}/data/poll.db.bolt" ];then
        rm -f ${IOTEX_HOME}/data/poll.db.bolt
    fi
}

function preDockerCompose() {
    # set monitor home
    IOTEX_MONITOR_HOME=$IOTEX_HOME/monitor
    IOTEX_IMAGE=iotex/iotex-core:${version}
    mkdir -p $IOTEX_MONITOR_HOME

    export IOTEX_HOME IOTEX_MONITOR_HOME IOTEX_IMAGE

    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/docker-compose.yml.gateway > $IOTEX_MONITOR_HOME/docker-compose.yml.gateway
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/docker-compose.yml > $IOTEX_MONITOR_HOME/docker-compose.yml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/.env > $IOTEX_MONITOR_HOME/.env
}

function enableMonitor() {
    echo "Download config files for monitor"
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/IoTeX.json > $IOTEX_MONITOR_HOME/IoTeX.json
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/dashboards.yaml > $IOTEX_MONITOR_HOME/dashboards.yaml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/datasource.yaml > $IOTEX_MONITOR_HOME/datasource.yaml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/prometheus.yml > $IOTEX_MONITOR_HOME/prometheus.yml
}

function procssNotUpdate() {
    echo "Not Upgrade!! current plugin is not changed, current ${runversion} is running....!"
    docker start iotex
    if [ "${wantmonitor}"X = "Y"X -o "${wantmonitor}"X = "y"X -o \
                         "${wantmonitor}"X = "yes"X -o "${wantmonitor}"X = "Yes"X ];then
        preDockerCompose

        docker ps -a |grep "iotex-monitor" > /dev/null
        if [ $? -eq 0 ];then
            echo "Iotex-monitor is running....!"
            docker start iotex-monitor
        else
            enableMonitor
            cd $IOTEX_MONITOR_HOME
            docker-compose up -d --no-deps monitor
            if [ $? -eq 0 ];then
                echo -e "${YELLOW} You can access 'localhost:3000' to view node monitoring ${NC}"
                echo -e "${YELLOW} Default User/Pass: admin/admin." 
            fi
            cd $CUR_PWD
        fi
    else
        echo "Iotex-monitor is stopping....!"
        docker ps -a |grep "iotex-monitor" > /dev/null
        if [ $? -eq 0 ];then
            docker stop iotex-monitor
        fi
    fi
}

function cleanOldVersion() {
    echo -e "${YELLOW} ******  Upgrade Iotex Node ******* ${NC}"
    echo -e "${YELLOW} ***  Will stop, delete old iotex container; ${NC}"
    echo -e "${YELLOW} *** download new config and recover your externalHost producerPrivKey ${NC}"
    read -p "******* Press any key to continue ... [Ctrl + c exit!] " upgreadekey
    echo "Stop old iotex-core"
    docker stop iotex
    echo "delete old iotex docker container"
    docker rm iotex
    producerPrivKey=$(grep '^  producerPrivKey:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
    externalHost=$(grep '^  externalHost:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
}

function determineExtIp() {
    if [ ! "${externalHost}" ];then
        findip=$(curl -Ss ip.sb)
        read -p "SET YOUR EXTERNAL IP HERE [$findip]: " inputip
        ip=${inputip:-$findip}
    fi
}

function determinPrivKey() {
    if [ ! "${producerPrivKey}" ]; then
        echo "If you are a delegate, make sure producerPrivKey is the key for the operator address you have registered."
        echo  "SET YOUR PRIVATE KEY HERE(e.g., 96f0aa5e8523d6a28dc35c927274be4e931e74eaa720b418735debfcbfe712b8)"
        read -p ": " inputkey
        PrivKey=${inputkey:-"96f0aa5e8523d6a28dc35c927274be4e931e74eaa720b418735debfcbfe712b8"}
    
        echo -e "Confirm your externalHost: ${YELLOW} $ip ${NC}"
        echo -e "Confirm your producerPrivKey: ${RED} $PrivKey ${NC}"
        read -p "Press any key to continue ... [Ctrl + c exit!] " key2
        externalHost="externalHost: $ip"
        producerPrivKey="producerPrivKey: $PrivKey"
    fi 
}

function downloadConfig() {
    #(Optional) If you prefer to start from a snapshot, run the following commands:
    #curl -LSs https://t.iotex.me/${env}-data-latest > $IOTEX_HOME/data.tar.gz
    #cd ${IOTEX_HOME} && tar -xzf data.tar.gz
    echo "download new config"
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/config_${env}.yaml > $IOTEX_HOME/etc/config.yaml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/genesis_${env}.yaml > $IOTEX_HOME/etc/genesis.yaml
    # https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v0.9.2/config_mainnet.yaml
    
    echo "Update your externalHost,producerPrivKey to config.yaml"
    sed -i "/^network:/a\ \ $externalHost" $IOTEX_HOME/etc/config.yaml
    sed -i "/^chain:/a\ \ $producerPrivKey" $IOTEX_HOME/etc/config.yaml
}

function enableGateway() {
    cd $IOTEX_MONITOR_HOME
    \cp docker-compose.yml docker-compose.yml.bak
    \cp docker-compose.yml.gateway docker-compose.yml
    cd $CUR_PWD
}

function startupWithMonitor() {
    echo -e "Start iotex-server and monitor."
    cd $IOTEX_MONITOR_HOME
    docker-compose up -d --no-recreate
    if [ $? -eq 0 ];then
        echo -e "${YELLOW} If you first create monitor, you can access 'localhost:3000' to view node monitoring ${NC}"
        echo -e "${YELLOW} Default User/Pass: admin/admin." 
    fi
    cd $CUR_PWD
}

function startup() {
    echo -e "Start iotex-server."
    cd $IOTEX_MONITOR_HOME
    docker-compose up -d iotex
    docker ps | grep iotex-monitor > /dev/null
    if [ $? -eq 0 ];then
        docker stop iotex-monitor
    fi
    cd $CUR_PWD
}

function startupNode() {
    if [ "${wantmonitor}"X = "Y"X -o "${wantmonitor}"X = "y"X -o \
                         "${wantmonitor}"X = "yes"X -o "${wantmonitor}"X = "Yes"X ];then
        enableMonitor
        startupWithMonitor
        #check node running
        sleep 5
        cd $IOTEX_MONITOR_HOME
        docker-compose ps
        cd ${CUR_PWD}
    else
        startup
        #check node running
        sleep 5
        cd $IOTEX_MONITOR_HOME
        docker-compose ps iotex
        cd ${CUR_PWD}
    fi

}

function main() {
    checkDockerPermissions

    _GREP_STRING_=MainNet
    setVar $@
    lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "^- $_GREP_STRING_:"|awk '{print $3}')

    echo -e "Current operating environment: ${YELLOW}  $env ${NC}"

    read -p "Install or Upgrade Version; if null the latest [$lastversion]: " ver
    version=${ver:-"$lastversion"}   # if $ver ;then version=$ver;else version=$lastversion"

    runversion=$(docker ps -a |grep "iotex/iotex-core:v"|awk '{print$2}'|awk -F'[:]' '{print$2}')
    
    _PLUGINS_CHANGE_=0
    determinePluginIsChanged

    read -p "Do you want to monitor the status of the node [Y/N] (Default: N)? " wantmonitor

    determinIotexHome
    confirmEnvironmentVariable

    deleteOldFile
    
    if [ "$version"X = "$runversion"X ] && [ $_PLUGINS_CHANGE_ -eq 0 ];then
        procssNotUpdate
        exit 0
    fi

    if [ -f "${IOTEX_HOME}/data/chain.db" ]; then
        cleanOldVersion
    else
        echo -e "${YELLOW} ****** Install Iotex Node  ***** ${NC}"
        echo -e "${YELLOW} if installed, Confirm Input IOTEX_HOME directory True ${NC};"
        read -p "[Ctrl + c exit!]; else Enter anykey ..." anykey
        mkdir -p ${IOTEX_HOME} && cd ${IOTEX_HOME} && mkdir data log etc
    fi

    determineExtIp
    determinPrivKey

    echo "docker pull iotex-core ${version}"
    docker pull iotex/iotex-core:${version}
    # or use gcr.io/iotex-servers/iotex-core:${version}
    #Set the environment with the following commands:

    downloadConfig
    preDockerCompose
    if [ $_PLUGINS_ ] && [ "$_PLUGINS_"X = "gateway"X ];then
        enableGateway
    fi

    startupNode

    # restore file docker-compose.yml
    if [ $_PLUGINS_ ] && [ "$_PLUGINS_"X = "gateway"X ];then
        cd $IOTEX_MONITOR_HOME
        mv docker-compose.yml.bak docker-compose.yml
        cd ${CUR_PWD}
    fi
}

main $@
