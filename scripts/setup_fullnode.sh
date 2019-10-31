#!/bin/bash

##Setup & Upgrade Iotex MainNet
##User bash/sh $0

##Input Version
lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "^- MainNet:"|awk '{print$3}')
defaultdatadir="$HOME/iotex-var"
read -p "Install or Upgrade Version [$lastversion]: " ver
version=${ver:-"$lastversion"}   # if $ver ;then version=$ver;else version=$lastversion"

##Input Data Dir
echo "The current user of the installation directory must have write permission!!!"
read -p "Install OR Upgrade Input your data dir [$defaultdatadir]: " inputdir
datadir=${inputdir:-"$defaultdatadir"}

echo "Confirm version: ${version}"
echo "Confirm Data directory: ${datadir}"
read -p "Press any key to continue ... [Ctrl + c exit!] " key1
export IOTEX_HOME=$datadir

##check iotex-server exist and running
runversion=$(docker ps -a |grep "iotex/iotex-core:v"|awk '{print$2}'|awk -F'[:]' '{print$2}')

if [ ${runversion} ];then

    if [ $version = ${runversion} ];then
        echo "Not Upgrade!! current ${runversion} is latest version"
        exit 0
    else
        echo "Stop old iotex-core"
        docker stop iotex
        echo "delete docker container"
        docker rm iotex
        #echo "delete iotex images"
        #docker rmi $(docker images iotex/iotex-core -q)
        producerPrivKey=$(grep '^  producerPrivKey:' ${datadir}/etc/config.yaml|sed 's/^  //g')
        externalHost=$(grep '^  externalHost:' ${datadir}/etc/config.yaml|sed 's/^  //g')
    fi

else
    mkdir -p ${datadir} && cd ${datadir} && mkdir data log etc
    findip=$(curl -Ss ip.sb)
    read -p "SET YOUR EXTERNAL IP HERE [$findip]: " inputip
    echo "If you are a delegate, make sure producerPrivKey is the key for the operator address you have registered."
    echo  "SET YOUR PRIVATE KEY HERE(e.g., 96f0aa5e8523d6a28dc35c927274be4e931e74eaa720b418735debfcbfe712b8)"
    read -p ": " inputkey
    ip=${inputip:-$findip}
    PrivKey=${inputkey:-"96f0aa5e8523d6a28dc35c927274be4e931e74eaa720b418735debfcbfe712b8"}
    echo "Confirm your externalHost: $ip"
    echo "Confirm your producerPrivKey: $PrivKey"
    read -p "Press any key to continue ... [Ctrl + c exit!] " key2
    externalHost="externalHost: $ip"
    producerPrivKey="producerPrivKey: $PrivKey"
fi

docker pull iotex/iotex-core:${version}
# or use gcr.io/iotex-servers/iotex-core:${version}
#Set the environment with the following commands:

#(Optional) If you prefer to start from a snapshot, run the following commands:
#curl -LSs https://t.iotex.me/mainnet-data-latest > $IOTEX_HOME/data.tar.gz
#cd ${IOTEX_HOME} && tar -xzf data.tar.gz
curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml


echo "Update your externalHost,producerPrivKey to config.yaml"
sed -i "/^network:/a\ \ $externalHost" $IOTEX_HOME/etc/config.yaml
sed -i "/^chain:/a\ \ $producerPrivKey" $IOTEX_HOME/etc/config.yaml

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

docker ps | grep iotex-server
