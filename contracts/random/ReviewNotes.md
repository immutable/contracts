Outstanding items from review:

## In RandomSeedProviderRequestQueue.sol: 

Q: I might be misunderstanding something, but the implementation of this contract feels a bit inefficient.
The functions that remove items from the queue seem to do so based on block number (e.g. dequeueBlockNumber()) and not strictly based on their order in the queue? If so, it feels like the implementation can be better optimised for this

A: I will add more information in the contract level comment. This is to prevent an attack: attacker generates random for many block numbers, but doesn't fulfil. If the queue only extracted one block number at a time, then the user would have to read each block number and do an sstore, to store the block hash for that block number, and keep processing until the hit their own block number. At 20,000 gas per sstore, and possibly 250 block numbers to process, that would be 5,000,000 gas that an attacker could force a normal user to have to use.

## In RandomSeedProviderRequestQueue.sol, in enqueueIfUnique: 

Q: would this uniqueness check work if the onChainDelay is updated (reduced) between requests?



## In RandomSeedProviderRequestQueue.sol, in enqueueIfUnique: for tail++

Q: I gather this always leaves outstandingRequests[0] empty? Is there a reason for this?

A: yes, because the initial value of head and tail are zero, and the empty condition is when head == tail

Q: I guess this somewhat departs from typical linear queue implementations, which could cause confusion? My expectation of head==tail, where value of the element is not empty, implies the existence of a single element (which is both the head and the tail of the queue)
