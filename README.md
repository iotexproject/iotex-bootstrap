# IoTeX Delegate Manual

### V0.5.0-rc10 is rollout to testnet. Please try it out. If you join the previous round of testnet, you MUST restart with the clean state.

## Index

- [Release Status](#status)
- [Join MainNet Rehearsal](#mainnet)
- [Join TestNet](#testnet)
- [Interact with Blockchain](#ioctl)
- [Operate Your Node](#ops)


## <a name="status"/>Release Status

- MainNet Rehearsal: v0.5.0-rc8-hotfix2
- TestNet: v0.5.0-rc10

## <a name="mainnet"/>Join MainNet Rehearsal

1. Pull the docker image:

```
docker pull iotex/iotex-core:v0.5.0-rc8-hotfix2
```

If you have problem to pull the image from docker hub, you can also try our mirror image on gcloud
`gcr.io/iotex-servers/iotex-core:v0.5.0-rc8-hotfix2`.

2. Set the environment with the following commands:

```
mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
```

3. Edit `$IOTEX_HOME/etc/config.yaml`, look for `externalHost` and `producerPrivKey`, replace `[...]` with your external
IP and private key and uncomment the lines.

4. (Optional) If you prefer to start from a snapshot, run the following commands:

```
curl -L https://t.iotex.me/mainnet-data-latest > $IOTEX_HOME/data.tar.gz
tar -xzf data.tar.gz
```
We will update the snapshot once a day. If you plan to run your node as a gateway, please use the snapshot with index data:
https://t.iotex.me/mainnet-data-with-idx-latest.

5. Run the following command to start a node:

```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.0-rc8-hotfix2 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml
```

Now your node should be started successfully.

If you want to also make your node be a gateway, which could process API requests from users, use the following command instead:

```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.0-rc8-hotfix2 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

6. Make sure TCP ports 4689, 8080 (also 14014 if used) are open on your firewall and load balancer (if any).

## <a name="testnet"/>Join TestNet

Current testnet is running with release `v0.5.0-rc10`.

There's almost no difference to join TestNet, but in step 2, you need to use the config and genesis files for TestNet:

```
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_testnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_testnet.yaml > $IOTEX_HOME/etc/genesis.yaml
```

In step 4, you need to use the snapshot for TestNet: https://t.iotex.me/testnet-data-latest and https://t.iotex.me/testnet-data-with-idx-latest. 

In step 5, you need to replace the docker image tag in the command with `v0.5.0-rc10`.

## <a name="ioctl"/>Interact with Blockchain


You can install `ioctl` (a command-line interface for interacting with IoTeX blockchain)

```
curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh
```

You can point `ioctl` to your node:

```
ioctl config set endpoint localhost:14014
```

Or you can point it to our nodes:

- MainNet rehearsal: api.iotex.one:80
- TestNet: api.testnet.iotex.one:80

Generate key:
```
ioctl account create
```

Get consensus delegates of current epoch:
```
ioctl node delegate
```

Refer to [CLI document](https://github.com/iotexproject/iotex-core/blob/master/cli/ioctl/README.md) for more details.

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
