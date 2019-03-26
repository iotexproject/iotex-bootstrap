# IoTeX TestNet Manual

### For those who join MainNet rehearsal, please read the document [here](rehearsal/README.md)!

## Updates

Check the release [notes](https://github.com/iotexproject/iotex-core/releases/tag/v0.5.0-rc5) for what's new in v0.5.0-rc5.

**Note: make sure you always rebase to the LATEST `iotex-testnet` repo**

**Note: for those who participated in the previous testnet, please restart with the docker image v0.5.0-rc5-hotfix1. you MUST
clean up the local database this time!**

## Join TestNet

1. Pull the docker image:

```
docker pull iotex/iotex-core:v0.5.0-rc5-hotfix1
```

If you have problem to pull the image from docker hub, you can also try our mirror image on gcloud
`gcr.io/iotex-servers/iotex-core:v0.5.0-rc5-hotfix1`.

2. Export `IOTEX_HOME`, create directories, and copy `https://github.com/iotexproject/iotex-testnet/blob/master/config.yaml` and `https://github.com/iotexproject/iotex-testnet/blob/master/genesis.yaml` into `$IOTEX_HOME/etc`, i.e., 

```
wget https://raw.githubusercontent.com/iotexproject/iotex-testnet/master/config.yaml
wget https://raw.githubusercontent.com/iotexproject/iotex-testnet/master/genesis.yaml

cd iotex-testnet
export IOTEX_HOME=$PWD #[SET YOUR IOTEX HOME PATH HERE]

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

cp config.yaml $IOTEX_HOME/etc/
cp genesis.yaml $IOTEX_HOME/etc/
```

3. Edit `config.yaml` in `$IOTEX_HOME/etc/`, look for `externalHost` and `producerPrivKey`, replace `[...]` with your external IP and private key and uncomment the lines. Check the following [section](#ioctl) for how to generate a key.

4. Run the following command to start a node:

```
docker run -d --name IoTeX-Node\
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.0-rc5-hotfix1 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

Now your node should be started successfully.

Note that the command above will also make your node be a gateway, which could process API requests from users. If you
don't want to enable this plugin, you could remove two lines from the command above: `-p 14014:14014 \` and
`-plugin=gateway`.

5. Make sure TCP ports 4689, 14014, 8080 are open on your firewall and load balancer (if any).

## <a name="ioctl"/>Interact with TestNet


You can install ioctl (a command-line interface for interacting with IoTeX blockchain)

```
curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh
```

Make sure ioctl is pointed to the testnet endpoint:
```
ioctl config set endpoint api.testnet.iotex.one:80
```

Generate key:
```
ioctl account create
```

Get active delegates of current epoch:
```
ioctl node delegate
```


Refer to [CLI document](https://github.com/iotexproject/iotex-core/blob/master/cli/ioctl/README.md) for more details.

## Checking node log

Container logs can be accessed with the following command. 

```
docker logs IoTeX-Node
```

content can be filtered with:

```
docker logs -f --tail 100 IoTeX-Node |grep --color -E "epoch|height|error|rolldposctx"
```

## Stop and remove container

When starting the container with ```--name=IoTeX-Node```, you must remove before a new building

```
docker stop IoTeX-Node
docker rm IoTeX-Node
```

## Pause and Restarting container

Container can be "stopped" and "restarted" with:

```
docker stop IoTeX-Node
docker start IoTeX-Node
```


## Fast Block Sync

IoTeX rootchain supports bootstrapping from archives (see below) which will greatly help to reduce the time spent on synchronization.
```
export IOTEX_SANPSHOT_URL=https://storage.googleapis.com/blockchain-archive/$IOTEX_SNAPSHOT_NAME
cd $IOTEX_HOME
wget $IOTEX_SANPSHOT_URL
rm -rf data/
tar -zxvf $IOTEX_SNAPSHOT_NAME
rm -rf $IOTEX_SNAPSHOT_NAME
```
Before these instructions, if you want to run your node as a gateway, please `export IOTEX_SNAPSHOT_NAME=data-with-idx-latest.tar.gz`,
otherwise, `export IOTEX_SNAPSHOT_NAME=data-latest.tar.gz`.

Then `docker run ...` as above after the snapshot is ready.
