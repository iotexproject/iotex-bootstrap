#!/bin/bash

set -e
docker pull iotex/iotex-core:v2.3.4

mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.3.4/config_testnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.3.4/genesis_testnet.yaml > $IOTEX_HOME/etc/genesis.yaml

# Download core snapshot (for delegate node)
curl -L https://t.iotex.me/testnet-data-snapshot-core-latest > $IOTEX_HOME/data.tar.gz
tar -xzf $IOTEX_HOME/data.tar.gz -C $IOTEX_HOME/data/

docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v2.3.4 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml
