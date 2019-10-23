#!/bin/bash

##Setup & Upgrade Iotex MainNet
##User bash/sh $0

lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "^- MainNet:"|awk '{print$3}')
defaultdatadir="$HOME/iotex-var"

read -p "Install or Upgrade Version default $lastversion: " ver
version=${ver:-"$lastversion"}   # if $ver ;then version=$ver;else version=$lastversion"
echo "Confirm version: ${version}"

##check iotex-server exist and running
currversion=$(docker ps -a |grep "iotex/iotex-core:v"|awk '{print$2}'|awk -F'[:]' '{print$2}')

if [ ${currversion} == $version ];then
    echo "Not Upgrade"
    exit 0
elif [ ${currversion} ]; then
    echo "Stop old iotex-core"
    docker stop iotex
    echo "delete docker container"
    docker rm iotex
    echo "delete iotex images"
    docker rmi $(docker images iotex/iotex-core -q)
fi
echo "The current user of the installation directory must have write permission!!!"
read -p "Install Data directory or Upgrade old Data directory default $defaultdatadir: " inputdir
datadir=${inputdir:-"$defaultdatadir"}
echo "Confirm Data directory: ${datadir}"
mkdir -p ${datadir} && cd ${datadir} && mkdir data log etc

docker pull iotex/iotex-core:${version}

# or use gcr.io/iotex-servers/iotex-core:${version}

#Set the environment with the following commands:

export IOTEX_HOME=$datadir
#(Optional) If you prefer to start from a snapshot, run the following commands:
#curl -LSs https://t.iotex.me/mainnet-data-latest > $IOTEX_HOME/data.tar.gz
#cd ${IOTEX_HOME} && tar -xzf data.tar.gz
curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
# sed -i '/^chain:/a\  producerPrivKey: d02921f3bf63c4dff0673b0446b552174deea243c5a1d32717d51b1807bcef76' $IOTEX_HOME/etc/config.yaml
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

