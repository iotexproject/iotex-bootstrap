# IOTEX TestNet Instructions

## Updates

**Note: for those who participated in the testnet of v0.5.0-rc1 and/or v0.5.0-rc2, you MUST clean your local state and
then restart with v0.5.0-rc3!**

Check the release [notes](https://github.com/iotexproject/iotex-core/releases/tag/v0.5.0-rc3) for what's new in v0.5.0-rc3.

## Instructions

Run the following command to start a node:

```
docker run -d \
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -p 7788:7788 \
        -v=/path/to/data:/var/data:rw \
        -v=/path/to/log:/var/log:rw \
        -v=/path/to/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=/path/to/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.0-rc3 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml
```

Replace `/path/to/` with your actual paths.

Replace `/tmp` with the path that you want to persist the blockchain data and logs. If you want to make a clean restart,
please delete files in this directory.

If you have an external IP address, please replace it with `externalHost` in `config.yaml`, and enable it and `externalPort`.

By default, an arbitrary key will be created every time you run the node. You could specify your key in `config.yaml` to
always use the same keys throughout runs. You can install ioctl (a command-line interface for interacting with IoTeX blockchain) and generate keys by:

```
curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh

ioctl account create
```

Docker images are hosted at
```
iotex/iotex-core:v0.5.0-rc3 (primary)
gcr.io/iotex-servers/iotex-core:v0.5.0-rc3
```

Election contracts on Ethereum mainnet:

- Registration: https://etherscan.io/address/0x92adef0e5e0c2b4f64a1ac79823f7ad3bc1662c4
- Staking: https://etherscan.io/address/0x3bbe2346c40d34fc3f66ab059f75a6caece2c3b3

## Interact with Testnet
Make sure ioctl is pointed to the testnet endpoint:
```
ioctl config set endpoint 35.230.103.170:10000
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
