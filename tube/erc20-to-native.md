##  The swap contract

We have deployed a swap contract [0x450caB2535D57cE9df625297D796aee266611728](https://etherscan.io/address/0x450caB2535D57cE9df625297D796aee266611728) on Ethereum. The abi of this contract is available [here](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/e2n.abi)

We recommend that you use our [web portal](https://member.iotex.io/tools/iotex) to do the swap.

##  Swap to same address

Usually if you use our [web portal](https://member.iotex.io/tools/iotex) (which prompts you to sign into Metamask), or our [web wallet](https://iotexscan.io/wallet), you may want to receive IOTX token in the same address. In this case, just use the ETH address in Metamask or web wallet as receiving address.

In our [web portal](https://member.iotex.io/tools/iotex), click the `Current IO address:` radio button (it is the default case). This calls the contract's `deposit` method with `_amount = amount you want to swap`.

Make sure you have enough amount of IoTeX ERC20 token and Ether (to cover transaction fee on Ethereum) in your sending address.

##  Swap to different address

If you use wallet app on mobile phone and wish to receive IOTX native token in the same wallet, you will need to use `ioctl` commandline tool to get the ETH address from the IoTeX native token address, and convert to IoTeX address, as introduced in [tube](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/tube.md).

In our [web portal](https://member.iotex.io/tools/iotex), click the `Another IO address` radio button and enter the receiving IoTeX address. This calls the contract's `depositTo` method with `_amount = amount you want to swap`, and `_to = receiving address`.

Make sure you have enough amount of IoTeX ERC20 token and Ether (to cover transaction fee on Ethereum) in your sending address.

##  Verify receiving of IOTX native token

The swap should take effect in about 2 minutes. You can check the IOTX native token in the receiving IoTeX address (use *io14s0vgnj0pjnazu4hsqlksdk7slah9vcfscn9ks* as example):

`ioctl account balance io14s0vgnj0pjnazu4hsqlksdk7slah9vcfscn9ks`