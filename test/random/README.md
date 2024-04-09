# Test Plan for Random Number Generation contracts

## RandomSeedProvider.sol
This section defines tests for contracts/random/RandomSeedProvider.sol. 
All of these tests are in test/random/RandomSeedProvider.t.sol.

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that deployment + initialize work.          | Yes        | Yes         |
| testReinit                      | Calling initialise a second time fails.           | No         | Yes         |
| testGetRandomSeedInit           | fulfilRandomSeedRequest(), initial value                    | Yes        | Yes         |
| testGetRandomSeedNotGen         | fulfilRandomSeedRequest(), when value not generated         | No         | Yes         |
| testGetRandomSeedNoOffchainSource | fulfilRandomSeedRequest(), when no offchain source configured | No     | Yes         |

Control functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testRoleAdmin                   | Check DEFAULT_ADMIN_ROLE can assign new roles.    | Yes        | Yes         |
| testRoleAdminBadAuth            | Check auth for create new admins.                 | No         | Yes         |
| testSetOffchainRandomSource     | setOffchainRandomSource().                        | Yes        | Yes         |
| testSetOffchainRandomSourceBadAuth | setOffchainRandomSource() without authorization. | No       | Yes         |
| testAddOffchainRandomConsumer   | addOffchainRandomConsumer().                      | Yes        | Yes         |
| testAddOffchainRandomConsumerBadAuth | addOffchainRandomConsumer() without authorization.| No    | Yes         |
| testRemoveOffchainRandomConsumer| removeOffchainRandomConsumer().                   | Yes        | Yes         |
| testRemoveOffchainRandomConsumerBadAuth | removeOffchainRandomConsumer() without authorization.| No | Yes      |
| testUpgrade                     | Check that the contract can be upgraded.          | Yes        | Yes         |
| testUpgradeBadAuth              | Check upgrade authorisation.                      | No         | Yes         |
| testNoUpgrade                   | Upgrade from V0 to V0.                            | No         | Yes         |
| testSetOnchainDelay             | Change the onchain delay.                         | Yes        | Yes         |
| testSetOnchainDelayBadAuth      | Change the onchain delay, without authorisation.  | Yes        | Yes         |
| testSetOnchainDelayInvalid      | Change the onchain delay to an invalid value.     | Yes        | Yes         |

Operational functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testOnchainNextBlock            | Check basic request flow                          | Yes        | Yes         |
| testOffchainNextBlock           | Check basic request flow                          | Yes        | Yes         |
| testOffchainNotReady            | Attempt to fetch offchain random when not ready   | No         | Yes         |
| testOnchainTwoInOneBlock        | Two calls to requestRandomSeed in one block       | Yes        | Yes         |
| testOffchainTwoInOneBlock       | Two calls to requestRandomSeed in one block       | Yes        | Yes         |
| testOnchainDelayedFulfillment   | Request then wait several blocks before fulfillment | Yes      | Yes         |
| testStreamedSeedValues          | Request seeds each block.                         | Yes        | Yes         |
| testBlock256Plus                | Check the operation with block number > 255       | Yes        | Yes         |
| testMissedSeed                  | Don't generate the random in time                 | No         | Yes         |
| testGenerateNextSeedOnChain     | Use generateNextSeedOnChain to fulfill requests    | Yes       | Yes         |
| testGenerateNextSeedOnChainLate | generateNextSeedOnChain too late for a request    | Yes        | Yes         |

Scenario: Generate some random numbers, switch random generation methodology, generate some more
numbers, check that the numbers generated earlier are still available:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testSwitchOnchainOffchain       | On-chain -> Off-chain.                            | Yes        | Yes         |
| testSwitchOffchainOffchain      | Off-chain to another off-chain source.            | Yes        | Yes         |
| testSwitchOffchainOnchain       | Disable off-chain source.                         | Yes        | Yes         |


## RandomSeedProviderRequestQueue.sol

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Empty queue.                                      | Yes        | Yes         |
| testEnqueue                     | Enqueue one value.                                | Yes        | Yes         |
| testEnqueueSame                 | Check enqueuing the same value.                   | Yes        | Yes         |
| testDequeueBlockNumberOnly      | Dequeue by block number: one entry in queue       | Yes        | Yes         |
| testDequeueBlockNumberFirst     | Dequeue by block number: dequeue value at head.   | Yes        | Yes         |
| testDequeueBlockNumberLast      | Dequeue by block number: dequeue value at tail.   | Yes        | Yes         |
| testDequeueBlockNumberMiddle    | Dequeue by block number: dequeue middle of queue. | Yes        | Yes         |
| testDequeueBlockNumberMultipleToFirst | Dequeue from middle, and then head.         | Yes        | Yes         |
| testDequeueBlockNumberMultipleToLast | Dequeue from middle, and then tail.          | Yes        | Yes         |
| testDequeueHistoricBlockNumbersNoHistoricBlocks | Dequeue historic blocks when there are no historic blocks. | No | Yes |
| testDequeueHistoricBlockNumbersOneBlock | Dequeue historic blocks when there is one historic block. | Yes | Yes |
| testDequeueHistoricBlockNumbersMultipleBlocks | As above with multiple blocks.      | Yes        | Yes         |
| testDequeueHistoricBlockNumbersWithHoles | Check interaction of dequeue by block number and historic blocks. | Yes | Yes |


