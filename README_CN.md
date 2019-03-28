# IoTeX 测试网络手册

## 更新

查看代码发布[说明](https://github.com/iotexproject/iotex-core/releases/tag/v0.5.0-rc6), 了解v0.5.0-rc6中的新增功能。

**请确保始终绑定到`iotex-testnet`代码库的最新版本**

**注意：对于参与之前测试网络的用户，您必须清理本地数据库！再使用docker镜像v0.5.0-rc6-hotfix1重新启动!**

## 加入测试网络


1. 提取(pull) docker镜象


```
docker pull iotex/iotex-core:v0.5.0-rc6-hotfix1
```

如果从docker hub中提取图像时遇到问题，您也可以在gcloud上尝试我们的镜像
`gcr.io/iotex-servers/iotex-core:v0.5.0-rc6-hotfix1`.

2. 在此数据库下编辑 `config.yaml` ，寻找 `externalHost` 和 `producerPrivKey` 
用您的外部IP和私钥替换`[...]`并取消注释。请查看以下[部分]（#ioctl）以了解如何生成密钥。


3. 导出 `IOTEX_HOME`, 创建目录, 并复制 `https://github.com/iotexproject/iotex-testnet/blob/master/config.yaml` 和 `https://github.com/iotexproject/iotex-testnet/blob/master/genesis.yaml` 到 `$IOTEX_HOME/etc`, 也就是，

```
wget https://raw.githubusercontent.com/iotexproject/iotex-testnet/master/config.yaml
wget https://raw.githubusercontent.com/iotexproject/iotex-testnet/master/genesis.yaml

cd iotex-testnet
export IOTEX_HOME=$PWD #[SET YOUR IOTEX HOME PATH HERE]

mkdir -p $IOTEX_HOME/data
mkdir -p $IOTEX_HOME/log
mkdir -p $IOTEX_HOME/etc

cp config.yaml $IOTEX_HOME/etc/
cp genesis.yaml $IOTEX_HOME/etc/
```

4. 运行下列命令以启动节点

```
docker run -d --name IoTeX-Node\
        -p 4689:4689 \
        -p 14014:14014 \
        -p 8080:8080 \
        -v=$IOTEX_HOME/data:/var/data:rw \
        -v=$IOTEX_HOME/log:/var/log:rw \
        -v=$IOTEX_HOME/etc/config.yaml:/etc/iotex/config_override.yaml:ro \
        -v=$IOTEX_HOME/etc/genesis.yaml:/etc/iotex/genesis.yaml:ro \
        iotex/iotex-core:v0.5.0-rc6-hotfix1 \
        iotex-server \
        -config-path=/etc/iotex/config_override.yaml \
        -genesis-path=/etc/iotex/genesis.yaml \
        -plugin=gateway
```

现在您的节点应该已经被成功启动了

请注意，上述命令同时也会让您的节点变成一个网关，可以处理来自用户的API请求。如果您不想启用此功能，可以从上面的命令中删除两行: `-p 14014:14014 \` 和 `-plugin=gateway`.

5. 确保您的防火墙和负载均衡器（如果有）上的TCP端口4689, 14014, 8080已打开。

## <a name="ioctl"/>与测试网络交互


你可以安装 ioctl (用于与IoTeX区块链交互的命令行界面)

```
curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh
```

确保您的ioctl已经指向了测试网络端点:
```
ioctl config set endpoint api.testnet.iotex.one:80
```

生成密钥:
```
ioctl account create
```

获得当前epoch共识节点的数量:
```
ioctl node delegate
```


参考 [CLI document](https://github.com/iotexproject/iotex-core/blob/master/cli/ioctl/README.md) 获得更多细节

## 检查节点日志

可以使用以下命令访问容器(container)日志。

```
docker logs IoTeX-Node
```

内容可以用以下命令筛选:

```
docker logs -f --tail 100 IoTeX-Node |grep --color -E "epoch|height|error|rolldposctx"
```

## 停止和删除容器(container)

当使用 ```--name=IoTeX-Node```启动一个container, 你必须在产生一个新的container之前先移除之前的container

```
docker stop IoTeX-Node
docker rm IoTeX-Node
```

## 暂停和重启container

可以使用以下命令“停止”和“重新启动”container:

```
docker stop IoTeX-Node
docker start IoTeX-Node
```


## Block快速同步

IoTeX rootchain支持从存档中读取（见下文），这将极大地减少同步所花费的时间。
```
export IOTEX_SANPSHOT_URL=https://storage.googleapis.com/blockchain-archive/$IOTEX_SNAPSHOT_NAME
cd $IOTEX_HOME
wget $IOTEX_SANPSHOT_URL
rm -rf data/
tar -zxvf $IOTEX_SNAPSHOT_NAME
rm -rf $IOTEX_SNAPSHOT_NAME
```
在这些说明之前，如果要将节点作为网关运行, 请运行 `export IOTEX_SNAPSHOT_NAME=data-with-idx-latest.tar.gz`,
否则, `export IOTEX_SNAPSHOT_NAME=data-latest.tar.gz`.

当snapshot准备好之后，运行 `docker run ...` 
