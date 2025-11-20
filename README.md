# IoTeX Delegate Manual
<a href="https://iotex.io/devdiscord" target="_blank">
  <img src="https://github.com/iotexproject/halogrants/blob/880eea4af074b082a75608c7376bd7a8eaa1ac21/img/btn-discord.svg" height="36px">
</a>

## Index

- [Release Status](#status)
- [Join MainNet](#mainnet)
- [Join Mainnet without using Docker](#mainnet_native)
- [Join TestNet](#testnet)
- [Interact with Blockchain](#ioctl)
- [Enable Logrotate](#log)
- [Operate Your Node](#ops)
- [Upgrade Your Node（One Line Upgrader）](#upgrade)
- [Q&A](#qa)

## <a name="status"/>Release Status

Here are the software versions we use:

- MainNet: v2.3.2

## <a name="testnet"/>Join TestNet
To start and run a testnet node, please click [**Join Testnet**](https://github.com/iotexproject/iotex-bootstrap/blob/master/README_testnet.md)

## <a name="mainnet"/>Join MainNet
This is the recommended way to start an IoTeX node

> All the steps have written in scripts/all_in_one_mainnet.sh, you can directly run `sh scripts/all_in_one_mainnet.sh`

1. Pull the docker image:

```
docker pull iotex/iotex-core:v2.3.2
```

2. Set the environment with the following commands:

```
mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.3.2/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.3.2/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.3.2/trie.db.patch > $IOTEX_HOME/data/trie.db.patch
```

3. Edit `$IOTEX_HOME/etc/config.yaml`, look for `externalHost` and `producerPrivKey`, uncomment the lines and fill in your external IP and private key. If you leave `producerPrivKey` empty, your node will be assgined with a random key.

4. Start from a **baseline snapshot** (rather than sync from the genesis block), run the following commands:

```
curl -L https://t.iotex.me/mainnet-data-snapshot-latest > $IOTEX_HOME/data.tar.gz
```

or download from another website:

```
curl -L https://storage.iotex.io/mainnet-data-snapshot-latest.tar.gz > $IOTEX_HOME/data.tar.gz
```

**We will update the baseline snapshot on the 1st of every month**. 

5. Download the latest **incremental data** (Optional):

```
curl -L https://storage.iotex.io/mainnet-data-incr-latest.tar.gz > $IOTEX_HOME/incr.tar.gz
```

**We will update the incremental snapshot everyday**. 

We also provide incremental packages from the **past 7 days**.
You can choose any day within this period.
For example, if you want to use the data from April 27, 2025, the incremental package file name will be `mainnet-data-incr-2025-04-27.tar.gz`.

The file named **latest** corresponds to today’s data.

To restore, you only need the full baseline package of the same month and the incremental package of the selected date.

6. Extract the data packages in the correct order.
It is essential to extract the baseline package first, followed by the incremental package.

```
tar -xzf $IOTEX_HOME/data.tar.gz -C $IOTEX_HOME/data/ && tar -xzf $IOTEX_HOME/incr.tar.gz -C $IOTEX_HOME/data/
```

For advanced users, there are three options to consider:

- Option 1: If you plan to run your node as a [gateway](#gateway), please use the snapshot with index data:
https://t.iotex.me/mainnet-data-with-idx-latest.

  or download from another website:
```
curl -L https://storage.iotex.io/mainnet-data-with-idx-latest.tar.gz > $IOTEX_HOME/data.tar.gz
tar -xzf data.tar.gz
```

> mainnet-data-with-idx-latest.tar.gz will be update on Monday every week

- Optional 2: If you only want to sync chain data from 0 height without relaying on legacy delegate election data from Ethereum, you can setup legacy delegate election data with following command:
```bash
curl -L https://storage.iotex.io/poll.mainnet.tar.gz > $IOTEX_HOME/poll.tar.gz; tar -xzf $IOTEX_HOME/poll.tar.gz --directory $IOTEX_HOME/data
```

- Optional 3: If you want to sync the chain from 0 height and also fetching legacy delegate election data from Ethereum, please change the `gravityChainAPIs` in config.yaml to use your infura key with Ethereum archive mode supported or change the API endpoint to an Ethereum archive node which you can access.

5. Run the following command to start a node:

```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v2.3.2 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml
```

Now your node should be started successfully.

If you want to also make your node be a [gateway](#gateway), which could process API requests from users, use the following command instead:

```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 14014:14014 \
        -p 15014:15014 \
        -p 16014:16014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v2.3.2 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

6. Ensure that TCP ports `4689` and `8080` are open on your firewall and load balancer (if applicable). Additionally, if you intend to use the node as a gateway, make sure the following ports are open:
- `14014` for the IoTeX native gRPC API
- `15014` for the Ethereum JSON API
- `16014` for the Ethereum WebSocket

## <a name="mainnet_native"/>Join Mainnet without using Docker
This is not the preferred way to start an IoTeX node

1. Set the environment with the following commands:

Same as [Join MainNet](#mainnet) step 2

2. Build server binary:

```
git clone https://github.com/iotexproject/iotex-core.git
cd iotex-core
git checkout v2.3.2

// optional
export GOPROXY=https://goproxy.io
go mod download
make clean build-all
cp ./bin/server $IOTEX_HOME/iotex-server
```

3. Edit configs

Same as [Join MainNet](#mainnet) step 3. Also make sure you update all db paths in config.yaml to correct location if you don't put them under `/var/data/`

4. Start from a snapshot

Same as [Join MainNet](#mainnet) step 4

5. Run the following command to start a node:

```
nohup $IOTEX_HOME/iotex-server \
        -config-path=$IOTEX_HOME/etc/config.yaml \
        -genesis-path=$IOTEX_HOME/etc/genesis.yaml &
```

Now your node should be started successfully.

If you want to also make your node be a [gateway](#gateway), which could process API requests from users, use the following command instead:

```
nohup $IOTEX_HOME/iotex-server \
        -config-path=$IOTEX_HOME/etc/config.yaml \
        -genesis-path=$IOTEX_HOME/etc/genesis.yaml \
        -plugin=gateway &
```

6. Make sure TCP ports 4689, 8080 (also 14014 if used) are open on your firewall and load balancer (if any).

## <a name="ioctl"/>Interact with Blockchain

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

#### Other Commonly Used Commands

Claim reward:
```
ioctl action claim ${amountInIOTX} -l 10000 -p 1 -s ${ioAddress|alias}
```

Exchange IoTeX native token to ERC20 token on Ethereum via Tube service:
```
ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 ${amountInIOTX} -s ${ioAddress|alias} -l 400000 -p 1 -b d0e30db0
```
Click [IoTeX Tube docs](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/tube.md) for detailed documentation of the tube service.

### JSON RPC API (former "Babel service")

Our node supports most methods of [Ethereum's JSON-RPC protocol](https://eth.wiki/json-rpc/API).  The local endpoint for the Ethereum API service is available at `localhost:15014`. WebSocket support is also available on `localhost:16014`. 

Additional method support could be requested [here](https://github.com/iotexproject/iotex-core/issues).

## <a name="log"/>Enable Logrotate
`logrotate` is pre-installed when building the image. But `crond` (daemon to execute scheduled commands) doesn't automatically start when the docker contaiter starts in alpine linux. 

To enable log logrotation, `docker exec -it <container> crond -b` is expected to be run after the container starts

## <a name="ops"/>Operate Your Node

### Checking Node log

Container logs can be accessed with the following command. 

```
docker logs iotex
```

Content can be filtered with:

```
docker logs -f --tail 100 iotex |grep --color -E "epoch|height|error|rolldposctx"
```

### Stop and remove container

When starting the container with ```--name=iotex```, you must remove the old container before a new build.

```
docker stop iotex
docker rm iotex
```

### Pause and Restarting container

Container can be "stopped" and "restarted" with:

```
docker stop iotex
docker start iotex
```

## <a name="upgrade"/>Upgrade Your Node(One Line Upgrader)
Make sure that $IOTEX_HOME is already set up, and all necessary files (e.g., configs, databases, etc.) are placed in the correct locations.
(Please refer to the Join MainNet section for detailed instructions.)

To upgrade your Mainnet node to the latest version, run the following command:
```bash
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh)
```
Note: If your Docker commands require root privileges, run the script with sudo like this:
```
sudo bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh)
```

To enable [gateway](#gateway) on mainnet
```bash
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) plugin=gateway
```

To stop auto upgdrade cron job and iotex server program, you can run
```bash
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/stop_fullnode.sh)
```
## <a name="gateway"/> Gateway Plugin
Node with gateway plugin enabled will perform extra indexing to serve API requests of more detail chain information, such as number of actions in a block or query actions by hash.

## <a name="qa"/>Q&A
Please refer [here](https://github.com/iotexproject/iotex-bootstrap/wiki/Q&A) for Q&A.
