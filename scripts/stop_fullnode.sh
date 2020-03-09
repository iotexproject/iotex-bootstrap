#!/bin/bash
## User local: source/bash/sh [$0]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/stop_fullnode.sh)

# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
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
    defaultdatadir="$HOME/iotex-var"
}


function determinIotexHome() {
    ##Input Data Dir
    echo "The current user of the input directory must have write permission!!!"
    echo -e "${RED} Input your directory \$IOTEX_HOME !!! ${NC}"
    
    #while True: do
    read -p "Input your \$IOTEX_HOME [e.g., $defaultdatadir]: " inputdir
    IOTEX_HOME=${inputdir:-"$defaultdatadir"}
}

function confirmEnvironmentVariable() {
    echo -e "Confirm version: ${RED} ${version} ${NC}"
    echo -e "Confirm IOTEX_HOME directory: ${RED} ${IOTEX_HOME} ${NC}"
    read -p "Press any key to continue ... [Ctrl + c exit!] " key1
}

function stopNode() {
    echo -e "${YELLOW}Stopping iotex-server.${NC}"
    pushd $IOTEX_HOME/monitor
    docker-compose stop

    # stop auto-updatem, if it is running.
    ps -ef | grep "$IOTEX_HOME/bin/auto-update" > /dev/null
    if [ $? -eq 0 ];then
        echo -e "${YELLOW} stopping auto-update service... ${NC}"
        pid=$(ps -ef | grep "$IOTEX_HOME/bin/auto-update" | grep -v grep | awk '{print $2}')
        kill -9 $pid
        echo -e "${YELLOW} auto-update stopped.${NC}"
    fi
    popd
    echo -e "${YELLOW}Iotex-server. stopped.${NC}"
}


function main() {
    checkDockerPermissions
    checkDockerCompose
    
    setVar
    determinIotexHome
    confirmEnvironmentVariable

    stopNode
}

main
