#!/bin/bash

##Setup & Upgrade Iotex MainNet / TestNet
## User local: source/bash/sh $0 [$1=testnet]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) [$1=testnet]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) [$1=testnet $2=plugin=gateway]
producerPrivKey=""
externalHost=""


# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

docker ps > /dev/null

if [ $? = 1 ];thenecho -e "your $RED [$USER] $NC not privilege docker" 
   echo -e "please run $RED [sudo bash] $NC first"
   echo -e "Or docker not install "
   exit 1
fi

##Input Version, set plugin
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

lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "^- $_GREP_STRING_:"|awk '{print$3}')
env=$_ENV_

defaultdatadir="$HOME/iotex-var"
echo -e "Current operating environment: ${YELLOW}  $env ${NC}"
#while True; do
read -p "Install or Upgrade Version; if null the latest [$lastversion]: " ver

version=${ver:-"$lastversion"}   # if $ver ;then version=$ver;else version=$lastversion"

runversion=$(docker ps -a |grep "iotex/iotex-core:v"|awk '{print$2}'|awk -F'[:]' '{print$2}')

if [ "$version"X = "$runversion"X ];then
    echo "Not Upgrade!! current ${runversion} is running....!"
    docker start iotex
    docker ps -a |grep "iotex-monitor"
    if [ $? -eq 0 ];then
        echo "Iotex-monitor is running....!"
        docker start iotex-monitor
        exit 0
    fi
    exit 0
fi


##Input Data Dir
echo "The current user of the input directory must have write permission!!!"
echo -e "${RED} If Upgrade ; input your old directory \$IOTEX_HOME !!! ${NC}"

#while True: do
read -p "Input your \$IOTEX_HOME [e.g., $defaultdatadir]: " inputdir
IOTEX_HOME=${inputdir:-"$defaultdatadir"}

#if [ "$IOTEX_HOME" ];

# Delete old file.
if [ -f "${IOTEX_HOME}/data/poll.db.bolt" ];then
    rm -f ${IOTEX_HOME}/data/poll.db.bolt
fi

echo -e "Confirm version: ${RED} ${version} ${NC}"
echo -e "Confirm IOTEX_HOME directory: ${RED} ${IOTEX_HOME} ${NC}"
read -p "Press any key to continue ... [Ctrl + c exit!] " key1

if [ -f "${IOTEX_HOME}/data/chain.db" ]; then
    echo -e "${YELLOW} ******  Upgrade Iotex Node ******* ${NC}"
    echo -e "${YELLOW} ***  Will stop, delete old iotex container; ${NC}"
    echo -e "${YELLOW} *** download new config and recover your externalHost producerPrivKey ${NC}"
    read -p "******* Press any key to continue ... [Ctrl + c exit!] " upgreadekey
    echo "Stop old iotex-core"
    docker stop iotex
    echo "delete old iotex docker container"
    docker rm iotex
        #echo "delete iotex images"
        #docker rmi $(docker images iotex/iotex-core -q)
    producerPrivKey=$(grep '^  producerPrivKey:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')
    externalHost=$(grep '^  externalHost:' ${IOTEX_HOME}/etc/config.yaml|sed 's/^  //g')

else
    echo -e "${YELLOW} ****** Install Iotex Node  ***** ${NC}"
    echo -e "${YELLOW} if installed, Confirm Input IOTEX_HOME directory True ${NC};"
    read -p "[Ctrl + c exit!]; else Enter anykey ..." anykey
    mkdir -p ${IOTEX_HOME} && cd ${IOTEX_HOME} && mkdir data log etc
fi

if [ ! "${externalHost}" ];then
    findip=$(curl -Ss ip.sb)
    read -p "SET YOUR EXTERNAL IP HERE [$findip]: " inputip
    ip=${inputip:-$findip}
fi

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

read -p "Do you want to monitor the status of the node [Y/N] (Default: N)? " wantmonitor

echo "docker pull iotex-core ${version}"
docker pull iotex/iotex-core:${version}
# or use gcr.io/iotex-servers/iotex-core:${version}
#Set the environment with the following commands:

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

if [ "${wantmonitor}"X = "Y"X -o "${wantmonitor}"X = "y"X -o \
                     "${wantmonitor}"X = "yes"X -o "${wantmonitor}"X = "Yes"X ];then
    echo "Download config files for monitor"
    mkdir -p $IOTEX_HOME/monitor
    IOTEX_MONITOR_HOME=$IOTEX_HOME/monitor
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/IoTeX.json > $IOTEX_MONITOR_HOME/IoTeX.json
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/dashboards.yaml > $IOTEX_MONITOR_HOME/dashboards.yaml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/datasource.yaml > $IOTEX_MONITOR_HOME/datasource.yaml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/docker-compose.yml > $IOTEX_MONITOR_HOME/docker-compose.yml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/.env > $IOTEX_MONITOR_HOME/.env
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/prometheus.yml > $IOTEX_MONITOR_HOME/prometheus.yml
    curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/${version}/monitor/run.sh > $IOTEX_MONITOR_HOME/run.sh

    chmod +x $IOTEX_MONITOR_HOME/run.sh

    echo -e "docker run iotex with monitor: ${YELLOW} ${version} ${NC}"
    IOTEX_IMAGE=iotex/iotex-core:${version}
    CUR_PWD=${PWD}
    cd $IOTEX_MONITOR_HOME
    export IOTEX_HOME IOTEX_MONITOR_HOME IOTEX_IMAGE
    docker-compose up -d
    if [ $? -eq 0 ];then
        echo -e "${YELLOW} You can access 'localhost:3000' to view node monitoring ${NC}"
        echo -e "${YELLOW} Default User/Pass: admin/admin." 
    fi
    cd ${CUR_PWD}
else
    echo -e "docker run iotex: ${YELLOW} ${version} ${NC}"
    #Run the following command to start a node:
    
    _DOCKER_RUN_CMD="docker run -d --restart on-failure --name iotex"
    _DOCKER_RUN_CMD_PORTS="-p 4689:4689 -p 8080:8080"
    _DOCKER_RUN_CMD_VOL="
            -v=$IOTEX_HOME/data:/var/data:rw \
            -v=$IOTEX_HOME/log:/var/log:rw \
            -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
            -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro"
    _DOCKER_RUN_CMD_IMAGE="iotex/iotex-core:${version}"
    _DOCKER_RUN_CMD_ENTRYPOINT="iotex-server \
            -config-path=/etc/iotex/config_override.yaml \
            -genesis-path=/etc/iotex/genesis.yaml"
    
    read -p  "Do you want to make your node be a gateway? [Y/N] (Default: N) ?" enableGateway
    if [ "$enableGateway"X = "Y"X -o "$enableGateway"X = "y"X ];then
        _DOCKER_RUN_CMD_PORTS="$_DOCKER_RUN_CMD_PORTS -p 14014:14014"
        _DOCKER_RUN_CMD_ENTRYPOINT="$_DOCKER_RUN_CMD_ENTRYPOINT -plugin=gateway"
    fi
    
    $_DOCKER_RUN_CMD $_DOCKER_RUN_CMD_PORTS \
    		 $_DOCKER_RUN_CMD_VOL \
    		 $_DOCKER_RUN_CMD_IMAGE \
    		 $_DOCKER_RUN_CMD_ENTRYPOINT
    
    
    #check node running
    sleep 5
    docker ps | grep iotex-server
fi
