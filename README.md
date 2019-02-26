# IOTEX TestNet Instructions

Run the following command to start a node:

```
docker run \
    -p 14014:14014 \
    -p 8080:8080 \
    -p 7788:7788 \
    -p 4689:4689 \
    -v=/tmp:/var/data:rw
    -v=/path/to/iotex-testnet/config.yaml:/etc/iotex/config_override.yaml:ro \
    -v=/path/to/iotex-testnet/testnet_actions.yaml:/etc/iotex/testnet_actions_override.yaml:ro \
    -v=/path/to/iotex-testnet/genesis.yaml:/etc/iotex/genesis.yaml:ro \
    iotex/iotex-core:v0.5.0-rc1 \
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
