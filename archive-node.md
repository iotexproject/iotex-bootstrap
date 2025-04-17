# IoTeX Archive Node Manual
The IoTeX archive node provides the capability of accessing the entire chain's
full history data. User can query an address's balance at any given height on
the chain, or replay a past transaction with the exact state of the chain at the
time the tx was originally executed. 

The following instrcutions will guide you through setting up an IoTeX archive node 
- [System Requirements](#system)
- [Pre-Requisites](#requisite)
- [Prepare Home Directory](#prephome)
- [Download Data](#download)
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

## <a name="prephome"/>Prepare Home Directory
Set up the home directory and download config, genesis, and snapshot data. In
the instructions below `/var/iotex-archive` is used as the home directory, this
is the same directory as specified in the config yaml file so it will work with
the downloaded config file.
>Note: You are free to use a directory path at your choice, in which case, be
sure to modify the file paths in `config_archive_mainnet.yaml` (there are 13 of
them)
```
mkdir -p /var/iotex-archive
cd /var/iotex-archive

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/etc
mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log

#download config, genesis file
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_archive_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/trie.db.patch > $IOTEX_HOME/data/trie.db.patch
curl https://r2.iotex.io/poll.mainnet.db > $IOTEX_HOME/data/poll.db
```
## <a name="download"/>Download Data
Next step is to download the snapshot data. There are 2 files to download. The
first is the IoTeX blockchain's address/state database file, due to the quite
large size of this file in archive mode, the file is not compressed and will be
a direct download. The second is a `tar.gz` compressed file containing multiple
data files (block data, blob storage, and certain indexing files, etc). You will
need to download and uncompress this file.

In the $IOTEX_HOME folder, run the following commands:
```
#download the data files and uncompress it
curl -LO https://r2.iotex.io/iotex-data.tar.gz
tar -xzf iotex-data.tar.gz

#download the state database file
cd data
curl -LO https://storage.googleapis.com/blockchain-golden/archive/archive.db
```
>Note: the state database file has a size of 4.6TB at this moment, it will take
considerable amount of time (12.8 hours at 100MB/s download speed) to download.
Please take measures (for example use `nohup` at the front) to prevent possible
interruption of the download process.

After successful download and uncompress operations, the $IOTEX_HOME/data folder
will have these files:

data<br>
├── archive.db<br>
├── blob.db<br>
├── bloomfilter.index.db<br>
├── candidate.index.db<br>
├── chain-00000001.db<br>
├── chain-00000002.db<br>
├── chain-00000003.db<br>
├── chain-00000004.db<br>
├── chain-00000005.db<br>
├── chain-00000006.db<br>
├── chain-00000007.db<br>
├── chain-00000008.db<br>
├── chain-00000009.db<br>
├── chain-00000010.db<br>
├── chain-00000011.db<br>
├── chain-00000012.db<br>
├── chain-00000013.db<br>
├── chain-00000014.db<br>
├── chain-00000015.db<br>
├── chain-00000016.db<br>
├── chain-00000017.db<br>
├── chain-00000018.db<br>
├── chain-00000019.db<br>
├── chain-00000020.db<br>
├── chain-00000021.db<br>
├── chain-00000022.db<br>
├── chain-00000023.db<br>
├── chain-00000024.db<br>
├── chain-00000025.db<br>
├── chain-00000026.db<br>
├── chain-00000027.db<br>
├── chain-00000028.db<br>
├── chain-00000029.db<br>
├── chain-00000030.db<br>
├── chain-00000031.db<br>
├── chain-00000032.db<br>
├── chain-00000033.db<br>
├── chain.db<br>
├── consensus.db<br>
├── contractstaking.index.db<br>
├── index.db<br>
├── poll.db<br>
├── staking.index.db<br>
└── trie.db.patch<br>

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
        -v=$IOTEX_HOME/data:/var/iotex-archive/data:rw \
        -v=$IOTEX_HOME/log:/var/iotex-archive/log:rw \
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
