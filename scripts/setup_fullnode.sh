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

_NEED_INSTALL_=0
_PLUGINS_CHANGE_=0
_AUTO_=0
_FORCE_=0
_SNAPSHOT_=0

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
        echo -e "Or docker is not installed "
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
    adminPort=""
    defaultdatadir="$HOME/iotex-var"

    processParam $@
}

function processParam() {
    _ENV_=mainnet
    _GREP_STRING_=MainNet
    for arg in "$@"; do
        case "$arg" in
            testnet)
                _ENV_=testnet
                _GREP_STRING_=TestNet
                ;;
            plugin=gateway)
                _PLUGINS_=gateway
                ;;
            --auto)
                _AUTO_=1
                ;;
            --home=*)
                IOTEX_HOME="${arg#--home=}"
                ;;
            --version=*)
                _FORCE_VERSION_="${arg#--version=}"
                ;;
            --monitor)
                _FORCE_MONITOR_=Y
                ;;
            --force)
                _FORCE_=1
                ;;
            --snapshot)
                _SNAPSHOT_=1
                ;;
        esac
    done
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

function detectIotexHome() {
    # Try to detect IOTEX_HOME from running iotex container mounts
    local detected=$(docker inspect iotex --format '{{range .HostConfig.Binds}}{{println .}}{{end}}' 2>/dev/null | grep config_override | sed 's|/etc/config.yaml:/etc/iotex/config_override.yaml:ro||')
    if [ -n "$detected" ];then
        echo "$detected"
    fi
}

