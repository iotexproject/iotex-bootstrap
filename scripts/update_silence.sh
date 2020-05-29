#!/bin/bash
## Upgrade Iotex MainNet / TestNet Silence none params

# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color


# set it in run auto-update
#echo -e "ENV IOTEX_HOME must be set."
[ $IOTEX_HOME ] || exit 2
#echo -e "ENV _ENV_ must be set."
[ $_ENV_ ] || exit 2
#echo -e "ENV _GREP_STRING_ must be set."
[ $_GREP_STRING_ ] || exit 2

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
    docker ps > /dev/null
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
    IOTEX_MONITOR_HOME=$IOTEX_HOME/monitor
    
    producerPrivKey=""
    externalHost=""
}

function isNotRunning() {
    pushd $IOTEX_MONITOR_HOME
    docker-compose ps iotex
    if [ $? -eq 0 ];then
        return 0
    fi
    popd
    return 1
}

function cleanOldVersion() {
    echo -e "${YELLOW} ******  Upgrade IoTeX Node ******* ${NC}"
    echo -e "${YELLOW} ***  Will stop, delete old iotex container; ${NC}"
    echo -e "${YELLOW} *** download new config and recover your externalHost producerPrivKey ${NC}"
    echo "Stop old iotex-core"
    docker stop iotex
    echo "delete old iotex docker container"
    docker rm iotex
    producerPrivKey=$(grep '^  producerPrivKey:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
    externalHost=$(grep '^  externalHost:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
}

function downloadConfig() {
    #(Optional) If you prefer to start from a snapshot, run the following commands:
    #curl -LSs https://t.iotex.me/${env}-data-latest > $IOTEX_HOME/data.tar.gz
    #cd ${IOTEX_HOME} && tar -xzf data.tar.gz
    echo "download new config"
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/config_${_ENV_}.yaml > $IOTEX_HOME/etc/config.yaml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/genesis_${_ENV_}.yaml > $IOTEX_HOME/etc/genesis.yaml
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

function startup() {
    echo -e "Start iotex-server."
    pushd $IOTEX_MONITOR_HOME
    docker-compose up -d iotex
    popd
}

function startupNode() {
        startup
        #check node running
        sleep 5
        pushd $IOTEX_MONITOR_HOME
        docker-compose ps iotex
        popd
}

function main() {    
    checkDockerPermissions
    checkDockerCompose

    setVar

    # Not running, not update.
    isNotRunning || exit 0
    
    version=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "^- $_GREP_STRING_:"|awk '{print $3}')

    echo -e "Current operating environment: ${YELLOW}  $env ${NC}"

    runversion=$(docker ps -a |grep "iotex/iotex-core:v"|awk '{print$2}'|awk -F'[:]' '{print$2}')
    
    if [ "$version"X = "$runversion"X ];then
        echo -e "${YELLOW} Current running version is latest. Don't need update. ${NC}"
        exit 0
    fi

    echo -e "${YELLOW} Current runing version ( $runversion ) need update ( latest $version ), ${NC}"

    cleanOldVersion

    IOTEX_IMAGE=iotex/iotex-core:${version}
    export IOTEX_IMAGE

    echo "docker pull iotex-core ${version}"
    docker pull $IOTEX_IMAGE

    downloadConfig

    startupNode
}

main
