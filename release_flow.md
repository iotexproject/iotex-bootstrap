# Release Flow
This doc lists out the steps for preparing, cutting and rolling out a release
of iotex-core. 

## Testing release candidate
1. Cut release candidate, e.g., v1.2.1_rc1
```
git tag v1.2.1_rc1
git push origin v1.2.1_rc1
```

2. Roll out the release candidate to testnet. There are 4 clusters to upgrade:
- testnet-gcp (cluster name: "gke_iotex-servers_us-west1-a_iotex-testnet-gcp")
- testnet-gcp-2 (cluster name: "gke_iotex-servers_asia-east1-a_iotex-testnet-gcp-2")
- testnet-london (arn:aws:eks:eu-west-2:363205959602:cluster/testnet-london)
- testnet-sg (arn:aws:eks:ap-southeast-1:363205959602:cluster/testnet-sg)

3. If a release contains a hard-fork, make a release in iotex-analyser repo, 
like [this](https://github.com/iotexproject/iotex-analyser/releases/tag/v1.8.0-rc1), and upgrade the
testnet iotex-analyser backend

4. Test the release candidate, observe all chain metrics. If a bug is found or
perf improvement is needed, check-in fix to iotex-core, go back to step 1. 

5. Repeat the above testing cycle until all bugs/issues are solved, and the release candidate code is
running stable

## Prepare release note and instruction
The following are prep work in [bootstrap](https://github.com/iotexproject/iotex-bootstrap) repo
1. Add a release note, like [this](https://github.com/iotexproject/iotex-bootstrap/blob/master/changelog/v1.2-release-note.md)

2. Make necessary change to config and genesis if needed, like [this](https://github.com/iotexproject/iotex-bootstrap/commit/e06bc1f846a6eb1cec4b852c46c411c954d51e79)

3. Update the version in README.md to the new release, and add an instruction if necessary,
like [this](https://github.com/iotexproject/iotex-bootstrap/commit/bb52592f501e45b2f52bc084622f355414793df1)

4. File a PR to include all these changes, get approvals (but **do not merge yet**)

## Make the final release
1. Tag the final release candidate code by the new release version, e.g., v1.2.1, and push to iotex-core
```
git tag v1.2.1
git push origin v1.2.1
```
this will automatically trigger a build of the image (for the new release tag) on dockerhub,
wait about 20 minutes for the new image to be successfully built and ready

2. Merge the approved PR in bootstrap repo, and make a release same as the **new release version**,
like [this](https://github.com/iotexproject/iotex-bootstrap/releases/tag/v1.2.1)

3. Make a release in iotex-core repo same as the **new release version**, 
like [this](https://github.com/iotexproject/iotex-core/releases/tag/v1.2.1)

4. Make a release in iotex-analyser repo same as the **new release version**, 
like [this](https://github.com/iotexproject/iotex-analyser/releases/tag/v1.4.1), and upgrade
the mainnet iotex-analyser backend

5. Rollout the release to mainnet. There are 3 clusters to upgrade:
- mainnet-gcp (cluster name: "gke_iotex-servers_us-east1-b_iotex-prod-gcp")
- mainnet-gcp-2 (cluster name: "gke_iotex-servers_us-central1_iotex-prod-gcp-2")
- mainnet-gcp-delegates (cluster name: "gke_iotex-servers_us-west1-a_iotex-prod-delegates")

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
