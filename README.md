# IOTEX TestNet Instructions

## Updates

**Note: for those who participated in the testnet of v0.5.0-rc1, you MUST clean your local state and then restart with
v0.5.0-rc2!**

New in v0.5.0-rc2:

- Interacting with the election contract on Ethereum mainnet
- Fixing the bugs in APIs
- Implementing more ioctl commands
- Cleaning up code (e.g., public key from configuration)

## Instructions

Run the following command to start a node:

```
docker run \
    -p 14014:14014 \
    -p 8080:8080 \
    -p 7788:7788 \
    -p 4689:4689 \
    -v=/path/to/data:/var/data:rw \
    -v=/path/to/log:/var/log:rw \
    -v=/path/to/iotex-testnet/config.yaml:/etc/iotex/config_override.yaml:ro \
    -v=/path/to/iotex-testnet/testnet_actions.yaml:/etc/iotex/testnet_actions_override.yaml:ro \
    -v=/path/to/iotex-testnet/genesis.yaml:/etc/iotex/genesis.yaml:ro \
    iotex/iotex-core:v0.5.0-rc2 \
    iotex-server -config-path=/etc/iotex/config_override.yaml -genesis-path=/etc/iotex/genesis.yaml
```

Replace `/path/to/` with your actual paths.

Replace `/tmp` with the path that you want to persist the blockchain data and logs. If you want to make a clean restart,
please delete files in this directory.

If you have an external IP address, please replace it with `externalHost` in `config.yaml`, and enable it and `externalPort`.

By default, an arbitrary key will be created every time you run the node. You could specify your key in `config.yaml` to
always use the same keys throughout runs. You can generate keys by:

```
./ioctl account create
```

Docker images are hosted at
```
iotex/iotex-core:v0.5.0-rc2 (primary)
gcr.io/iotex-servers/iotex-core:v0.5.0-rc2
```

Election contracts on Ethereum mainnet:

- Registration: https://etherscan.io/address/0x92adef0e5e0c2b4f64a1ac79823f7ad3bc1662c4
- Staking: https://etherscan.io/address/0x3bbe2346c40d34fc3f66ab059f75a6caece2c3b3


## Blockchain Archives

Syncing from genesis usually take quite a while to catch up the blockchain, we provide the daily archives to start from
a given snapshot.


| Archive File | MD5 Checksum |
| ------------ | ------------ |
| [data-2019-03-05.tar.gz](https://storage.googleapis.com/blockchain-archive/data-2019-03-05.tar.gz) | 600213829d801ac79eea2863daf79a2d |