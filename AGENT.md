# IoTeX Node Setup & Upgrade Guide for AI Agents

Practical knowledge for AI agents setting up or upgrading an IoTeX mainnet fullnode. Covers pitfalls not obvious from the main README.

## Prerequisites

1. **Docker** — must be installed first. The setup script checks but does NOT install it:
   ```bash
   curl -fsSL https://get.docker.com | sh
   ```

2. **docker-compose standalone binary** — the script requires `docker-compose` (not `docker compose` plugin syntax). Modern Docker ships the plugin but not the standalone binary:
   ```bash
   ln -sf /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose
   ```

3. **Non-root user (recommended)** — install Docker as root, then create a node user with docker group access:
   ```bash
   useradd -m -s /bin/bash <username>
   usermod -aG docker <username>
   ```

## Fresh Install

### Before you start

1. **Check available disk space** — a core node needs at least 500GB free, a gateway node needs 1TB+:
   ```bash
   df -h /
   ```
2. **Choose the install path** — pick the partition with the most space. Recommend `$HOME/iotex-var` if the home partition is large enough, otherwise use the largest mounted volume (e.g., `/data/iotex-var`, `/mnt/iotex-var`). Ask the user if unclear.

### Run the setup

```bash
# Download the setup script — note: it's under scripts/, NOT repo root
curl -sSL https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh -o ~/setup_fullnode.sh

# Run with --snapshot to download blockchain data (~180GB, takes 1-3 hours)
bash ~/setup_fullnode.sh --auto --home=<install-path> --snapshot
```

See the [main README](README.md#agent-upgrade) for all available flags.

### Key things to know

- **Always use `--snapshot` for fresh installs.** Without it, the node tries to sync from genesis using an Ethereum RPC endpoint. The default Infura key in config.yaml is expired, so the node will crash with `401 Unauthorized: account disabled`.
- **`externalHost` must be IPv4.** The script auto-detects via `curl ip.sb`, which may return IPv6 on dual-stack servers. The p2p layer does not handle IPv6. Fix with: `curl -4 ip.sb` and update `$IOTEX_HOME/etc/config.yaml`.
- **The snapshot download is blocking** and can take hours. For manual background download:
  ```bash
  nohup bash -c "\
    curl -L -C - -o $HOME/iotex-var/data.tar.gz https://t.iotex.me/mainnet-data-snapshot-core-latest && \
    tar -xzf $HOME/iotex-var/data.tar.gz -C $HOME/iotex-var/data/ && \
    echo DONE > $HOME/iotex-var/snapshot.status \
  " > $HOME/iotex-var/snapshot.log 2>&1 &
  ```
- **Disk space:** if the target partition has less than 500GB free, warn the user before proceeding.

## Upgrade

```bash
bash ~/setup_fullnode.sh --auto --home=$HOME/iotex-var
```

Upgrades preserve `externalHost`, `producerPrivKey`, and `adminPort`. No snapshot download needed — only the binary and configs are updated. Downtime is minimized by pulling the new image before stopping the old container.

## Verify

```bash
docker ps | grep iotex
docker logs -f --tail 20 iotex | grep -E "height|sync|error"
```

The node is healthy when block heights are increasing with no `fatal` errors.

## Ports

| Port | Purpose | Required |
|---|---|---|
| 4689 | P2P network | Always |
| 8080 | HTTP stats | Always |
| 14014 | gRPC API | Gateway only |
| 15014 | Ethereum JSON-RPC API | Gateway only |
| 16014 | Ethereum WebSocket | Gateway only |
