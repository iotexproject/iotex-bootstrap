# IoTeX TestNet Manual

## Updates
**Note: make sure you always rebase to the LATEST `iotex-testnet` repo**

**Note: for those who participated in the testnet of v0.5.0-rc1 and/or v0.5.0-rc2, you MUST clean your local state and
then restart with v0.5.0-rc3 (image ID: d2773d858ca9)!**

**Note: address generation method is updated in v0.5.0-rc3. We recommend you generating a new address and key for this
run.**

**Note: the command to start a node has been changed. Please follow the new command bellow.**

Check the release [notes](https://github.com/iotexproject/iotex-core/releases/tag/v0.5.0-rc3) for what's new in v0.5.0-rc3.

## Join TestNet

1. Pull the docker image:

```
docker pull iotex/iotex-core:v0.5.0-rc3
```

If you have problem to pull the image from docker hub, you can also try our mirror image on gcloud
`gcr.io/iotex-servers/iotex-core:v0.5.0-rc3`.

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
        -p 7788:7788 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.0-rc3 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml
```

Now your node should be started successfully.

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

## Blockchain Archives

Syncing from genesis usually take quite a while to catch up the blockchain, we provide the daily archives to start from
a given snapshot.


| Archive File | MD5 Checksum |
| ------------ | ------------ |
| [data-2019-03-12.tar.gz](https://storage.googleapis.com/blockchain-archive/data-2019-03-12.tar.gz) (latest) | 22bf3c4ccafa45101ecf51848898373b |
| [data-2019-03-11.tar.gz](https://storage.googleapis.com/blockchain-archive/data-2019-03-11.tar.gz) | f6403860a4d9880b318fe1c832c2668a |
| [data-2019-03-10.tar.gz](https://storage.googleapis.com/blockchain-archive/data-2019-03-10.tar.gz) | e25fffb9082652b482c580409de5a043 |
| [data-2019-03-09.tar.gz](https://storage.googleapis.com/blockchain-archive/data-2019-03-09.tar.gz) | 6834b1dcd4c66485cbe5160071b11cc8 |
