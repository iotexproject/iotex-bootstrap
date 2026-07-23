#!/bin/bash

set -e
docker pull iotex/iotex-core:v2.4.4

mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.4.4/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.4.4/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.4.4/trie.db.patch > $IOTEX_HOME/data/trie.db.patch

# Download core snapshot (for delegate node) — use multi-threaded aria2c for speed, fall back to curl
command -v aria2c >/dev/null 2>&1 || (sudo apt-get update && sudo apt-get install -y aria2) || true
if command -v aria2c >/dev/null 2>&1; then
    aria2c -x16 -s16 -c --file-allocation=none -d $IOTEX_HOME -o data.tar.gz https://t.iotex.me/mainnet-data-snapshot-core-latest
else
    curl -L -C - -o $IOTEX_HOME/data.tar.gz https://t.iotex.me/mainnet-data-snapshot-core-latest
fi
tar -xzf $IOTEX_HOME/data.tar.gz -C $IOTEX_HOME/data/

docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v2.4.4 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml

# --- Optional: gateway / API node only (not needed for a delegate / fullnode) ---
# If you run this node as a gateway (add `-plugin=gateway` to the docker run above) so it
# serves API / transaction-log queries, also apply the transaction-log patch shipped with
# v2.4.4 (see changelog/v2.4.4-release-note.md):
#
#   curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.4.4/txlog.db.patch > $IOTEX_HOME/data/txlog.db.patch
#
# then add the following to the chain: section of $IOTEX_HOME/etc/config.yaml and restart:
#
#   chain:
#     patchTransactionLogPath: /var/data/txlog.db.patch
#
# IMPORTANT: only set patchTransactionLogPath if the file exists at that path — a node
# configured with a missing patch file will fail to start.
