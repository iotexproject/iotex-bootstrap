#!/bin/bash

set -e
docker pull iotex/iotex-core:v2.4.4

mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.4.4/config_testnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.4.4/genesis_testnet.yaml > $IOTEX_HOME/etc/genesis.yaml

# Download core snapshot (for delegate node) — use multi-threaded aria2c for speed, fall back to curl
command -v aria2c >/dev/null 2>&1 || (sudo apt-get update && sudo apt-get install -y aria2) || true
if command -v aria2c >/dev/null 2>&1; then
    aria2c -x16 -s16 -c --file-allocation=none -d $IOTEX_HOME -o data.tar.gz https://t.iotex.me/testnet-data-snapshot-core-latest
else
    curl -L -C - -o $IOTEX_HOME/data.tar.gz https://t.iotex.me/testnet-data-snapshot-core-latest
fi
tar -xzf $IOTEX_HOME/data.tar.gz -C $IOTEX_HOME/data/

docker run -d --restart on-failure --name iotex \
        -p 4690:4690 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v2.4.4 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml
