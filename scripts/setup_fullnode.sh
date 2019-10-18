#!/bin/bash

##Setup  Iotex TestNet
##User $0 [$1]
lastversion=$(curl -sS https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/README.md|grep "docker pull"|awk -F "[:]" '{print $2}')
version=${1:-"$lastversion"}   # if $1 ;then version=$1;else version=last version
echo ${version}
#Pull the docker image
docker pull iotex/iotex-core:${version}

# or use gcr.io/iotex-servers/iotex-core:${version}

#Set the environment with the following commands:
mkdir -p ~/iotex-var && cd ~/iotex-var && mkdir data log etc
export IOTEX_HOME=$PWD

#mkdir -p $IOTEX_HOME/{data,log,etc}

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml

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