## RandomValues.sol

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that contructor worked.                     | Yes        | Yes         |


Operational tests: 

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testNoValue                     | Request zero bytes be returned                    | No         | Yes         |
| testFirstValue                  | Return a single value                             | Yes        | Yes         |
| testSecondValue                 | Return two values                                 | Yes        | Yes         |
| testMultiFetch                  | Attempt to fetch a generated number twice.        | Yes        | Yes         |
| testFirstValues                 | Return a single set of values                     | Yes        | Yes         |
| testSecondValues                | Return two sets of values                         | Yes        | Yes         |
| testMultipleGames               | Multiple games in parallel.                       | Yes        | Yes         |
| testTooLate                     | Handle auto seed failure                          | No         | Yes         |


## RandomSequences.sol

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that contructor worked.                     | Yes        | Yes         |


Operational tests for getNextRandom: 

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testGetInvalidSequenceTypeId    | Attempt to use an invalid sequence type id        | No         | Yes         |
| testGetNoExistingRequest        | When no previous call (no request)                | Yes        | Yes         |
| testGetInProgress               | When random generation is in progress.            | Yes        | Yes         |
| testGetAlreadyFetched           | Random value is being mistakenly re-used.         | No         | Yes         |
| testGetRandom                   | Generate a random value.                          | Yes        | Yes         |
| testGetRandomMultiple           | Generate a sequence of random values.             | Yes        | Yes         |
| testGetRandomMultipleSequences  | Generate multiple sequences.                      | Yes        | Yes         |
| testGetRandomMultiplePlayers    | Generate multiple sequences for multiple players. | Yes        | Yes         |
| testMissedFulfillment           | Auto seed fulfillment failure, auto re-request.   | No         | Yes         |


Operational tests for randomStatus: 

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testStatusInvalidSequenceTypeId | Attempt to use an invalid sequence type id        | No         | Yes         |
| testStatusNoExistingRequest     | When no previous call (no request)                | Yes        | Yes         |
| testStatusInProgress            | When random generation is in progress.            | Yes        | Yes         |
| testStatusAlreadyFetched        | Random value is being mistakenly re-used.         | No         | Yes         |
| testStatusReady                 | Generate a random value.                          | Yes        | Yes         |
| testStatusRetry                 | Handle auto seed fulfillment failure              | No         | Yes         |


## ChainlinkSource.sol
This section defines tests for contracts/random/offchainsources/chainlink/ChainlinkSource.sol. 
All of these tests are in test/random/offchainsources/chainlink/ChainlinkSource.t.sol.

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that deployment and initialisation works.   | Yes        | Yes         |

Control functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testRoleAdmin                   | Check DEFAULT_ADMIN_ROLE can assign new roles.    | Yes        | Yes         |
| testRoleAdminBadAuth            | Check auth for create new admins.                 | No         | Yes         |
| testConfigureRequests           | Check configureRequests can be called.            | Yes        | Yes         |
| testConfigureRequestsBadAuth    | Check configureRequests fails with bad auth.      | No         | Yes         |


Operational functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testRequestRandom               | Request a random value.                           | Yes        | Yes         |
| testTwoRequests                 | Check that two requests return different values.  | Yes        | Yes         |
| testBadFulfillment              | Return a set of random numbers rather than one.   | No         | Yes         |
| testRequestTooEarly             | Request before ready.                             | No         | Yes         |
| testHackFulfillment             | Attempt to maliciously fulfil from other address. | No         | Yes         |
| testRequestBadAuth              | Request but not random seed provider.             | No         | Yes         |

Integration tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testEndToEnd                    | Request a random value from randomValues.         | Yes        | Yes         |



## SupraSource.sol
This section defines tests for contracts/random/offchainsources/supra/SupraSource.sol. 
All of these tests are in test/random/offchainsources/supra/SupraSource.t.sol.

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that deployment and initialisation works.   | Yes        | Yes         |

Control functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testRoleAdmin                   | Check DEFAULT_ADMIN_ROLE can assign new roles.    | Yes        | Yes         |
| testRoleAdminBadAuth            | Check auth for create new admins.                 | No         | Yes         |
| testSetSubcription              | Check setSubscription can be called.              | Yes        | Yes         |
| testSetSubscriptionBadAuth      | Check setSubscription fails with bad auth.        | No         | Yes         |


Operational functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testRequestRandom               | Request a random value.                           | Yes        | Yes         |
| testTwoRequests                 | Check that two requests return different values.  | Yes        | Yes         |
| testBadFulfillment              | Return a set of random numbers rather than one.   | No         | Yes         |
| testRequestTooEarly             | Request before ready.                             | No         | Yes         |
| testHackFulfillment             | Attempt to maliciously fulfil from other address. | No         | Yes         |
| testRequestBadAuth              | Request but not random seed provider.             | No         | Yes         |


Integration tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testEndToEnd                    | Request a random value from randomValues.         | Yes        | Yes         |

