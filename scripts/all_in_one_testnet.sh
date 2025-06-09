#!/bin/bash

set -e
docker pull iotex/iotex-core:v2.1.2

mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.1.2/config_testnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.1.2/genesis_testnet.yaml > $IOTEX_HOME/etc/genesis.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.1.2/trie.db.patch > $IOTEX_HOME/data/trie.db.patch

curl -L https://storage.iotex.io/testnet-data-snapshot-latest.tar.gz > $IOTEX_HOME/data.tar.gz
curl -L https://storage.iotex.io/testnet-data-incr-latest.tar.gz > $IOTEX_HOME/incr.tar.gz

tar -xzf $IOTEX_HOME/data.tar.gz -C $IOTEX_HOME/data/
tar -xzf $IOTEX_HOME/incr.tar.gz -C $IOTEX_HOME/data/

docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v2.1.2 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml
