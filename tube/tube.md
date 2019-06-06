# tube
Tube is a bi-directional service that allows our users to swap the IoTeX mainnet native token to the [IoTeX Network ERC20 token](https://etherscan.io/token/0x6fb3e0a217407efff7ca062d46c26e5d60a14d69), or vice versa.

Basically you send certain amount of token (ERC20 or native) to a special smart contract, and you'll receive the other type of token in equal amount.

## Getting started
Before using the service let's first introduce some basic facts of the IoTeX address. 

An IoTeX address is inherently associated with an underlying ETH address. You can use our `ioctl` commandline tool to check the associated ETH address of an IoTeX address, or vice versa. If you are a first-time user of IoTeX, refer to [How to install ioctl](https://github.com/iotexproject/iotex-bootstrap#interact-with-blockchain)

`ioctl account ethaddr io14s0vgnj0pjnazu4hsqlksdk7slah9vcfscn9ks`

it shows that that underlying ETH address is *0xAc1ec44E4f0ca7D172B7803f6836De87Fb72b309*

`io14s0vgnj0pjnazu4hsqlksdk7slah9vcfscn9ks - 0xAc1ec44E4f0ca7D172B7803f6836De87Fb72b309`

Or use the ETH address as input:

`ioctl account ethaddr 0xAc1ec44E4f0ca7D172B7803f6836De87Fb72b309`

You will see the same output showing the mapping of these 2 addresses.

These 2 addresses are an alias to each other. They share the **same private key**, this same private key gives you full access/control of the IOTX ERC20 and native token on these 2 addresses.

When you swap token using Metamask, or our [web wallet](https://iotexscan.io/wallet), you are operating the same private key so everything is fine.

Now here's the **caveat:** in most wallet software when you generate address from the seed phrase, the address of the IOTX native token is *NOT* same as the IoTeX ERC20 token, i.e., there are *2 different private keys* behind these 2! 

In other words, when you swap tokens in your wallet and expect to receive the other type of token in the same wallet, you will need to **specify a correct receiving address**.

> Knowing this distinction is extremely important for correctly operating your swap and prevent loss of token!

## [Swap ERC20 to native](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/erc20-to-native.md)

## [Swap native to ERC20](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/native-to-erc20.md)
 


