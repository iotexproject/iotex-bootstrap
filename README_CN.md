# IoTeX 主网预演手册

## 更新

节点现在可以将主网更新到 v0.5.1了。请确保你下载了最新的`genesis.yaml` 并且在重启节点之前覆盖现在的`genesis.yaml`

## 索引

- [版本状态](#status)
- [加入主网预演](#mainnet)
- [加入测试网络](#testnet)
- [与区块链交互](#ioctl)
- [操作您的节点](#ops)


## <a name="status"/>版本状态

主网：[v0.5.1](https://github.com/iotexproject/iotex-core/tree/0810e5166d12c7ae06110cf6429f332c59585056)
测试网：v0.5.1


## <a name="mainnet"/>加入主网内测

1. 提取(pull) docker镜像

```
docker pull iotex/iotex-core:v0.5.1
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

我们将会每天更新一次snapshot


5. 运行以下命令以启动节点:

```
docker run -d --restart on-failure --name iotex \
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.1 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

现在您的节点应该已经被成功启动了

请注意，上述命令同时也会让您的节点变成一个网关，可以处理来自用户的API请求。如果您不想启用此功能，可以从上面的命令中删除两行: `-p 14014:14014 \` 和 `-plugin=gateway`.

6. 确保您的防火墙和负载均衡器（如果有）上的TCP端口4689, 14014, 8080已打开。

## <a name="testnet"/>加入测试网络

加入测试网络基本没有什么不同，只是在第二步，您需要使用以下的源文件：
```
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/config_testnet.yaml > $IOTEX_HOME/etc/config.yaml
curl https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/genesis_testnet.yaml > $IOTEX_HOME/etc/genesis.yaml
```

在第四步，您需要使用针对于测试网络的snapshot: https://t.iotex.me/data-testnet-latest。

在第五步，您需要将docker镜像的标签替换成``iotex/iotex-core:v0.5.1``。


## <a name="ioctl"/>与区块链交互


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

## <a name="ops"/>操作您的节点

### 检查节点记录

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
