# IoTeX Delegate Manual
<a href="https://iotex.io/devdiscord" target="_blank">
  <img src="https://github.com/iotexproject/halogrants/blob/880eea4af074b082a75608c7376bd7a8eaa1ac21/img/btn-discord.svg" height="36px">
</a>

## Index

- [Release Status](#status)
- [Join TestNet](#testnet)
- [Join Testnet without using Docker](#testnet_native)
- [Interact with Blockchain](#ioctl)
- [Enable Logrotate](#log)
- [Operate Your Node](#ops)
- [Upgrade Your Node（One Line Upgrader）](#upgrade)
- [Q&A](#qa)

## <a name="status"/>Release Status

Here are the software versions we use:

- TestNet: v1.14.0

**Note**
To start and run a mainnet node, please click [**Join Mainnet**](https://github.com/iotexproject/iotex-bootstrap/blob/master/README.md)

## <a name="testnet"/>Join TestNet
This is the recommended way to start an IoTeX node

1. Pull the docker image:

```
docker pull iotex/iotex-core:v1.14.0
```

2. Set the environment with the following commands:

```
mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v1.14.0/config_testnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v1.14.0/genesis_testnet.yaml > $IOTEX_HOME/etc/genesis.yaml
```

3. Edit `$IOTEX_HOME/etc/config.yaml`, look for `externalHost` and `producerPrivKey`, uncomment the lines and fill in your external IP and private key. If you leave `producerPrivKey` empty, your node will be assgined with a random key.

4. Start from a snapshot (rather than sync from the genesis block), run the following commands:

```
curl -L https://t.iotex.me/testnet-data-latest > $IOTEX_HOME/data.tar.gz
tar -xzf data.tar.gz
```

or download from Google Cloud:
```
curl -L https://storage.googleapis.com/blockchain-archive/testnet-data-latest.tar.gz > $IOTEX_HOME/data.tar.gz
tar -xzf data.tar.gz
```

**We will update the snapshot once a day**. For advanced users, there are three options to consider:

- Option 1: If you plan to run your node as a [gateway](#gateway), please use the snapshot with index data:
https://t.iotex.me/testnet-data-with-idx-latest.

- Optional 2: If you only want to sync chain data from 0 height without relaying on legacy delegate election data from Ethereum, you can setup legacy delegate election data with following command:
```bash
curl -L https://storage.googleapis.com/blockchain-golden/poll.testnet.tar.gz > $IOTEX_HOME/poll.tar.gz; tar -xzf $IOTEX_HOME/poll.tar.gz --directory $IOTEX_HOME/data
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
        iotex/iotex-core:v1.14.0 \
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
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v1.14.0 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

6. Make sure TCP ports 4689, 8080 (also 14014 if used) are open on your firewall and load balancer (if any).

## <a name="testnet_native"/>Join Testnet without using Docker
This is not the preferred way to start an IoTeX node

1. Set the environment with the following commands:

Same as [Join TestNet](#testnet) step 2

2. Build server binary:

```
git clone https://github.com/iotexproject/iotex-core.git
cd iotex-core
git checkout v1.14.0

// optional
export GOPROXY=https://goproxy.io
go mod download
make clean build-all
cp ./bin/server $IOTEX_HOME/iotex-server
```

3. Edit configs

Same as [Join TestNet](#testnet) step 3. Also make sure you update all db paths in config.yaml to correct location if you don't put them under `/var/data/`

4. Start from a snapshot

Same as [Join TestNet](#testnet) step 4

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

- TestNet secure: `api.testnet.iotex.one:443`
- TestNet insecure: `api.testnet.iotex.one:80`

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

### JSON RPC API(Babel service)

Our node supports most of methods of [Ethereum's JSON-RPC protocol](https://eth.wiki/json-rpc/API). The local endpoint of babal service is `localhost:15014` on the gateway node.

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
Make sure you have `$IOTEX_HOME` already set up, and all the files(configs, dbs etc) are placed in the right locations (Please refer to the Join TestNet section).

To upgrade testnet node, use following command. By default, it will upgrade to latest testnet version.
```bash
sudo bash # If your docker requires root privilege
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) testnet
```

To enable [gateway](#gateway) on testnet
```bash
sudo bash # If your docker requires root privilege
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) testnet plugin=gateway
```

To stop auto upgdrade cron job and iotex server program, you can run
```bash
sudo bash # If your docker requires root privilege
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/stop_fullnode.sh)
```
## <a name="gateway"/> Gateway Plugin
Node with gateway plugin enabled will perform extra indexing to serve API requests of more detail chain information, such as number of actions in a block or query actions by hash.

## <a name="qa"/>Q&A
Please refer [here](https://github.com/iotexproject/iotex-bootstrap/wiki/Q&A) for Q&A.
