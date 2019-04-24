# 1. Claim reward and voter list

# 2. IoTeX tube service

This service allows our user to seamlessly swap the IoTeX mainnet token to the IoTeX Network ERC20 token (https://etherscan.io/token/0x6fb3e0a217407efff7ca062d46c26e5d60a14d69).

To initiate a swap, simply send a transfer to the lock contract on IoTeX mainnet from your IoTeX address. The service keeps monitoring the lock contract on IoTeX mainnet. Once a transfer into the lock contract is detected, a transfer with the equal amount of ECR20 token less gas fee will be sent to the ETH address associated with your IoTeX address.

Here's the lock contract: **io1pcg2ja9krrhujpazswgz77ss46xgt88afqlk6y**

## 2.1 How to transfer IoTeX native token to lock contract

First, we need to install ioctl command line tool. In the terminal run:

```curl https://raw.githubusercontent.com/iotexproject/iotex-core/master/install-cli.sh | sh```

After installation, make sure you are connected to the correct IoTeX mainnet endpoint. In the terminal run:

```ioctl config set endpoint api.iotex.one:443```

If your IoTeX address is created using the ioctl tool, skip the below and directly go to **Transfer IoTeX native token to lock contract** Otherwise your IoTeX address is mapped from your ETH address, in that case we need to import the ETH address's private key in order to manage the IoTeX address.

Rest assured that the ioctl tool does not store your private key in cleartext, the key is imported in an encrypted format using Ethereum's keystore package and protected by a password set by you. In the terminal run:

```ioctl account import reward```

"reward" is a name/alias for the IoTeX address, you can give it other name. After hitting Enter you will be prompted to Enter your private key. Copy your ETH private key (a hex string) and paste it (it won't show up on the screen), hit Enter you will be prompted to Set password, enter a strong password, hit Enter you will be prompted to Enter password again, enter the same password, hit Enter you will see

```New account #reward is created. Keep your password, or you will lose your private key.```

## 2.2 Transfer IoTeX native token to lock contract

Before starting transfer, you can use the following command to check the balance in your IoTeX address

```ioctl account balance addr```

Now run the following command to transfer IoTeX native token to lock contract (amount is the amount you want to swap, addr is the IoTeX address/alias):

```ioctl action invoke io1pcg2ja9krrhujpazswgz77ss46xgt88afqlk6y amount -s addr -l 400000 -p 1 -b d0e30db0```

You will be prompted to enter password, then enter 'yes' to confirm the transfer.

***Note***
The lock contract has imposed a minimum transfer amount of 1020 and maximum 1,000,000 tokens. Amount not in this range will automatically be rejected. The contract will charge 20 tokens as gas fee for each transfer, so the minimum/maximum range is to help user make swap in an economical way.

Due to this reason, do not transfer the total balance in the IoTeX address, that will be rejected (because that won't leave enough balance to cover the gas fee). We suggest leave about ~100 tokens in the IoTeX address so you will have enough balance to cover gas fee and use it next time.

Please keep the transaction hash of your transfer for future reference, especially in the rare case that the ERC20 token transfer failed and you request for a re-issue

## 2.3 Check received ERC20 token
Each IoTeX address is by itself associated with an ETH address, which shares the same private key.

Use the iotcl command line tool to get the ETH address associated with your IoTeX address, for example:

```ioctl account ethaddr io10z0ngrknkund7me7ccj3s0s7u6umtfj7yjrzh3```

```io10z0ngrknkund7me7ccj3s0s7u6umtfj7yjrzh3 - 0x789F340eD3b726df6f3ec625183E1Ee6b9b5a65e```

You can check address **0x789F340eD3b726df6f3ec625183E1Ee6b9b5a65e** on etherscan.io to verify that you have received equal amount of IoTeX Network ERC20 token

# 3. Multi-send tool

Now you have ERC20 IOTX, and you want to distribute them to multiple addresses? Please goto https://member.iotex.io/multi-send.
