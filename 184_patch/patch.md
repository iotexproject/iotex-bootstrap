# v1.8.4 patch
In the past 2 weeks certain IoTeX nodes run into an issue of failing to sync with
most recent blocks. After careful analysis it was root-caused to an incorrect state
in memory storage, which may occur when a node restarts.

## Impact
A node could be affected by this issue if it has restarted sometime between Sep 30
and Oct 08, 2002. It will get stuck on a certain height if it happens.

## Solution
This issue has been fixed in the v1.8.4 release. A script tool has been provided
to download a patch file, which would correctly restore the internal state. 

This fix is **not** a hard-fork, and is **only** needed one-time. After applying
the patch, the node will be able to successfully restart and continue to run. It
does **not** need to rely on this patch in the future restarts.

Follow steps below to apply the patch and upgrade to v1.8.4.

## Apply the patch
1. First, stop your IoTeX node and remove the docker container. This is **needed**
to ensure that the patch fix can be applied correctly and the node can successfully
restart later. 
2. Download the patch script:
```
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v1.8.4/184_patch/patch.sh > ./patch.sh
```
3. `chmod a+x ./patch.sh`
4. Make sure you have the `$IOTEX_HOME` environment variable properly set. It is
the full-node home directory containing all node settings and data files in the
`/etc`, `/data`, `/log` sub-directories. By default, it is `/iotex-var`, you can
check it by `echo $IOTEX_HOME`. If it is not set, when you run the script in the
next step you will be asked to input it, make sure you enter the right directory
using absolute path. 
5. Run the script `./patch.sh`, it will download the proper patch file, you will
see message like:
```
download /iotex-var/data/19901069.patch success, please upgrade to v1.8.4 and restart iotex-server
```

## Upgrade to v1.8.4
Now with the correct path file in place, it's time to upgrade to v1.8.4. 
```
docker pull iotex/iotex-core:v1.8.4
```
Restart your node as usual, but use `iotex/iotex-core:v1.8.4` image in the docker
script/commandline. Your node should apply the patch file, and then continue to
run normally.
