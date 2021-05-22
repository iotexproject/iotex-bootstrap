# Release Flow
This doc lists out the steps for preparing, cutting and rolling out a release
of iotex-core. 

## Testing release candidate
1. Cut release candidate, e.g., v1.2.1_rc1
```
git tag v1.2.1_rc1
git push origin v1.2.1_rc1
```

2. Roll out the release candidate to testnet. There are 2 clusters to upgrade:
[testnet-gcp](https://github.com/iotexproject/iotex-cluster/blob/master/scripts/testnet-gce.sh)
[testnet-gcp-2](https://github.com/iotexproject/iotex-cluster/blob/master/scripts/testnet-gce-2.sh)

> Note: do NOT directly run these 2 scripts. Run `helm upgrade --dryrun --debug
> xxx > helm.log` first to dump the configuration about to deploy. Verify the
> config in `helm.log` to make sure it is the correct/intended config.

3. Test the release candidate, observe all chain metrics. If a bug is found or
perf improvement is needed, check-in fix to iotex-core, go back to step 1. 

4. Once testing is stablized, revise the tag by removing `rc*`, e.g., v1.2.1_rc5
becomes v1.2.1, and cut the official release.
```
git tag v1.2.1
git push origin v1.2.1
```

## Prepare release note and instruction
The following are prep work in [bootstrap](https://github.com/iotexproject/iotex-bootstrap) repo
1. Add a release note, like [this](https://github.com/iotexproject/iotex-bootstrap/blob/master/changelog/v1.2-release-note.md)
2. Make necessary change to config and genesis if needed, like [this](https://github.com/iotexproject/iotex-bootstrap/commit/e06bc1f846a6eb1cec4b852c46c411c954d51e79)
3. Update the version in README.md to the new release, and add an instruction
if necessary, like [this](https://github.com/iotexproject/iotex-bootstrap/commit/bb52592f501e45b2f52bc084622f355414793df1)
4. Make a release of the bootstrap repo same as the **new release version**,
like [this](https://github.com/iotexproject/iotex-bootstrap/releases/tag/v1.2.0)

## Make iotex-core release 
1. Make the release on iotex-core repo, like [this](https://github.com/iotexproject/iotex-core/releases/tag/v1.2.0)
2. Rollout the release to mainnet. There are also 2 clusters to upgrade:
[mainnet-gcp](https://github.com/iotexproject/iotex-cluster/blob/master/scripts/prod-gce.sh)
[mainnet-gcp-delegates](https://github.com/iotexproject/iotex-cluster/blob/master/scripts/prod-delegates.sh)

## Rollout
1. Notify the community. Marketing team to announce in Twitter/TG/Discord/wechat/email
2. Notify all delegates. We'll ping delegate contact in group conversation
3. Notify all exchanges who run IoTeX nodes
- binance
- huobi
- KuCoin
- mxc
- coinone
- upbit
- bittrex
