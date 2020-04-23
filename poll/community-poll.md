## Start self-serving community poll on IoTeX blockchain

We have deployed a registration contract [io17nq7vnm3wcs5a2cmhwhcnhwtwv4s6lxuv7qqj5](https://iotexscan.io/address/io17nq7vnm3wcs5a2cmhwhcnhwtwv4s6lxuv7qqj5) that allows you to quickly start a community poll.

Follow the steps in this guide to create your poll.

## Drafe the poll and publish in IoTeX forum

1. Draft the poll with your favorite text editor.

2. Post a forum thread under “Ecosystem” and tag it with “delegates” and “governance”, entitled it with “[Community Poll] a great enhancement - Proposal #X”. See this [example](https://community.iotex.io/t/community-poll-self-staking-bonus-and-extend-unstaking-period-proposal-5/724)

3. Paste the content to https://emn178.github.io/online-tools/keccak_256.html and generate a keccak-256 hash. **This hash would be the unique ID for the poll's content**. Post the content hash back to the forum thread.

## Register the poll on IoTeX blockchain

1. Go to https://abi.hashex.org/ paste the poll registration contract ABI from https://github.com/iotexproject/iotex-bootstrap/blob/master/poll/poll.abi, click Parse

2. Select function register() from the “Function type” drop-down, and fill in the parameter.

3. bytecode will be generated in the text box at the bottom, click Copy

4. Register the poll, by running the following command: (paste the bytecode after -b)

`ioctl action invoke io17nq7vnm3wcs5a2cmhwhcnhwtwv4s6lxuv7qqj5 -s {YOUR_ADDRESS} -l 3000000 --endpoint api.iotex.one:443 -b bytecode`

you will see output like below:
```
Action has been sent to blockchain.
Wait for several seconds and query this action by hash:284b40c21ef3cd9a3f2fd833800a8e806650ebda98a94dc31f51bb6997202d15
```

## Update the poll hash in IoTeX forum

1. Post the tx hash returned above to the forum thread. **This tx hash would be the unique ID for the poll's registration on the blockchain**. 

2. Fill out the following JSON blob and post it to the same forum thread and @tian who will populate frontend using this blob. Replace **TODO** with the actual content/option of your poll.

`{
   "status": 1,
   "contractAddress": "TODO: YOUR CONTRACT ADDRESS",
   "title": "TODO: your proposal's title",
   "description": "TODO: your proposal's content in plain text or HTML",
   "start": "TODO: start date with timezone",
   "end": "TODO: end date with timezone",
   "proposer": "TODO: your name",
   "category": "General",
   "maxNumOfChoices": 2, // TODO: max number of choices
   "options": [{"id": "1", "description": "TODO"}, {"id": "2", "description": "TODO"}],
   "id": 5, //TODO: your proposal ID
 }`
 
 ## Publish the poll in IoTeX member portal
 
 Give it 24 hour, the poll will show up on https://member.iotex.io/polls, hooray!