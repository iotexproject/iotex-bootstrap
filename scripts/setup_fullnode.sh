#!/bin/bash

##Setup & Upgrade Iotex MainNet / TestNet
## User local: source/bash/sh $0 [$1=testnet]
## If remote:  source/bash/sh <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) [$1=testnet]
producerPrivKey=""
externalHost=""


# Colour codes
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

docker ps > /dev/null

if [ $? = 1 ];then
   echo -e "your $RED [$USER] $NC not privilege docker" 
   echo -e "please run $RED [sudo bash] $NC first"
   echo -e "Or docker not install "
   exit 1
fi

##Input Version
if [ "$1"X = "testnet"X ];then
    lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "^- TestNet:"|awk '{print$3}')
    env=testnet

else
    lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "^- MainNet:"|awk '{print$3}')
    env=mainnet
fi
defaultdatadir="$HOME/iotex-var"
echo -e "Current operating environment: ${YELLOW}  $env ${NC}"
#while True; do
read -p "Install or Upgrade Version; if null the latest [$lastversion]: " ver

version=${ver:-"$lastversion"}   # if $ver ;then version=$ver;else version=$lastversion"

runversion=$(docker ps -a |grep "iotex/iotex-core:v"|awk '{print$2}'|awk -F'[:]' '{print$2}')

if [ "$version"X = "$runversion"X ];then
    echo "Not Upgrade!! current ${runversion} is running....!"
    docker start iotex
    exit 0
fi
##Input Data Dir
echo "The current user of the input directory must have write permission!!!"
echo -e "${RED} If Upgrade ; input your old directory \$IOTEX_HOME !!! ${NC}"

#while True: do
read -p "Input your \$IOTEX_HOME [e.g., $defaultdatadir]: " inputdir
IOTEX_HOME=${inputdir:-"$defaultdatadir"}

#if [ "$IOTEX_HOME" ];

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

echo -e "docker run iotex: ${YELLOW} ${version} ${NC}"
#Run the following command to start a node:
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:${version} \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml

#check node running
sleep 5
docker ps | grep iotex-server
