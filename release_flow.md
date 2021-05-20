# Release Flow
This doc lists out the steps for preparing, cutting and rolling out a release of iotex-core. 

## Prepare
1. Cut release candidate, e.g., v1.2.1_rc1, v1.2.2_rc2
2. Roll out the candidate to testnet and observe all chain metrics
3. Put in necessary bug fixes, performance improvements
4. If necessary repeat steps 1 - 3
5. Once stablized, revise the tag by removing `rc*`, e.g., v1.2.1_rc5 becomes v1.2.1

## Rollout
6. Notify the community
7. Notify all delegates
8. Notify all exchanges who run nodes
