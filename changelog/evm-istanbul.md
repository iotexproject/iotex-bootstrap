# EVM Istanbul upgrade

Starting v1.3 the IoTeX blockchain supports EVM Istanbul, which brings upgrades
that improve denial-of-service attack resilience, and adjust gas costs for EVM
storage and zk-SNARKs and zk-STARKs, allowing privacy applications based on
SNARK and STARK to scale at a cheaper cost.

Here's the list of EIP adopted in the Istanbul upgrade:

- [EIP-152](https://eips.ethereum.org/EIPS/eip-152) -- precompiled Blake2b to
facilitate Zcash
- [EIP-1108](https://eips.ethereum.org/EIPS/eip-1108) -- better bn256 library
for faster EC computation and reduced gas cost
- [EIP-1344](https://eips.ethereum.org/EIPS/eip-1344) -- adds the CHAINID opcode
to return current chain's EIP-155 unique identifier inside smart contract
- [EIP-1884](https://eips.ethereum.org/EIPS/eip-1884) -- repricing for trie-size
-dependent opcodes
- [EIP-2028](https://eips.ethereum.org/EIPS/eip-2028) -- transaction data gas cost
reduction
- [EIP-2200](https://eips.ethereum.org/EIPS/eip-2200) -- cost reduction of storage
in the EVM

## Gas cost change
Here's a summary of gas cost change as a result of these EIPs

| Precompiled contract | Address | Current gas cost | Updated gas cost |
| --- | --- | --- | --- |
| ECADD | 0x06 | 500 | 150 |
| ECMUL | 0x07 | 40000 | 6000 |
| Pairing check | 0x08 | 80000*k* + 100000 | 34000*k* + 45000 |

*k* is the number of pairings being computed

| Opcode | Address | Current gas cost | Updated gas cost |
| --- | --- | --- | --- |
| SLOAD | 0x54 | 200 | 800 |
| BALANCE | 0x31 | 400 | 700 |
| EXTCODEHASH | 0x3F | 400 | 700 |
| SELFBALANCE | 0x47 | n/a | 5 |
| Calldata | n/a | 68 per byte | 16 per byte |

