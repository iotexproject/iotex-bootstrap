# Prerequisite

Before moving onto any of the following sections, please install our `ioctl` and `bookkeeper` commandline tool

## Install `ioctl` Tool

`ioctl` is a tool to create/manage IoTeX address and interact with our mainnet Blockchain. [How to install `ioctl`](https://github.com/iotexproject/iotex-bootstrap#interact-with-blockchain)

After installation, be sure to point to our mainnet secure endpoint `api.iotex.one:443` by running the following in terminal:

```ioctl config set endpoint api.iotex.one:443```

### Import Your Account

**We recommend that you use the ioctl tool to create your IoTeX Rewards/Beneficiary address.** If your IoTeX address is created using the ioctl tool, skip the rest in this subsection. Otherwise, if your IoTeX address is mapped from your ETH address, you need to import the ETH address's private key in order to manage the IoTeX address.

Rest assured that the `ioctl` tool does not store your private key in cleartext, the key is imported in an encrypted format using Ethereum's keystore package and protected by a password set by you. To import your account, run the following command in the terminal:

```ioctl account import my_first_account```

"my_first_account" is a name/alias for the IoTeX address, you can give it other name. After hitting Enter, you will be prompted to enter your private key. Copy your ETH private key (a hex string) and paste it (it won't show up on the screen); hit Enter you will be prompted to Set password. Enter a strong password, hit Enter you will be prompted to re-enter password, enter the same password, hit Enter you will see

```New account #my_first_account is created. Keep your password, or you will lose your private key.```

### Check Your Balance

Run the following command in terminal to query the balance in your address:

```ioctl account balance ${io_address|account_name}```

## Install `bookkeeper` Tool

Bookkeeper is a reward distribution tool provided by IOTEX FOUNDATION to assist calculation of reward tokens for voters. To install, run the following command in terminal:

```curl -Ss https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-bookkeeper.sh | sh```

# Step 1: Claim Reward

All Delegate rewards (block rewards, epoch bonus reward, foundation bonus) will be sent to your Rewards address as “unclaimed rewards”. You must claim these rewards from the blockchain before you can swap/distribute them. The rewards will remain “unclaimed” until you claim them using the following steps.

## Query Your Unclaimed Rewards

Run the following command in terminal to query the unclaimed rewards in your account:

```ioctl node reward ${io_address|name}```

You will find the unclaimed reward amount in IOTX in the output.

## Claim Your Rewards

To claim your reward, run in terminal:

```ioctl action claim ${amount_in_rau} -l 10000 -p 1 -s ${io_address|name}```

If your claim is successful, you will notice an increase of the balance in your account.

# Step 2: Swap to Ethereum ERC20 Token

This service allows our user to seamlessly swap the IoTeX mainnet token to the IoTeX Network ERC20 token (https://etherscan.io/token/0x6fb3e0a217407efff7ca062d46c26e5d60a14d69).

To initiate a swap, simply send a transfer to the lock contract on IoTeX mainnet from your IoTeX address. The service keeps monitoring the lock contract on IoTeX mainnet. Once a transfer into the lock contract is detected, a transfer with the equal amount of ECR20 token less gas fee will be sent to the ETH address associated with your IoTeX address.

Here's the lock contract: **io1pcg2ja9krrhujpazswgz77ss46xgt88afqlk6y**

## Transfer IoTeX native token to lock contract

Run the following command to transfer IoTeX native token to lock contract (amount is the amount you want to swap, addr is the IoTeX address/alias):

```ioctl action invoke io1pcg2ja9krrhujpazswgz77ss46xgt88afqlk6y ${amount} -s ${io_address|name} -l 400000 -p 1 -b d0e30db0```

You will be prompted to enter password, then enter 'yes' to confirm the transfer.

> Note: The lock contract has imposed a minimum transfer amount of 1020 and maximum 1,000,000 tokens. Amount not in this range will automatically be rejected. The contract will charge 20 tokens as gas fee for each transfer, so the minimum/maximum range is to help user make swap in an economical way.

Due to this reason, do not transfer the total balance in the IoTeX address, that will be rejected (because that won't leave enough balance to cover the gas fee). We suggest leave about ~100 tokens in the IoTeX address so you will have enough balance to cover gas fee and use it next time.

Please keep the transaction hash of your transfer for future reference, especially in the rare case that the ERC20 token transfer failed and you request for a re-issue

## Check received ERC20 token
Each IoTeX address is by itself associated with an ETH address, which shares the same private key.

Use the iotcl command line tool to get the ETH address associated with your IoTeX address, for example:

```ioctl account ethaddr io10z0ngrknkund7me7ccj3s0s7u6umtfj7yjrzh3```

```io10z0ngrknkund7me7ccj3s0s7u6umtfj7yjrzh3 - 0x789F340eD3b726df6f3ec625183E1Ee6b9b5a65e```

You can check address **0x789F340eD3b726df6f3ec625183E1Ee6b9b5a65e** on etherscan.io to verify that you have received equal amount of IoTeX Network ERC20 token

# Step 3: Distribution to Voters

You can use the bookkeeper tool to calculate voter's reward. The usage is:

`bookkeeper --bp BP_NAME --start START_EPOCH_NUM --to END_EPOCH_NUM --percentage PERCENTAGE [--with-foundation-bonus] [--endpoint IOTEX_ENDPOINT] [--CONFIG CONFIG_FILE]`

For example, delegate `xyz` wants to distribute 90% of its reward from epoch 24 to epoch 48. To distribute Epoch Reward only:

```
./bookkeeper --bp xyz --start 24 --to 48 --percentage 90
```

To distribute Foundation Bonus in addition to Epoch Reward:

```
./bookkeeper --bp xyz --start 24 --to 48 --percentage 90 --with-foundation-bonus
```

The result will be saved to file `epoch_24_to_48.csv`, with the first column as the voter address, and the second column as the reward in Rau the corresponding voter will get. This csv file will be used in the next step MultiSend tool where the rewards are actually distributed to your voters.

## IoTeX MultiSend Tool
To distribute ECR20 tokens to your voters, go to https://member.iotex.io/multi-send, sign into Metamask, paste the csv file from the above step into "Recipients and Amounts", then click the button "Distribute ERC-20 IOTX", and follow instructions from Metamask.

## Third Party MultiSend Tool
You can also try the third party multi-send tool: https://multisender.app.