function determinIotexHome() {
    # In auto mode, avoid interactive prompts.
    if [ $_AUTO_ -eq 1 ];then
        # If IOTEX_HOME is already set, just use it.
        if [ -n "$IOTEX_HOME" ];then
            echo "Using IOTEX_HOME=$IOTEX_HOME"
            return
        fi

        # Try to auto-detect IOTEX_HOME from a running container.
        local detected=$(detectIotexHome)
        if [ -n "$detected" ];then
            IOTEX_HOME="$detected"
            echo "Using auto-detected IOTEX_HOME=$IOTEX_HOME"
            return
        fi

        # In auto mode, we cannot prompt; fail fast with a clear error.
        echo "Error: --auto mode requires --home to be specified or an existing IoTeX container to detect IOTEX_HOME." >&2
        exit 1
    fi

    # Non-auto mode: optionally auto-detect and then prompt the user.
    # Auto-detect from running container
    local detected=$(detectIotexHome)
    if [ -n "$detected" ];then
        defaultdatadir="$detected"
    fi

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

function downloadFile()
{
    echo "Downloading file: $1"
    curl -Ss --connect-timeout 10 \
        --max-time 10 \
        --retry 10 \
        --retry-delay 0 \
        --retry-max-time 180 \
        $1 > $2
    response=$?
    if test "$response" != "0"; then
        echo -e "${RED} Download of configuration failed with following: $response"
        exit 1
    fi
}

function preDockerCompose() {
    # set monitor home
    IOTEX_MONITOR_HOME=$IOTEX_HOME/monitor
    IOTEX_IMAGE=iotex/iotex-core:${version}
    mkdir -p $IOTEX_MONITOR_HOME

    export IOTEX_HOME IOTEX_MONITOR_HOME IOTEX_IMAGE

    downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/docker-compose.yml.gateway" "$IOTEX_MONITOR_HOME/docker-compose.yml.gateway"
    downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/docker-compose.yml" "$IOTEX_MONITOR_HOME/docker-compose.yml.default"
    downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/.env" "$IOTEX_MONITOR_HOME/.env"
}

function enableMonitor() {
    echo "Download config files for monitor"
    downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/prometheus.yml" "$IOTEX_MONITOR_HOME/prometheus.yml"
    downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/alert.rules" "$IOTEX_MONITOR_HOME/alert.rules"
}

function checkPrivateKey() {
    _HAS_PRIVKEY_=0
    if [ -f ${IOTEX_HOME}/etc/config.yaml ];then
        grep '^  producerPrivKey:' ${IOTEX_HOME}/etc/config.yaml > /dev/null
        if [ $? -eq 0 ];then
            _HAS_PRIVKEY_=1
        fi
    fi
    # Fresh install is determined by absence of chain.db, not by key
    if [ ! -f "${IOTEX_HOME}/data/chain.db" ];then
        _NEED_INSTALL_=1
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

function backupOldConfig() {
    # Backup externalHost
    externalHost=$(grep '^  externalHost:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
    ip=$(echo "$externalHost" | awk -F':' '{print $2}' | xargs)
    if [ -z "$ip" ];then
        if [ "$_AUTO_" -eq 1 ]; then
            echo "Error: externalHost is missing or invalid in ${IOTEX_HOME}/etc/config.yaml; cannot continue auto-upgrade."
            exit 1
        else
            determineExtIp
        fi
    fi

    # Backup producerPrivKey if it exists
    if [ $_HAS_PRIVKEY_ -eq 1 ];then
        producerPrivKey=$(grep '^  producerPrivKey:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
        privKey=$(echo $producerPrivKey|awk -F':' '{print$2}')
    else
        echo "No producerPrivKey found — node will use a random key"
        privKey=""
        producerPrivKey=""
    fi

    # Extract existing admin port
    adminPort=$(grep '^  httpAdminPort:' ${IOTEX_HOME}/etc/config.yaml|awk -F':' '{print$2}'|tr -d ' ')
}

function stopAndRemoveContainer() {
    echo "Stop old iotex-core (downtime starts now)"
    docker stop iotex
    echo "delete old iotex docker container"
    docker rm iotex
}

function determineExtIp() {
    # Check if an existing config already has externalHost
    if [ -f "${IOTEX_HOME}/etc/config.yaml" ];then
        local existingIp=$(grep '^  externalHost:' ${IOTEX_HOME}/etc/config.yaml 2>/dev/null | awk -F': ' '{print $2}' | tr -d ' "')
        if [ -n "$existingIp" ];then
            echo "Using existing externalHost from config.yaml: $existingIp"
            ip="$existingIp"
            externalHost="externalHost: $ip"
            return
        fi
    fi

    # Force IPv4 — p2p layer does not handle IPv6
    findip=$(curl -4 -Ss ip.sb)
    if [ $_AUTO_ -eq 1 ];then
        ip=$findip
    else
        read -p "SET YOUR EXTERNAL IP HERE [$findip]: " inputip
        ip=${inputip:-$findip}
    fi
    externalHost="externalHost: $ip"
}

function determinPrivKey() {
    # Check if an existing config already has a producerPrivKey
    if [ -f "${IOTEX_HOME}/etc/config.yaml" ];then
        local existingKey=$(grep '^  producerPrivKey:' ${IOTEX_HOME}/etc/config.yaml 2>/dev/null | awk -F': ' '{print $2}' | tr -d ' "')
        if [ -n "$existingKey" ];then
            echo "Using existing producerPrivKey from config.yaml"
            privKey="$existingKey"
            producerPrivKey="producerPrivKey: $privKey"
            return
        fi
    fi

    if [ $_AUTO_ -eq 1 ];then
        # Auto-generate a random private key as temp operator wallet
        privKey=$(openssl rand -hex 32)
        echo -e "${YELLOW}Auto-generated temporary operator key: $privKey${NC}"
        echo -e "${YELLOW}To use your own key, update producerPrivKey in \$IOTEX_HOME/etc/config.yaml and restart.${NC}"
    else
        echo "If you are a delegate, make sure producerPrivKey is the key for the operator address you have registered."
        echo  "SET YOUR PRIVATE KEY HERE(e.g., 96f0aa5e8523d6a28dc35c927274be4e931e74eaa720b418735debfcbfe712b8)"
        read -p ": " inputkey
        privKey=${inputkey:-"96f0aa5e8523d6a28dc35c927274be4e931e74eaa720b418735debfcbfe712b8"}
    fi
    producerPrivKey="producerPrivKey: $privKey"
}

function determineAdminPort() {
    # Check if an existing config already has adminPort
    if [ -f "${IOTEX_HOME}/etc/config.yaml" ];then
        local existingPort=$(grep '^  httpAdminPort:' ${IOTEX_HOME}/etc/config.yaml 2>/dev/null | awk -F':' '{print $2}' | tr -d ' ')
        if [ -n "$existingPort" ];then
            echo "Using existing adminPort from config.yaml: $existingPort"
            adminPort="$existingPort"
            return
        fi
    fi

    if [ $_AUTO_ -eq 1 ];then
        return
    fi
    echo "Enable admin port for node management."
    read -p "SET ADMIN PORT (press Enter to skip, e.g., 9009): " inputport
    if [ -n "$inputport" ]; then
        # Validate port number (1-65535)
        if [[ "$inputport" =~ ^[0-9]+$ ]] && [ "$inputport" -ge 1 ] && [ "$inputport" -le 65535 ]; then
            adminPort=$inputport
            echo "Admin port set to: $adminPort"
        else
            echo -e "${RED}Invalid port number. Skipping admin port setup.${NC}"
        fi
    fi
}

function addAdminPortToCompose() {
    if [ -n "$adminPort" ]; then
        local composeFile="$IOTEX_MONITOR_HOME/docker-compose.yml"
        # Check if port mapping already exists to avoid duplicates
        if grep -q "${adminPort}:${adminPort}" $composeFile; then
            echo "Admin port mapping ${adminPort}:${adminPort} already exists in docker-compose.yml"
            return
        fi
        echo "Adding admin port mapping to docker-compose.yml"
        # Use awk for reliable cross-platform replacement with proper indentation
        awk -v port="$adminPort" '{
            print
            if (/^[[:space:]]*- 4689:4689/) {
                printf "      - %s:%s\n", port, port
            }
        }' "$composeFile" > "${composeFile}.tmp" && mv "${composeFile}.tmp" "$composeFile"
    fi
}

function downloadConfig() {
    echo "download new config"
    downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/config_${env}.yaml" "$IOTEX_HOME/etc/config.yaml"
    downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/genesis_${env}.yaml" "$IOTEX_HOME/etc/genesis.yaml"

    #Download patch file
    if [ "${_ENV_}X" = "mainnetX" ];then
        echo -e "Downloading the patch file"
        downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/trie.db.patch" "$IOTEX_HOME/data/trie.db.patch"
    fi

    SED_IS_GNU=0
    sedCheck
    echo "Update your externalHost,producerPrivKey to config.yaml"
    if [ $SED_IS_GNU -eq 1 ];then
        sed -i "/^network:/a\ \ $externalHost" $IOTEX_HOME/etc/config.yaml
        if [ -n "$producerPrivKey" ];then
            sed -i "/^chain:/a\ \ $producerPrivKey" $IOTEX_HOME/etc/config.yaml
        fi
        # Add admin port if set
        if [ -n "$adminPort" ]; then
            echo "Adding httpAdminPort: $adminPort to config.yaml"
            # Check if system: section exists
            if grep -q "^system:" $IOTEX_HOME/etc/config.yaml; then
                sed -i "/^system:/a\ \ httpAdminPort: $adminPort" $IOTEX_HOME/etc/config.yaml
            else
                # Add system: section with httpAdminPort at the end of file
                echo -e "\nsystem:\n  httpAdminPort: $adminPort" >> $IOTEX_HOME/etc/config.yaml
            fi
        fi
    else
        sed -i '' "/^network:/a\
\ \ $externalHost
" $IOTEX_HOME/etc/config.yaml
        if [ -n "$producerPrivKey" ];then
            sed -i '' "/^chain:/a\
\ \ $producerPrivKey
" $IOTEX_HOME/etc/config.yaml
        fi
        # Add admin port if set
        if [ -n "$adminPort" ]; then
            echo "Adding httpAdminPort: $adminPort to config.yaml"
            # Check if system: section exists
            if grep -q "^system:" $IOTEX_HOME/etc/config.yaml; then
                sed -i '' "/^system:/a\\
\ \ httpAdminPort: $adminPort\\
" $IOTEX_HOME/etc/config.yaml
            else
                # Add system: section with httpAdminPort at the end of file
                echo -e "\nsystem:\n  httpAdminPort: $adminPort" >> $IOTEX_HOME/etc/config.yaml
            fi
        fi
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
    NODE_MAINNET_CORE_URL=https://t.iotex.me/mainnet-data-snapshot-core-latest
    NODE_TESTNET_CORE_URL=https://t.iotex.me/testnet-data-snapshot-core-latest
    NODE_MAINNET_GATEWAY_URL=https://t.iotex.me/mainnet-data-snapshot-gateway-latest
    NODE_TESTNET_GATEWAY_URL=https://t.iotex.me/testnet-data-snapshot-gateway-latest

    SAVE_DIR=$IOTEX_HOME/tmp
    mkdir -p $SAVE_DIR

    echo -e "${YELLOW} Downloading the core snapshot...${NC}"
    if [ "${_ENV_}X" = "mainnetX" ];then
        curl -L -C - -o $SAVE_DIR/data-core.tar.gz $NODE_MAINNET_CORE_URL
    else
        curl -L -C - -o $SAVE_DIR/data-core.tar.gz $NODE_TESTNET_CORE_URL
    fi
    echo -e "${YELLOW} Unzipping core snapshot...${NC}"
    tar xvf $SAVE_DIR/data-core.tar.gz -C $IOTEX_HOME
    echo -e "${YELLOW} Core snapshot done.${NC}"

    if [ "${_PLUGINS_}X" = "gatewayX" ];then
        echo -e "${YELLOW} Downloading the gateway snapshot...${NC}"
        if [ "${_ENV_}X" = "mainnetX" ];then
            curl -L -C - -o $SAVE_DIR/data-gateway.tar.gz $NODE_MAINNET_GATEWAY_URL
        else
            curl -L -C - -o $SAVE_DIR/data-gateway.tar.gz $NODE_TESTNET_GATEWAY_URL
        fi
        echo -e "${YELLOW} Unzipping gateway snapshot...${NC}"
        tar xvf $SAVE_DIR/data-gateway.tar.gz -C $IOTEX_HOME
        echo -e "${YELLOW} Gateway snapshot done.${NC}"
    fi

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
        echo -e "${YELLOW} ******  Detect the auto-update is running , it will stop and clean ******* ${NC}"
        pid=$(ps -ef | grep "$IOTEX_HOME/bin/auto-update" | grep -v grep | awk '{print $2}')
        kill -9 $pid > /dev/null 2>&1
        rm -f $IOTEX_HOME/bin/auto-update $IOTEX_HOME/bin/update_silence.sh
    fi
}

function startAutoUpdate() {
    # Download auto-update command
    mkdir -p $IOTEX_HOME/bin
    if [ "$(uname)"X = "Darwin"X ];then
        downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/tools/auto-update/auto-update_darwin-amd64" "$IOTEX_HOME/bin/auto-update" || exit 1
    else
        downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/tools/auto-update/auto-update_linux-amd64" "$IOTEX_HOME/bin/auto-update" || exit 1
    fi

    downloadFile "https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/update_silence.sh" "$IOTEX_HOME/bin/update_silence.sh" || exit 1
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

    # Interactive setup phase
    if [ $_AUTO_ -eq 1 ];then
        wantmonitor=${_FORCE_MONITOR_:-N}
    else
        read -p "Do you want to monitor the status of the node [Y/N] (Default: N)? " wantmonitor
    fi

    if [ $_PLUGINS_ ] && [ "$_PLUGINS_"X = "gateway"X ];then
        plugins=Y
    else
        plugins=N
    fi

    if [ $_AUTO_ -eq 0 ];then
        read -p "Do you want to enable gateway plugin [Y/N] (Default: $plugins)? " plugins
        if [ "${plugins}X" = "yX" ] || [ "${plugins}X" = "YX" ];then
            _PLUGINS_=gateway
            echo "Gateway plugin enabled"
        fi
    fi

    # Get the latest version.
    lastversion=$(curl -sS https://api.github.com/repos/iotexproject/iotex-core/releases/latest|grep -oP '(?<="tag_name": ")[^"]*')
    if [ "$_GREP_STRING_" = "TestNet" ];then
        lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README_testnet.md|grep "^- $_GREP_STRING_:"|awk '{print $3}')
    fi

    echo -e "Current operating environment: ${YELLOW}  $env ${NC}"
    if [ $_AUTO_ -eq 1 ];then
        version=${_FORCE_VERSION_:-"$lastversion"}
    else
        read -p "Install or Upgrade Version; if null the latest [$lastversion]: " ver
        version=${ver:-"$lastversion"}   # if $ver ;then version=$ver;else version=$lastversion"
    fi

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

        if [ "$version"X = "$runversion"X ] && [ $_PLUGINS_CHANGE_ -eq 0 ] && [ $_FORCE_ -eq 0 ];then
            # Do nothing
            procssNotUpdate
            exit 0
        fi
    fi

    # Need update or install
    _IS_UPGRADE_=0
    if [ -f "${IOTEX_HOME}/data/chain.db" ];then
        _IS_UPGRADE_=1
        # Backup config while node is still running
        backupOldConfig
    else
        determineExtIp
        determinPrivKey
        determineAdminPort

        echo -e "${YELLOW} ****** Install IoTeX Node  ***** ${NC}"
        if [ $_AUTO_ -eq 0 ];then
            echo -e "${YELLOW} if installed, Confirm Input IOTEX_HOME directory $IOTEX_HOME True ${NC};"
            read -p "[Ctrl + c exit!]; else Enter anykey ..." anykey
        else
            echo -e "${YELLOW} Installing to $IOTEX_HOME ${NC}"
        fi

        mkdir -p ${IOTEX_HOME}
        pushd ${IOTEX_HOME}
        mkdir data log etc > /dev/null 2>&1
        popd
    fi

    echo -e "Confirm your externalHost: ${YELLOW} $ip ${NC}"
    echo -e "Confirm your producerPrivKey: ${RED} $privKey ${NC}"
    if [ -n "$adminPort" ]; then
        echo -e "Confirm your adminPort: ${YELLOW} $adminPort ${NC}"
    fi

    wantdownload=N
    if [ $_AUTO_ -eq 1 ] && [ $_SNAPSHOT_ -eq 1 ];then
        wantdownload=Y
    elif [ $_AUTO_ -eq 0 ];then
        read -p "Do you prefer to start from a snapshot, This will overwrite existing data. Download the db file. [Y/N] (Default: N)? " wantdownload
        if [ "$_PLUGINS_"X = "gateway"X ];then
            if [[ "$runversion" == "v1.1"* && "$version" == "v1.2"* ]] && ([ "$wantdownload"X = "N"X ] || [ "$wantdownload"X = "n"X ]);then
                read -p "Confirm that the current bloomfilter.index.db file will be deleted to be forward-compatible." dbf
                pushd ${IOTEX_HOME}
                rm -f data/bloomfilter.index.db || echo 'Not exist bloomfilter.index.db.'
                popd
            fi
        fi

    fi

    # Last chance to bail out before making changes
    if [ $_IS_UPGRADE_ -eq 1 ] && [ $_AUTO_ -eq 0 ];then
        echo -e "${YELLOW} ******  Upgrade IoTeX Node ******* ${NC}"
        echo -e "${YELLOW} ***  Will pull new image, download config, then stop and replace the container. ${NC}"
        read -p "******* Press any key to continue ... [Ctrl + c exit!] " upgreadekey
    fi

    # All heavy downloads happen while the old node is still running
    echo "docker pull iotex-core ${version}"
    docker pull iotex/iotex-core:${version}
    # or use gcr.io/iotex-servers/iotex-core:${version}

    downloadConfig
    preDockerCompose
    if [ $_PLUGINS_ ] && [ "$_PLUGINS_"X = "gateway"X ];then
        enableGateway
    else
        disableGateway
    fi

    # Add admin port mapping to docker-compose.yml if set
    addAdminPortToCompose

    # --- Downtime starts here: stop old container as late as possible ---
    if [ $_IS_UPGRADE_ -eq 1 ];then
        stopAndRemoveContainer
    fi

    deleteOldFile

    # Extract snapshot after container is stopped (writes to mounted data dir)
    if [ "${wantdownload}X" = "YX" ] || [ "${wantdownload}X" = "yX" ];then
        donwloadBlockDataFile
    fi

    startupNode
    # --- Downtime ends here ---

    checkAndCleanAutoUpdate
}

main $@
