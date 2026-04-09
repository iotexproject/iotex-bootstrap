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

1. **Check available disk space** — first check the actual snapshot size, then compare against free disk:
   ```bash
   # Step 1: Check current compressed snapshot size (as of 2026-04, ~182GB compressed, ~265GB extracted)
   curl -sIL https://t.iotex.me/mainnet-data-snapshot-core-latest 2>/dev/null | grep -i content-length
   # Step 2: Check free disk on all partitions
   df -h
   ```
   - These sizes grow over time — always check the URL first, don't rely on the numbers above.
   - Core node: extracted size + growth headroom (as of 2026-04, ~300GB minimum). Gateway node: 1TB+.
   - If using stream extraction (curl | tar), only the extracted size is needed. If downloading tarball first, both compressed + extracted sizes are needed.
   - If no single partition is large enough, tell the user to resize the disk or attach additional storage before proceeding.
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
- **Fresh install in `--auto` mode** now works without interactive prompts:
  - `externalHost` is auto-detected via `curl -4 ip.sb` (forced IPv4 — p2p layer does not handle IPv6).
  - A random `producerPrivKey` is auto-generated as a temporary operator wallet.
  - After install, ask the user: "A temporary operator key was generated. Do you want to fund this wallet for staking, or replace it with an existing key in `$IOTEX_HOME/etc/config.yaml`?"
- **`externalHost` must be IPv4.** The script now uses `curl -4 ip.sb` by default. If the detected IP is wrong, update `$IOTEX_HOME/etc/config.yaml` and restart.
- **Snapshot download:** The `--snapshot` flag downloads the snapshot to `$IOTEX_HOME/tmp/` and extracts it. This requires enough disk to hold both the compressed tarball and the extracted data on the same partition. The compressed snapshot is ~182GB and extracts to ~265GB (as of 2026-04) — these sizes grow over time, always verify by checking the URL as shown above.
  - **Manual download (recommended for large snapshots):** Instead of using `--snapshot`, download the snapshot yourself before running the script. This lets you use a separate disk/volume for the tarball and supports resume on failure. Run the setup script without `--snapshot` afterward — the script detects existing data in `$IOTEX_HOME/data/`:
    ```bash
    apt-get install -y pigz
    mkdir -p $IOTEX_HOME/data
    # Download with resume support (use a separate disk/volume if main disk is too small)
    DOWNLOAD_DIR=$IOTEX_HOME  # or /mnt/volume if main disk can't hold both
    until curl -L -C - -o $DOWNLOAD_DIR/snapshot.tar.gz \
      --retry 20 --retry-delay 10 --speed-limit 100000 --speed-time 120 \
      https://t.iotex.me/mainnet-data-snapshot-core-latest; do
      echo "Download interrupted, resuming in 30s..."; sleep 30
    done
    # Extract with parallel decompression, then clean up
    pigz -dc $DOWNLOAD_DIR/snapshot.tar.gz | tar -xf - -C $IOTEX_HOME/data/
    rm -f $DOWNLOAD_DIR/snapshot.tar.gz
    ```
    For even faster downloads, use `aria2c -x16 -s16` instead of curl (16 parallel connections). aria2c also supports resume via `--continue=true`.
  - **Stream extraction (fallback — only when disk is very constrained):** Pipe curl directly into tar — no intermediate file, but cannot resume on failure. Only use when you truly cannot attach a temporary volume:
    ```bash
    apt-get install -y pigz
    mkdir -p $IOTEX_HOME/data
    # No resume — restarts from scratch on failure
    ATTEMPT=0; MAX=5
    until [ $ATTEMPT -ge $MAX ]; do
      ATTEMPT=$((ATTEMPT + 1)); echo "Attempt $ATTEMPT/$MAX"
      rm -rf $IOTEX_HOME/data/*
      curl -L -s --retry 10 --retry-delay 5 --speed-limit 100000 --speed-time 60 \
        https://t.iotex.me/mainnet-data-snapshot-core-latest | pigz -d | tar -xf - -C $IOTEX_HOME/data/ && break
      echo "Failed, retrying in 30s..."; sleep 30
    done
    ```
- **Disk space:** always verify the current snapshot size from the URL before proceeding. Ensure the target partition has enough free space plus growth headroom. If the main disk can't hold both the compressed and extracted data, attach a temporary volume for the download — it only needs to hold the compressed file and can be deleted after extraction. If the target partition is too small even for extracted data, suggest the user resize the disk before proceeding.

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
