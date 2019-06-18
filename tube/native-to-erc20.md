##  Swap to same address

Usually if you use Metamask, or our [web wallet](https://iotexscan.io/wallet), you may want to receive IOTX ERC20 token in the same address.

In this case, use the `ioctl` commandline tool to transfer to contract *io1pcg2ja9krrhujpazswgz77ss46xgt88afqlk6y*. The abi of this contract is available [here](https://github.com/iotexproject/iotex-bootstrap/blob/master/native-to-erc20.abi)

`ioctl action invoke io1pcg2ja9krrhujpazswgz77ss46xgt88afqlk6y ${amount} -s ${io_address|account_name} -l 400000 -p 1 -b d0e30db0`

The `amount` in the command should be equal to the amount you want to swap plus a fee (20 IOTX). For example, if you want to swap 30000 IOTX from you account `my_primary_account`, run the following command in terminal:

`ioctl action invoke io1pcg2ja9krrhujpazswgz77ss46xgt88afqlk6y 30020 -s my_primary_account -l 400000 -p 1 -b d0e30db0`

> OR, you can program to call the contract's `deposit` method with the same amount, gas limit, and gas price setting as that in commandline. 

##  Swap to different address

If you use wallet app on mobile phone and wish to receive IOTX ERC20 token in the same wallet, you will need to get the ETH address of your IoTeX ERC20 token in your wallet.

In this case, use the `ioctl` commandline tool to transfer to contract *io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5*. The abi of this contract is available [here](https://github.com/iotexproject/iotex-bootstrap/blob/master/tube/n2e.abi)

Below is the example of swap 30000 IOTX native token to ETH address *0xac1ec44e4f0ca7d172b7803f6836de87fb72b309*

> Important: replace *ac1ec44e4f0ca7d172b7803f6836de87fb72b309* with your ETH address, remove '0x' in front of ETH address, keep `b760faf9000000000000000000000000` intact

`ioctl action invoke io1p99pprm79rftj4r6kenfjcp8jkp6zc6mytuah5 30020 -s my_primary_account -l 400000 -p 1 -b b760faf9000000000000000000000000ac1ec44e4f0ca7d172b7803f6836de87fb72b309` 

> OR, you can program to call the contract's `depositTo` method with the same amount, address, gas limit, and gas price setting as that in commandline.

##  Verify receiving of IOTX ERC20 token

The swap should take effect in about 2 minutes. You can check the ETH address on https://etherscan.io to verify you have received the IoTeX ERC20 tokens.
