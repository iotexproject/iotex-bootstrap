# IoTeX 节点候选人手册

*最新版本请参考 https://github.com/iotexproject/iotex-bootstrap/blob/master/README.md*

## 索引

- [发布状态](#status)
- [加入主网](#mainnet)
- [不使用Docker加入主网](#mainnet_native)
- [加入测试网络](#testnet)
- [与区块链交互](#ioctl)
- [节点操作](#ops)
- [节点升级](#upgrade)
- [网关插件](#gateway)
- [常见问题](#qa)

## <a name="status"/>发布状态

以下是当前我们使用的软件版本：

- 主网：v2.2.1

## <a name="testnet"/>加入测试网
如果你要启动节点加入测试网，请点击[**加入测试网**](https://github.com/iotexproject/iotex-bootstrap/blob/master/README_CN_testnet.md)

## <a name="mainnet"/>加入主网

以下是启动 IoTeX 节点的推荐方式

> 所有步骤已集成在scripts/all_in_one_mainnet.sh, 可以直接`sh scripts/all_in_one_mainnet.sh`

1. 提取(pull) docker镜像

```
docker pull iotex/iotex-core:v2.2.1
```

2. 使用以下命令设置运行环境

```
mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.2.1/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.2.1/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/v2.2.1/trie.db.patch > $IOTEX_HOME/data/trie.db.patch
```

3. 编辑 `$IOTEX_HOME/etc/config.yaml`, 查找 `externalHost` 和 `producerPrivKey`, 取消注释行并填写您的外部 IP 和私钥。如果`producerPrivKey`放空，你的节点将被分配一个随机密钥。

4. 下载全量数据快照, 请运行以下命令:
```
curl -L https://t.iotex.me/mainnet-data-snapshot-latest > $IOTEX_HOME/data.tar.gz
```
或者 请运行以下命令
```
curl -L https://storage.iotex.io/mainnet-data-snapshot-latest.tar.gz > $IOTEX_HOME/data.tar.gz
```

**我们将会在每月一日更新全量数据快照**。

5. 下载最新增量数据, 请运行以下命令(可选):

```
curl -L https://storage.iotex.io/mainnet-data-incr-latest.tar.gz > $IOTEX_HOME/incr.tar.gz
```

**我们将会每天更新一次增量数据快照**。

同时我们提供7日内的增量包下载，你可以选择这期间中任意一天。比如你想使用2025.4.27日的数据， 那么增量包的文件名称为`mainnet-data-incr-2025-04-27.tar.gz`， latest为今日的数据。 还原的时候只需当月的全量包 + 当日的增量包即可。

6. 解压数据包, 请注意解压顺序, 必须先解压全量包, 再解压增量包

```
tar -xzf $IOTEX_HOME/data.tar.gz -C $IOTEX_HOME/data/ && tar -xzf $IOTEX_HOME/incr.tar.gz -C $IOTEX_HOME/data/
```

对于高级用户，可以考虑以下三个选项：

- 选项1：如果计划将节点作为[网关](#gateway)运行，请使用带有索引数据的快照：https://t.iotex.me/mainnet-data-with-idx-latest.

  或从另一个站点下载:
```
curl -L https://storage.iotex.io/mainnet-data-with-idx-latest.tar.gz > $IOTEX_HOME/data.tar.gz
tar -xzf data.tar.gz
```

> mainnet-data-with-idx-latest.tar.gz 在每周一会打新的压缩包

- 选择2：如果计划从 0 区块高度开始同步链上数据而不使用来自以太坊旧的节点代表数据，执行以下命令设置旧的节点代表数据：
```
curl -L https://storage.iotex.io/poll.mainnet.tar.gz > $IOTEX_HOME/poll.tar.gz; tar -xzf $IOTEX_HOME/poll.tar.gz --directory $IOTEX_HOME/data
```

- 选择3：如果计划从 0 区块高度开始同步链并从以太坊获取旧的节点代表数据，请更改 config.yaml 中的 `gravityChainAPIs`并在支持以太坊存档模式的情况下使用您的 infura 密钥，或将 API 端点更改为您有权限访问的以太坊存档节点。

7. 运行以下命令以启动节点:

```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v2.2.1 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml
```

现在您的节点应该已经被成功启动了！

如果您还希望使节点成为[网关](#gateway)，可以处理用户的API请求，请改用以下命令：
```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v2.2.1 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

7. 确保您的防火墙和负载均衡器（如果有）上的TCP端口4689, 8080（14014如果节点启用了网关）已打开。

## <a name="mainnet_native"/>不使用Docker加入主网

这不是我们推荐的启动 IoTeX 节点的首选方式

1. 使用以下命令设置环境：
与[加入主网](#mainnet)的步骤 2 相同

2. 构建服务器二进制文件：
```
git clone https://github.com/iotexproject/iotex-core.git
cd iotex-core
git checkout v2.2.1

// optional
export GOPROXY=https://goproxy.io
go mod download
make clean build-all
cp ./bin/server $IOTEX_HOME/iotex-server
```

3. 编辑配置
与[加入主网](#mainnet)的步骤 3 相同。如果不将它们放在 `/var/data/` 下，请确保将 config.yaml 中的所有数据库路径更新到正确的位置

4. 从数据快照启动
与[加入主网](#mainnet)的步骤 4 相同

5. 运行以下命令以启动节点:
```
nohup $IOTEX_HOME/iotex-server \
        -config-path=$IOTEX_HOME/etc/config.yaml \
        -genesis-path=$IOTEX_HOME/etc/genesis.yaml &
```
现在此节点应该已成功启动。

如果您还希望使节点成为[网关](#gateway)，可以处理用户的API请求，请改用以下命令：
```
nohup $IOTEX_HOME/iotex-server \
        -config-path=$IOTEX_HOME/etc/config.yaml \
        -genesis-path=$IOTEX_HOME/etc/genesis.yaml \
        -plugin=gateway &
```

6. 确保您的防火墙和负载均衡器（如果有）上的TCP端口4689, 8080（14014如果节点启用了网关）已打开。

## <a name="ioctl"/>与区块链交互

你可以安装 `ioctl` (用于与IoTeX区块链交互的命令行工具)

```
curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh
```

您可以将`ioctl`指向您的节点（如果您启用[网关](#gateway)插件）：
```
ioctl config set endpoint localhost:14014 --insecure
```

或者您可以将它指向我们的API节点:

- 主网安全端口: `api.iotex.one:443`
- 主网非安全端口: `api.iotex.one:80`

如果你准备使用非安全端口，你需要添加`--insecure`参数。

生成密钥:
```
ioctl account create
```

获得当前epoch共识节点的数量:
```
ioctl node delegate
```

参考 [CLI document](https://github.com/iotexproject/iotex-core/blob/master/cli/ioctl/README.md) 获得更多细节

### 其他常用命令

获取奖励:
```
ioctl action claim ${amountInIOTX} -l 10000 -p 1 -s ${ioAddress|alias}
```

通过Tube服务将IoTeX令牌交换到以太坊上的ERC20令牌:

```
ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 ${amountInIOTX} -s ${ioAddress|alias} -l 400000 -p 1 -b d0e30db0
```
单击 [IoTeX Tube docs](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/tube.md) 获取tube服务的详细文档。

## <a name="ops"/>节点操作

### 检查节点日志

可以使用以下命令访问容器(container)日志。

```
docker logs iotex
```

内容可以用以下命令筛选:

```
docker logs -f --tail 100 iotex |grep --color -E "epoch|height|error|rolldposctx"
```

### 停止和删除容器(container)

使用```--name=iotex```启动container时，你必须在产生一个新的container之前先移除之前的container

```
docker stop iotex
docker rm iotex
```

### 暂停和重启container

可以使用以下命令“停止”和“重新启动”container:

```
docker stop iotex
docker start iotex
```

## <a name="upgrade"/>节点升级
确保你已经设置了`$IOTEX_HOME`，并且所有文件（configs、dbs 等）都放在正确的位置（请参阅加入“主网”）。

请使用以下命令升级主网节点。 默认情况下，它将升级到最新的主网版本：
```bash
sudo bash # If your docker requires root privilege
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh)
```

在主网上启用 [网关](#gateway)
```bash
sudo bash # If your docker requires root privilege
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/setup_fullnode.sh) plugin=gateway
```

如果需要停止自动升级 cron job 和 iotex 服务器程序，您可以运行以下指令：
```bash
sudo bash # If your docker requires root privilege
bash <(curl -s https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/stop_fullnode.sh)
```

## <a name="gateway"/>网关插件

为服务更多详细链信息的 API 请求，启用网关插件的节点将执行额外的索引。例如区块中的操作数量或通过哈希查询操作信息。

## <a name="qa"/>常见问题

请参考 [此处](https://github.com/iotexproject/iotex-bootstrap/wiki/Q&A) 了解常见问题。
