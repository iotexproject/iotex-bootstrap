You can interact with our mainnet smart contract `io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5` to swap native token to ERC20 token. The abi of this contract is available [here](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/n2e.abi)

The swap can be done either by the `ioctl` commaindline tool or on our [web portal](https://member.iotex.io/tools/iotex).

##  Swap to same address

Usually if you use our [web portal](https://member.iotex.io/tools/iotex) (which prompts you to sign into Metamask), or our [web wallet](https://iotexscan.io/wallet), you may want to receive IOTX ERC20 token in the same address.

Here's the commandline:

`ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 ${amount} -s ${io_address|account_name} -l 400000 -p 1 -b d0e30db0`

The `amount` in the command should be equal to the amount you want to swap plus a fee (20 IOTX). For example, if you want to swap 30000 IOTX from you account `my_primary_account`, run the following command in terminal:

`ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 30020 -s my_primary_account -l 400000 -p 1 -b d0e30db0`

In our [web portal](https://member.iotex.io/tools/iotex), click the `Current ETH address:` radio button (it is the default case).

> OR, you can program to call the contract's `deposit` method with the same amount, gas limit, and gas price setting as that in commandline. 

##  Swap to different address

If you use wallet app on mobile phone and wish to receive IOTX ERC20 token in the same wallet, you will need to get the ETH address of your IoTeX ERC20 token in your wallet.

Below is the example of swap 30000 IOTX native token to ETH address *0xac1ec44e4f0ca7d172b7803f6836de87fb72b309*

> Important: replace *ac1ec44e4f0ca7d172b7803f6836de87fb72b309* with your ETH address, remove '0x' in front of ETH address, keep `b760faf9000000000000000000000000` intact

`ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 30020 -s my_primary_account -l 400000 -p 1 -b b760faf9000000000000000000000000ac1ec44e4f0ca7d172b7803f6836de87fb72b309` 

In our [web portal](https://member.iotex.io/tools/iotex), click the `Another ETH address` radio button and enter the receiving ETH address.

> OR, you can program to call the contract's `depositTo` method with the same amount, address, gas limit, and gas price setting as that in commandline.

##  Verify receiving of IOTX ERC20 token

The swap should take effect in about 2 minutes. You can check the ETH address on https://etherscan.io to verify you have received the IoTeX ERC20 tokens.
