# IoTeX Archive Node Manual
The IoTeX archive node provides the capability of accessing the entire chain's
full history data. User can query an address's balance at any given height on
the chain, or replay a past transaction with the exact state of the chain at the
time the tx was originally executed. 

The following instrcutions will guide you through setting up an IoTeX archive node 
- [System Requirements](#system)
- [Pre-Requisites](#requisite)
- [Prepare Data](#prepdata)
- [Build Binary](#build)
- [Start Node](#start)
- [Running Node using Docker](#docker)
- [Interact with IoTeX Blockchain](#ioctl)

## <a name="system"/>System Requirements

| OS | CPU | RAM | Disk |
| ---------- | ------------ | ------------ | ------------ |
| Debian 12/Ubuntu 22.04 | 8+ cores | 32GB+ | 10TB+ (SSD or NVMe) |

## <a name="requisite"/>Pre-Requisites
```
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y
sudo apt install -y git gcc make --fix-missing

#install Go
curl -LO https://go.dev/dl/go1.21.8.linux-amd64.tar.gz
sudo tar xzf go1.21.8.linux-amd64.tar.gz -C /usr/local && rm go1.21.8.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

#verify Go installation
go version
```

## <a name="prepdata"/>Prepare Data
Set up the home directory and download config, genesis, and snapshot data. In
the instructions below `~/iotex-var` is used as the home directory, feel free
to use a directory path at your choice (make sure you have file creation and
write access in the folder)
```
mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/etc
mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log

#download config, genesis file
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/trie.db.patch > $IOTEX_HOME/data/trie.db.patch
curl https://storage.googleapis.com/blockchain-golden/poll.mainnet.db > $IOTEX_HOME/data/poll.db

#download snapshot and unzip data
// TODO: add download link
```

## <a name="build"/>Build Binary
In the home directory, run the following commands
```
git clone https://github.com/iotexproject/iotex-core.git
cd iotex-core

#checkout the code branch for archive node
git checkout origin/archive

#build binary
make build
cp ./bin/server $IOTEX_HOME/iotex-server
```

## <a name="start"/>Start Node
Run the following command to start the IoTeX archive node.
>Note: make sure TCP ports 4689, 8080, 14014, and 15014 are open on the node's
network or firewall, these are needed for p2p and API query to work properly
```
nohup $IOTEX_HOME/iotex-server -config-path=$IOTEX_HOME/etc/config.yaml -genesis-path=$IOTEX_HOME/etc/genesis.yaml -plugin=gateway &
```
`nohup` will keep the process running in case you logged out of the terminal where
the node is started

## <a name="docker"/>Running Node using Docker
You can also run the IoTeX archive node using Docker. To do so, skip the
**Build Binary** and **Start Node** section, run the following commands
instead:
```
docker pull iotex/iotex-core:archive
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:archive \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```
To restart your node, remove the old container before restarting with the above
docker command.
```
docker stop iotex
docker rm iotex
```
To temporarily pause and resume the node: 
```
docker stop iotex
docker start iotex
```

## <a name="ioctl"/>Interact with IoTeX Blockchain

### ioctl

You can install `ioctl` (a command-line interface for interacting with IoTeX blockchain)

```
curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh
```

You can point `ioctl` to your node (if you enable the [gateway](#gateway) plugin):

```
ioctl config set endpoint localhost:14014 --insecure
```

Or you can point it to our API nodes:

- MainNet secure: `api.iotex.one:443`
- MainNet insecure: `api.iotex.one:80`

If you want to set an insecure endpoint, you need to add `--insecure` option.

Generate key:
```
ioctl account create
```
Get consensus delegates of current epoch:
```
ioctl node delegate
```
Refer to [CLI document](https://github.com/iotexproject/iotex-core/blob/master/ioctl/README.md) for more details.
