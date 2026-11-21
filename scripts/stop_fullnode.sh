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

# Set by checkDockerCompose() to whichever Compose is available. Used unquoted
# at call sites so that "docker compose" word-splits into command + subcommand.
COMPOSE_CMD=""

function checkDockerCompose() {
    # Compose v2 ships as a Docker CLI plugin invoked as `docker compose`. The
    # standalone `docker-compose` v1 binary is end-of-life and is absent from
    # current Docker installs, so requiring it fails outright on a recent host.
    # Prefer the plugin, fall back to the legacy binary.
    if docker compose version > /dev/null 2>&1;then
        COMPOSE_CMD="docker compose"
    elif docker-compose --version > /dev/null 2>&1;then
        COMPOSE_CMD="docker-compose"
    else
        echo -e "$RED Neither 'docker compose' nor 'docker-compose' is available $NC"
        echo -e "Install the Compose plugin, e.g. 'apt-get install docker-compose-plugin'"
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
    $COMPOSE_CMD stop

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
