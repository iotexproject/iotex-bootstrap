# IoTeX 节点候选人手册

*最新版本请参考 https://github.com/iotexproject/iotex-bootstrap/blob/master/README.md*

## 最新动态
- 我们在v0.9.0中发现了一个错误，该错误可能导致节点在委托列表上不一致。我们已经推出了v0.9.1版来解决此问题。
- v0.9.0已发布，因此委托节点应将其软件升级到此新版本。该分叉将发生在块高度1641601处。在使用v0.9.0 docker image重新启动之前，请首先重新获取最新的mainnet创世区块配置文件。这是此升级的必需步骤。此外，请注意，此升级将导致重新启动时迁移数据库，这可能需要30分钟到1个小时才能完成。因此，请在委托节点不在有效共识时期时进行升级。
- 我们重置了测试网，并部署了v0.8.3，最后将其升级到v0.9.0。配置文件也已更新。
- 我们已经将主网升级到v0.8.3。它包含一些重大更改，这些更改将在块高度1512001上激活。代表必须在此之前将您的节点升级到新版本。
- 我们已经将testnet升级到v0.8.4。
- 我们已将testnet升级到v0.8.3，其中包含新的错误代码和共识改进。

## 索引

- [版本状态](#status)
- [加入主网预演](#mainnet)
- [加入测试网络](#testnet)
- [与区块链交互](#ioctl)
- [操作您的节点](#ops)


## 发行版本状态

主网：v0.9.1
测试网：v0.9.1


## 加入主网内测

1. 提取(pull) docker镜像

```
docker pull iotex/iotex-core:v0.9.1
```
请检查你的docker镜像的摘要是`ad495eee20a758402d2a7b01eee9e2fdb842be9a1786ba2fb67bf6d440c21625`。

2. 使用以下命令设置运行环境

```
mkdir -p ~/iotex-var
cd ~/iotex-var

export IOTEX_HOME=$PWD

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_mainnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_mainnet.yaml > $IOTEX_HOME/etc/genesis.yaml
```

3. 编辑 `$IOTEX_HOME/etc/config.yaml`, 查找 `externalHost` and `producerPrivKey`, 使用您的ip地址和私钥代替`[...]`，并且取消该行备注 

4. (可选) 如果您想从snapshot启动, 请运行以下命令:

```
curl -L https://t.iotex.me/data-latest > $IOTEX_HOME/data.tar.gz
tar -xzf data.tar.gz
```

我们将会每天更新一次snapshot，如果计划将节点作为网关运行，请使用带有索引数据的快照：https://t.iotex.me/mainnet-data-with-idx-latest.


5. 运行以下命令以启动节点:

```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.9.1 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
```

现在您的节点应该已经被成功启动了

如果您还希望使节点成为网关，可以处理用户的API请求，请改用以下命令：
```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.9.1 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

6. 确保您的防火墙和负载均衡器（如果有）上的TCP端口4689, 8080（14014如果使用）已打开。

## 加入测试网络

加入测试网络基本没有什么不同，只是在第二步，您需要使用以下的源文件：
```
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_testnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_testnet.yaml > $IOTEX_HOME/etc/genesis.yaml
```

在第四步，您需要使用针对于测试网络的snapshot:  https://t.iotex.me/testnet-data-latest 和 https://t.iotex.me/testnet-data-with-idx-latest.

在第五步，您需要将docker镜像的标签替换成``v0.9.1``。


## 与区块链交互


你可以安装 ioctl (用于与IoTeX区块链交互的命令行界面)

```
curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh
```

您可以将`ioctl`指向您的节点
```
ioctl config set endpoint localhost:14014 --insecure
```

或者您可以将它指向我们的节点:

- 主网安全端口: api.iotex.one:443
- 主网安非全端口: api.iotex.one:80
- 测试网安全端口: api.testnet.iotex.one:443
- 测试网安全端口: api.testnet.iotex.one:80

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

## 其他常用命令
获取奖励:
```
ioctl action claim ${amountInIOTX} -l 10000 -p 1 -s ${ioAddress|alias}
```

通过Tube服务将IoTeX令牌交换到以太坊上的ERC20令牌:

```
ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 ${amountInIOTX} -s ${ioAddress|alias} -l 400000 -p 1 -b d0e30db0
```

## 操作你的节点

## 检查节点记录

可以使用以下命令访问容器(container)日志。

```
docker logs iotex
```

内容可以用以下命令筛选:

```
docker logs -f --tail 100 iotex |grep --color -E "epoch|height|error|rolldposctx"
```

## 停止和删除容器(container)

你必须在产生一个新的container之前先移除之前的container

```
docker stop iotex
docker rm iotex
```

## 暂停和重启container

可以使用以下命令“停止”和“重新启动”container:

```
docker stop iotex
docker start iotex
```
