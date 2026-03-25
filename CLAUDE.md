# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is the **IoTeX Delegate Manual** repository - configuration and operational scripts for IoTeX blockchain validators and delegates. It is NOT a code repository in the traditional sense; instead, it provides:

- Node configuration files for MainNet and TestNet
- Shell scripts for node setup, upgrade, and monitoring
- Docker compose configurations for running nodes
- Documentation for node operators

## Version Alignment

This repository is versioned in sync with [iotex-core](https://github.com/iotexproject/iotex-core). The current release is **v2.3.8**. When iotex-core releases a new version:
1. Update version references in README.md, config files, and scripts
2. Add a release note in `changelog/`
3. Create a PR but do NOT merge until the final release is tagged in iotex-core

See `release_flow.md` for the complete release process.

## Key Directories

| Directory | Purpose |
|-----------|---------|
| `scripts/` | Node setup, upgrade, and monitoring automation scripts |
| `config_mainnet.yaml` / `config_testnet.yaml` | Node configuration templates |
| `genesis_mainnet.yaml` / `genesis_testnet.yaml` | Genesis block configurations |
| `monitor/` | Docker compose and prometheus configs for node monitoring |
| `infra/` | Infrastructure guides and best practices for delegates |
| `changelog/` | Release notes for each version |
| `tools/auto-update/` | Auto-updater binary and Makefile |
| `tube/` | Documentation for ERC20/native token swap service |
| `archive-node.md` | Archive node setup instructions |
| `poll/` | Community poll documentation |

## Common Tasks

### Update for a new iotex-core release
1. Update `version` references in README.md (search for `v2.3.8`)
2. Update docker image tags in `scripts/all_in_one_mainnet.sh` and `scripts/all_in_one_testnet.sh`
3. Add release note in `changelog/vX.Y.Z-release-note.md`
4. Update `config_mainnet.yaml` and `config_testnet.yaml` if needed

### Quick node setup (MainNet)
```bash
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh)
```

### One-line upgrade
```bash
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh)
```

### Run with gateway plugin (for API serving)
```bash
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) plugin=gateway
```

### Stop auto-upgrade cron job
```bash
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/stop_fullnode.sh)
```

## Node Architecture

### Node Types
1. **Regular Node**: Participates in p2p network, syncs blocks
2. **Delegate/Validator Node**: Has `producerPrivKey` set, participates in consensus (ROLLDPOS)
3. **Gateway Node**: Runs with `-plugin=gateway`, enables API indexing for external queries
4. **Archive Node**: Serves full historical chain data (separate setup - see archive-node.md)

### Key Ports
- `4689`: P2P network
- `8080`: HTTP API (liveness/readiness probes)
- `14014`: IoTeX native gRPC API
- `15014`: Ethereum JSON-RPC API
- `16014`: Ethereum WebSocket API

### Configuration Structure
- `config_*.yaml`: Node settings (network, chain, actPool, api, consensus)
- `genesis_*.yaml`: Genesis block data
- `trie.db.patch`: Required patch file for MainNet

### High Availability Setup
Multiple nodes can share the same `producerPrivKey` with different `masterKey` values:
```yaml
network:
  masterKey: producer_private_key-replica_id
system:
  active: true  # or false for standby nodes
```
Use `http://ip:9009/ha?activate=true/false` to switch active/standby roles.

## Gravity Chain Binding

IoTeX uses Ethereum as its gravity chain for delegate elections. Nodes need Ethereum JSON-RPC endpoints configured in:
```yaml
chain:
  committee:
    gravityChainAPIs:
      - https://mainnet.infura.io/v3/YOUR_KEY
```

## Snapshot URLs
- MainNet core: `https://t.iotex.me/mainnet-data-snapshot-core-latest`
- MainNet gateway: `https://t.iotex.me/mainnet-data-snapshot-gateway-latest`
- TestNet: `https://t.iotex.me/testnet-data-latest`

## Related Repositories
- [iotex-core](https://github.com/iotexproject/iotex-core): Main node implementation
- [iotex-analyser](https://github.com/iotexproject/iotex-analyser): Chain analytics backend
- [ioctl](https://github.com/iotexproject/iotex-core/tree/master/ioctl): CLI tool for blockchain interaction
