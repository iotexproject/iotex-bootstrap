# IoTeX Rehearsal Manual

### Note that upgrading to v0.5.0-rc7 is a compatible upgrade (aka soft fork), you just need to restart and use the new docker image.

## Join MainNet Rehearsal

1. Pull the docker image:

```
docker pull iotex/iotex-core:v0.5.0-rc7
```

If you have problem to pull the image from docker hub, you can also try our mirror image on gcloud
`gcr.io/iotex-servers/iotex-core:v0.5.0-rc7`.

2. Set the environment with the following commands:

```
mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-testnet/master/rehearsal/config.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-testnet/master/rehearsal/genesis.yaml > $IOTEX_HOME/etc/genesis.yaml
```

3. Edit `$IOTEX_HOME/etc/config.yaml`, look for `externalHost` and `producerPrivKey`, replace `[...]` with your external
IP and private key and uncomment the lines.

4. (Optional) If you prefer to start from a snapshot, run the following commands:

```
curl -L https://t.iotex.me/data-latest > $IOTEX_HOME/data.tar.gz
tar -xzf data.tar.gz
```

5. Run the following command to start a node:

```
docker run -d --restart on-failure \
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.0-rc7 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

Now your node should be started successfully.

Note that the command above will also make your node be a gateway, which could process API requests from users. If you
don't want to enable this plugin, you could remove two lines from the command above: `-p 14014:14014 \` and
`-plugin=gateway`.

6. Make sure TCP ports 4689, 14014, 8080 are open on your firewall and load balancer (if any).

## <a name="ioctl"/>Interact with MainNet Rehearsal


You can install ioctl (a command-line interface for interacting with IoTeX blockchain)

```
curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh
```

Make sure ioctl is pointed to the mainnet rehearsal endpoint:
```
ioctl config set endpoint api.iotex.one:80
```

## Misc

For the remaining information, it will be the same as testnet before. Please refer to the document [here](../README.md).

For those who has customized deployment process already, you don't need to exactly follow the instructions above. However,
please make sure you will use `iotex/iotex-core:v0.5.0-rc7` and the latest config file `rehearsal/config.yaml` and genesis
file `rehearsal/genesis.yaml`.
