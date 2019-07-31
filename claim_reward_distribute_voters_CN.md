本文档将指导您如何领取奖励并分发给您的投票者。以下是本指南将涵盖的所有主题的预览：
* [必要条件](#prerequisite)
* [领取奖励](#claim-rewards)
* [转换到ETH-erc20代币](#swap-to-ethereum-erc20-token)
* [分发给投票者](#distribution-to-voters)

# 必要条件

在进行以下任何一个步骤之前，请安装我们的`ioctl`命令行工具

##安装ioctl工具

`ioctl` 是一个创建/管理IoTeX地址并与我们的主网区块链交互的工具。如要了解更多细节，请参阅[如何安装ioctl](https://github.com/iotexproject/iotex-bootstrap#interact-with-blockchain)

在安装之后，确保ioctl指向我们的主网安全端点 `api.iotex.one:443` 您可以使用如下命令设置：

`ioctl config set endpoint api.iotex.one:443`

### 导入您的账户

**我们推荐您使用ioctl工具创建您的IoTeX奖励地址。**如果您的IoTeX地址是使用ioctl工具创建的，请跳过本小节中的其余部分。否则，如果您使用通过ETH地址映射IoTeX地址，则需要导入ETH地址的私钥以管理IoTeX地址。

请放心，`ioctl`工具不会将您的私钥存储为明文，密钥是使用以太坊的密钥库包以加密格式导入的，并受您设置的密码保护。要导入您的帐户，请在终端中运行以下命令：

```ioctl account import ${account_name}```

例如，您如果想命名您的账户为 `my_primary_account`， 你可以输入：

```ioctl account import my_primary_account```

点击`Enter`后，系统将提示您输入私钥。复制您的ETH私钥（十六进制字符串）并粘贴它（它不会显示在屏幕上）;按`Enter`，系统将提示您设置密码。输入一个强密码，点击`Enter`，系统会提示您重新输入密码，输入相同的密码，按Enter键即可看到。

```New account #my_primary_account is created. Keep your password, or you will lose your private key.```

### 核查您的余额

在终端中运行以下命令以查询地址中的余额：

```ioctl account balance ${io_address|account_name}```

例如，您可以使用以下命令核查您的帐户`my_primary_account`的余额：

```ioctl account balance my_primary_account```

您将在输出中找到IOTX中的余额。

---

# 领取奖励

所有节点奖励(block rewards, epoch bonus reward, foundation bonus)将作为“未被领取的奖励”发送到您的奖励地址。在交换/分发区块链之前，您必须从区块链中获得这些奖励。您将通过如下步骤领取。

## 查询您的奖励

在终端中运行以下命令以查询帐户中的奖励：

```ioctl node reward ${io_address|account_name}```

您将在输出中找到IOTX中未被领取的奖励金额。

## 领取您的奖励

为了领取您的奖励，在终端中输入以下命令：

```ioctl action claim ${amount_in_iotx} -l 10000 -p 1 -s ${io_address|name}```

例如，如果您希望从帐户`my_primary_account`中提取1200 IOTX，则可以输入以下命令：

```ioctl action claim 1200 -l 10000 -p 1 -s my_primary_account```

如果您领取成功，您会发现帐户余额有所增加。

---

# 交换为ETH ERC代币
我们提供服务，通过固定合约将IoTeX主网代币交换到[IoTeX网络ERC20令牌](https://etherscan.io/token/0x6fb3e0a217407efff7ca062d46c26e5d60a14d69)
**io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5**

## 转换IOTX代币到固定合约

要调用固定合约，请在终端中运行以下命令：

```ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 ${amount} -s ${io_address|account_name} -l 400000 -p 1 -b d0e30db0```

命令中的`amount`应该等于您要交换的金额加上费用（20 IOTX）。例如，如果要从帐户`my_primary_account`交换30000 IOTX，则可以输入：

```ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 30020 -s my_primary_account -l 400000 -p 1 -b d0e30db0```

系统将提示您输入密码，然后输入`yes`进行确认。

>注意：固定合约规定最低金额为1020，最高金额为1,000,020 IOTX。不在此范围内的金额将自动被拒绝。合约将收取20个代币作为每次交易的手续费，因此最小/最大范围是帮助用户以经济的方式进行交换。

由于这个原因，不要转移IoTeX地址中的全部余额，这将被拒绝（因为这不会留下足够的余额来支付手续费）。我们建议在IoTeX地址留下大约100个代币，这样您就可以有足够的余额来支付手续费并在下次使用它。

请保留您的转移的交易代号以供将来核查，尤其是在一些少见的情况下，例如ERC20代币转账失败并且您要求重新执行。

## 核查您收到的ERC20代币
每个IoTeX地址本身与ETH地址相关联，共享相同的私钥。

使用ioctl命令行工具获取与IoTeX地址关联的ETH地址，在终端中运行以下命令：

```ioctl account ethaddr ${io_address|account_name}```

例如，要获取帐户`my_primary_account`的ETH地址：

```ioctl account ethaddr my_primary_account```

您将在输出中找到您的IoTeX地址和相应的ETH地址。然后，您可以在https://etherscan.io上查看ETH地址，以验证您收到的IoTeX Network ERC20代币。

---

#分发给投票者

要向投票者分发奖励，您需要首先使用`bookkeeping`导出分发明细，然后使用一些多重发送工具发送代币或逐个发送。

## 使用`bookkeeping`GraphQL网页工具导出分发明细
您可以使用bookkeeping GraphQL工具计算投票者的奖励。用法是：

```
query {
  delegate(startEpoch: START_EPOCH_NUMBER, epochCount: EPOCH_COUNT, delegateName: DELEGATE_NAME){
    bookkeeping(percentage: PERCENTAGE_OF_DISTRIBUTION, includeFoundationBonus: WHETHER_DISTRIBUTE_FOUNDATION_BONUS){
      exist
      rewardDistribution(pagination: {skip: START_INDEX_OF_DISPLAYING_REWARD_DISTRIBUTION_LIST, first: NUMBER_OF_REWARD_DISTRIBUTIONS_TO_DISPLAY}){
        voterEthAddress
        voterIotexAddress
        amount
      }
      count
    }
  }
}
```

如上所示，您可以通过添加可选返回项**exist**来查看节点在周期范围内是否拥有奖励分发所需的数据记录。您可以通过设置可选参数**pagination**来获取部分奖励分发明细。与此同时，添加可选返回项**count**以用来返回奖励分发的个数。如果选择不设置参数**pagination**，您将会默认收到按投票人以太坊地址排序的完整奖励明细列表。

当您设置好所有参数和返回项后，点击PLAY按钮，奖励明细会出现在界面右边。
<img width="1517" alt="Screen Shot 2019-06-16 at 4 52 48 PM" src="https://user-images.githubusercontent.com/15241597/59571278-07915e80-9058-11e9-8f8f-ee238a822164.png">

您可以在[这里](https://analytics.iotexscan.io/)找到GraphQL网页工具。


## 发送ERC20代币到投票者

要向您的选民发送代币，您可以选择以下工具之一

### IoTeX MultiSend 工具

[multi-send](https://member.iotex.io/multi-send) 是由__IoTeX Foundation__开发的工具，用于将以太坊上的IOTX令牌发送到多个帐户。要使用此工具，您需要登录Metamask。之后，将上述步骤中的csv文件粘贴到“收件人和金额”中。单击“分发ERC-20 IOTX”按钮后，按照Metamask中的说明完成发送代币。

>注意：将自动收取ETH费用。

### 第三方Multisend工具

您还可以尝试一些第三方多发送工具，例如：https://multisender.app


