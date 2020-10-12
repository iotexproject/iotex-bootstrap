#!/bin/bash
## User local: source/bash/sh
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh)

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
    IOTEX_IMAGE=363205959602.dkr.ecr.us-east-1.amazonaws.com/iotex-core:latest
}

function determinIotexHome() {
    ##Input Data Dir
    echo "The current user of the input directory must have write permission!!!"
    echo -e "${RED} If Upgrade ; input your old directory \$IOTEX_HOME !!! ${NC}"
    
    #while True: do
    read -p "Input your \$IOTEX_HOME [e.g., $defaultdatadir]: " inputdir
    IOTEX_HOME=${inputdir:-"$defaultdatadir"}
    IOTEX_MONITOR_HOME=$IOTEX_HOME/monitor
}

function preDockerCompose() {
    # set monitor home
    mkdir -p $IOTEX_MONITOR_HOME

    export IOTEX_HOME IOTEX_MONITOR_HOME IOTEX_IMAGE

    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/docker-compose.yml.marketplace > $IOTEX_MONITOR_HOME/docker-compose.yml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/monitor/.env > $IOTEX_MONITOR_HOME/.env
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
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v1.1.1/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v1.1.1/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
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

function donwloadBlockDataFile() {
    NODE_GATEWAY_MAINNET_DATA_URL=https://t.iotex.me/mainnet-data-with-idx-latest

    SAVE_DIR=$IOTEX_HOME/tmp
    mkdir -p $SAVE_DIR
    DATA_FILE_PATH=$SAVE_DIR/data.tar.gz

    UNZIP_FILE_CMD="tar xvf $SAVE_DIR/data.tar.gz -C $IOTEX_HOME"

    echo -e "${YELLOW} Downloading the db file from a snapshot...${NC}"
    curl -sSL $NODE_GATEWAY_MAINNET_DATA_URL > $DATA_FILE_PATH
    echo -e "${YELLOW} Unzipping...${NC}"
    $UNZIP_FILE_CMD
    echo -e "${YELLOW} Done.${NC}"
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
    # Check and clean
    checkDockerPermissions     # Determine the current user can run docker
    checkDockerCompose         # Determin the docker-compose is installed
    setVar                     # Set global variable

    determinIotexHome          # Determine the $IOTEX_HOME
    determineExtIp
    determinPrivKey

    echo -e "${YELLOW} ****** Install Iotex Node  ***** ${NC}"
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

    echo -e "Confirm your externalHost: ${YELLOW} $ip ${NC}"
    echo -e "Confirm your producerPrivKey: ${RED} $privKey ${NC}"
    read -p "Press any key to continue ... [Ctrl + c exit!] " key2

    echo "docker pull iotex-core"
    docker pull $IOTEX_IMAGE
    # or use gcr.io/iotex-servers/iotex-core:${version}
    #Set the environment with the following commands:

    downloadConfig
    preDockerCompose

    startupNode
}

main $@
