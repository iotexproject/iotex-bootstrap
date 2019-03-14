# IoTeX TestNet Manual

## Updates

Check the release [notes](https://github.com/iotexproject/iotex-core/releases/tag/v0.5.0-rc4) for what's new in v0.5.0-rc4.

**Note: make sure you always rebase to the LATEST `iotex-testnet` repo**

**Note: for those who participated in the previous testnet, you MUST clean your local state and then restart with
v0.5.0-rc4 (image ID: 5d07869264da)!**

**Note: the command to start a node has been changed. Please follow the new command bellow.**

**Note: we support claim block production rewards, please try it out by using ioctl.**

## Join TestNet

1. Pull the docker image:

```
docker pull iotex/iotex-core:v0.5.0-rc4
```

If you have problem to pull the image from docker hub, you can also try our mirror image on gcloud
`gcr.io/iotex-servers/iotex-core:v0.5.0-rc4`.

2. Edit `config.yaml` in this repo, look for `externalHost` and `producerPrivKey`, replace `[...]` with your external IP
and private key and uncomment the lines. Check the following [section](#ioctl) for how to generate a key.

3. Export `IOTEX_HOME`, create directories, and copy `config.yaml` and `genesis.yaml` into `$IOTEX_HOME/etc`.

```
export IOTEX_HOME=[SET YOUR IOTEX HOME PATH HERE]

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc
```

4. Run the following command to start a node:

```
docker run -d \
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.0-rc4 \
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
ioctl config set endpoint 35.230.103.170:10000
```

Generate key:
```
ioctl account create
```

Get active delegates of current epoch:
```
ioctl node delegate
```

Get active delegates of current epoch:
```
ioctl node productivity
```

Refer to [CLI document](https://github.com/iotexproject/iotex-core/blob/master/cli/ioctl/README.md) for more details.

## Fast Sync

IoTeX rootchain supports bootstrapping from archives (see below) which will greatly help to reduce the time spent on synchronization.
```
cd $IOTEX_HOME
wget https://storage.googleapis.com/blockchain-archive/data-latest.tar.gz
rm -rf data/
tar -zxvf data-latest.tar.gz
rm -rf data-latest.tar.gz
```
Then "docker run ..." as above.

## Blockchain Archives

We provide the daily archives to start from a given snapshot.

| Archive File | MD5 Checksum |
| ------------ | ------------ |
