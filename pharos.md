# pharos
Gateway server bridging REST and gRPC

Pharos is an HTTP endpoint for developer and 3rd-party integrator to access address and transaction data on IoTeX blockchain

## APIs
Currently Pharos has the following 3 APIs:

1. get an address

GET: https://pharos.iotex.io/v1/accounts/io1e2nqsyt7fkpzs5x7zf2uk0jj72teu5n6aku3tr

Response is a JSON blob like below:
> `{"accountMeta":{"address":"io1e2nqsyt7fkpzs5x7zf2uk0jj72teu5n6aku3tr","balance":"8804142945000000000000","nonce":"18","pendingNonce":"19","numActions":"35"}}`

2. get a transaction by hash

GET: https://pharos.iotex.io/v1/actions/hash/53e729d28b0c69fc66c4317fdc6ee7af292980ce781b56b502e2ee2e0b9ca48a

Response is a JSON blob like below:
> `{"total":"1","actionInfo":[{"action":{"core":{"version":1,"nonce":"1","gasLimit":"20000","gasPrice":"1000000000000","transfer":{"amount":"1000000000000000","recipient":"io1e2nqsyt7fkpzs5x7zf2uk0jj72teu5n6aku3tr"}},"senderPubKey":"BLhgbOGdny7iNzyHe9axp5KWTb8sMJzad78+bc5cTYRAUqVNF6igy5t9z2jqM2Zneiw17d6xSgbokcDnVRxmuM8=","signature":"awRLFCvU4X5SVyz2IDU5rdjmKjUk3BOchmt/3bmvgi9GJJW3pat4I0i/qqROowPbVJ8nj+eZNQ5Okhgt6ezPgAE="},"actHash":"53e729d28b0c69fc66c4317fdc6ee7af292980ce781b56b502e2ee2e0b9ca48a","blkHash":"33e1d2858cec24059f22348b862a2f415a21bb14b7d96733249a12e96c542969","blkHeight":"222656","sender":"io1e2nqsyt7fkpzs5x7zf2uk0jj72teu5n6aku3tr","gasFee":"10000000000000000","timestamp":"2019-05-17T23:26:20Z"}]}`

3. get a list of transactions of an address

GET: https://pharos.iotex.io/v1/actions/addr/io1e2nqsyt7fkpzs5x7zf2uk0jj72teu5n6aku3tr?count=1&start=9

Note: the first API returns `numActions:` the total number of actions of an address. Here the params in HTTP request body need to satisfy `start + count <= numActions`

Response is a JSON blob like below:
> `{"total":"35","actionInfo":[{"action":{"core":{"version":1,"nonce":"10","gasLimit":"10000","gasPrice":"1000000000000","transfer":{"amount":"466555000000000000","recipient":"io1j0d0lvx7493426zfdk43fdt6wmnp502p96m9c0"}},"senderPubKey":"BLhgbOGdny7iNzyHe9axp5KWTb8sMJzad78+bc5cTYRAUqVNF6igy5t9z2jqM2Zneiw17d6xSgbokcDnVRxmuM8=","signature":"pJoeZx7UnrqFngxm91q6EtP7WlBznHCkKQg4zlFYTxUtUbIkH5mbps2ZU8eQ/MXRjarwzOLorC1el5P/pT3t8gA="},"actHash":"211b56cc9ae0e35a59bd71d8d888d1eba48183340478e8c23908bb2cd7921449","blkHash":"9da5c800137c25b7b6b9f5cd745afa37a183526c5f7f5867705fda32ce052afd","blkHeight":"251783","sender":"io1e2nqsyt7fkpzs5x7zf2uk0jj72teu5n6aku3tr","gasFee":"10000000000000000","timestamp":"2019-05-21T08:24:30Z"}]}`

## Send transfer to IoTeX blockchain
Please click [here](https://github.com/iotexproject/iotex-proto/) and refer to the example at the end of readme.

