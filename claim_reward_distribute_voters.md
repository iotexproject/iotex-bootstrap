This doc will guide you how to claim rewards and distribute to your voters. Here's a sneak peek of all the topics this guide will cover:
* [Prerequisite](#prerequisite)
* [Claim Rewards](#claim-rewards)
* [Swap to Ethereum ERC20 Token](#swap-to-ethereum-erc20-token)
* [Distribution to Voters](#distribution-to-voters)

# Prerequisite

Before moving onto any of the following sections, please install our `ioctl` commandline tool

## Install ioctl Tool

`ioctl` is a tool to create/manage IoTeX address and interact with our mainnet Blockchain. For more details, please refer to [How to install ioctl](https://github.com/iotexproject/iotex-bootstrap#interact-with-blockchain)

After installation, be sure to point to our mainnet secure endpoint `api.iotex.one:443` by running the following in terminal:

```ioctl config set endpoint api.iotex.one:443```

### Import Your Account

**We recommend that you use the ioctl tool to create your IoTeX Rewards/Beneficiary address.** If your IoTeX address is created using the ioctl tool, skip the rest in this subsection. Otherwise, if your IoTeX address is mapped from your ETH address, you need to import the ETH address's private key in order to manage the IoTeX address.

Rest assured that the `ioctl` tool does not store your private key in cleartext, the key is imported in an encrypted format using Ethereum's keystore package and protected by a password set by you. To import your account, run the following command in the terminal:

```ioctl account import ${account_name}```

For example, if you want to name your account as `my_primary_account`, you can type:

```ioctl account import my_primary_account```

After hitting `Enter`, you will be prompted to enter your private key. Copy your ETH private key (a hex string) and paste it (it won't show up on the screen); hit `Enter` you will be prompted to set password. Enter a strong password, hit `Enter` you will be prompted to re-enter password, enter the same password, hit Enter you will see

```New account #my_primary_account is created. Keep your password, or you will lose your private key.```

### Check Your Balance

Run the following command in terminal to query the balance in your address:

```ioctl account balance ${io_address|account_name}```

For example, you can use the following command to check the balance of your account `my_primary_account`:

```ioctl account balance my_primary_account```

You will find your balance in IOTX in the output.

---

# Claim Rewards

All `Delegate Rewards` (block rewards, epoch bonus reward, foundation bonus) will be sent to your rewards address as “unclaimed rewards”. You must claim these rewards from the blockchain before you can swap/distribute them. The rewards will remain “unclaimed” until you claim them with the following steps.

## Query Your Unclaimed Rewards

Run the following command in terminal to query the unclaimed rewards in your account:

```ioctl node reward ${io_address|account_name}```

You will find the unclaimed reward amount in IOTX in the output.

## Claim Your Rewards

To claim your reward, run in terminal:

```ioctl action claim ${amount_in_iotx} -l 10000 -p 1 -s ${io_address|name}```

For example, if you want ot claim 1200 IOTX from your account `my_primary_account`, you can type the following command:

```ioctl action claim 1200 -l 10000 -p 1 -s my_primary_account```

If your claim is successful, you will notice an increase of the balance in your account.

---

# Swap to Ethereum ERC20 Token

We provide a service to swap the IoTeX mainnet coin to the [IoTeX Network ERC20 token](https://etherscan.io/token/0x6fb3e0a217407efff7ca062d46c26e5d60a14d69) via a lock contract **io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5**.
```
ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 ${amountInIOTX} -s ${ioAddress|alias} -l 400000 -p 1 -b d0e30db0
```
We recommend that you use our [web portal](https://member.iotex.io/tools/iotex) to do the swap. Click [IoTeX Tube docs](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/tube.md) for detailed documentation of the tube service.

---

# Distribution to Voters

To distribute rewards to your voters, you need to first export the distribution with `bookkeeping`, and then send out tokens with some multi-send tool or send them one by one.

## Export Distribution with `bookkeeping` GraphQL web interface
You can use our GraphQL interface tool to get the reward distributions. The usage is:

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

Note that you can add the optional return field **exist** as above to check wether the delegate has bookkeeping information within the specified epoch range. Specifying the optional argument **pagination** would only show you part of the reward distribution list while the optional return field **count** would tell the total number of reward distributions. If you don't specify **pagination** argument, by default you will get the complete reward distribution list sorted by voter's ETH address.

Once you specify all the arguments and return information, click the PLAY button, and you will see the reward information on the right.
<img width="1517" alt="Screen Shot 2019-06-16 at 4 52 48 PM" src="https://user-images.githubusercontent.com/15241597/59571278-07915e80-9058-11e9-8f8f-ee238a822164.png">

You can find the GraphQL web tool [here](https://analytics.iotexscan.io/).

## Send ERC20 Tokens to Voters

To send tokens to your voters, you may choose one of the following tools

### IoTeX MultiSend Tool

[multi-send](https://member.iotex.io/tools/multi-send) is a tool developed by __IoTeX Foundation__ to send IOTX tokens on Ethereum to multi accounts. To use this tool, you need to sign into Metamask. After that, paste the csv file from the above step into "Recipients and Amounts". After clicking the button "Distribute ERC-20 IOTX", follow instructions from Metamask to finish sending tokens.

> Note: A fee in ETH will be charged automatically.

### Third Party MultiSend Tool

You can also try some third party multi-send tools, e.g., https://multisender.app.
