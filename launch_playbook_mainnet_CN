# 主网上线操作手册

这是IoTeX主网上线的指导手册。它是关于IoTeX主网上线最全面的知识手册

# 注册成为节点候选人并获得投票
一开始，您应该在门户网站注册成为一个节点，您可以通过以下地址进入：

- 主网: https://member.iotex.io/profile/name-registration
- 主网预演: https://member-reherasal.iotex.io/profile/name-registration
- 测试网络: https://member-testnet.iotex.io/profile/name-registration

一经注册，您的节点就会分别被显示在 https://member.iotex.io, https://member-reherasal.iotex.io 
或者 https://member-testnet.iotex.io 上，并且可以接受投票。确保您有填写操作地址(用于操作
节点)和奖励地址(用于获得奖励)。这两个地址都是以 `io` 开头，并且可以由[ioctl](https://docs.iotex.io/#create-account-s)
工具产生。为了更高的安全性，他们应该是不同的地址。

具体而言，共有四种角色，并且后者包含前者：
- 活跃共识节点：24个从共识节点中随机选取的，且负责在每个周期(一小时)产生区块的节点
- 共识节点：获得票数最多的前36个节点
- 节点：获得2,000,000选票且自我质押1,200,000IOTX到自己节点的候选人
- 候选人：所有注册的节点

为了主网成功上线， **前18名候选人必须要参加**；**前12名候选人和24名机器人作为共识节点一起工作，产生区块**。一旦
成功上线，主网保持稳定后，所有前36名候选人都会参加。

# 准备合格的机器
推荐配置：
```
服务器：主服务器和备份服务器
• 内存：32 GB RAM
• 本地存储：1 TB SSD，具有1000+ IOPS
• 处理器：8核（每个2.4 GHz）
• 网络：100 Mb /秒
```

你应该运行[这个脚本](https://raw.githubusercontent.com/iotexproject/iotex-bootstrap/master/scripts/get_systemstat.sh)
获取基本硬件信息。请注意，慢速网络和慢速本地存储会对节点的生产率产生显着的负面影响。

# 设置操作节点
请遵循[这个指导](https://github.com/iotexproject/iotex-bootstrap/blob/master/README.md) 来设置操作节点

一旦节点完全同步，请在[这里](https://member.iotex.io/profile/technical/) 填写其域名/静态IP以及您的联系信息。我们可以监控共识节点状态，并在出现问题时通知您。请勿与其他人分享此信息！

# 产生区块并且获得奖励
一旦节点启动并运行并排在前12位，它将参与共识。 [ioctl](https://docs.iotex.io/#cli-command-line-interface)是确保您的节点注册的最佳工具。如果是这样，它开始从某个时期生成块。请注意，一个周期包含360个块，大约一个小时。每10秒生成一个块，每个块会获得16个IOTX。在每个时代完成之后，所有节点将会按各自投票占比共同分享12,500 IOTX的周期奖励。此外，至多36名共识节点将会在前8760个周期(大约一年)，每个周期分享2,880IOTX的基金奖励。

**如果一个节点正在参与共识（作为一个活跃的共识代表）并且在这个周期错过了超过2个区块，那么它的所有周期奖励将被剥夺**，
虽然区块奖励（如果它实际产生了块）和基金奖励还可以获得。可以在[这里](https://iotex.io/consensus-delegate-handbook.pdf)获得更多信息


因此，启动并运行多个操作节点始终是一种很好的做法。一位当选主设备参与了共识，而其他附属设备被动同步。如果主设备发生故障（例如，软件崩溃，硬件错误），其中一个从设备将自动升级为主设备并继续参与共识。请参阅[这里]（infra / infraguide.md＃high-availability）进行主设备选举和故障转移。

请使用ioctl工具来核查[check](https://docs.iotex.io/#query-reward)和取出[claim](https://docs.iotex.io/#claim-reward)奖励，并使用iotex- tube服务(TBD)将本地IOTX兑换成ERC20 IOTX以进行质押和交易。

# 基础设施配置指导
请参阅[本指南](https://github.com/iotexproject/iotex-bootstrap/blob/master/infra/infraguide.md)设置基础架构（而不是单独节点）以获得高出块效率。

请参阅[本指南](https://github.com/iotexproject/iotex-bootstrap/tree/master/infra/monitoring)设置仪表板以监控节点。

# 安全措施配置指导
TBD

Stanford CPC 贡献
