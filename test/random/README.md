# Test Plan for Random Number Generation contracts

## RandomSeedProvider.sol
This section defines tests for contracts/random/RandomSeedProvider.sol. 
All of these tests are in test/random/RandomSeedProvider.t.sol.

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that deployment + initialize work.          | Yes        | Yes         |
| testReinit                      | Calling initialise a second time fails.           | No         | Yes         |
| testGetRandomSeedInitTraditional | getRandomSeed(), initial value, method TRADITIONAL | Yes      | Yes         |
| testGetRandomSeedInitRandao     | getRandomSeed(), initial value, method RANDAO     | Yes        | Yes         |
| testGetRandomSeedNotGenTraditional | getRandomSeed(), when value not generated      | No         | Yes         |
| testGetRandomSeedNotGenRandao   | getRandomSeed(), when value not generated         | No         | Yes         |
| testGetRandomSeedNoOffchainSource | getRandomSeed(), when no offchain source configured | No     | Yes         |

Control functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testRoleAdmin                   | Check DEFAULT_ADMIN_ROLE can assign new roles.    | Yes        | Yes         |
| testRoleAdminBadAuth            | Check auth for create new admins.                 | No         | Yes         |
| testSetOffchainRandomSource     | setOffchainRandomSource().                        | Yes        | Yes         |
| testSetOffchainRandomSourceBadAuth | setOffchainRandomSource() without authorization. | No       | Yes         |
| testSetRanDaoAvailable          | setRanDaoAvailable().                             | Yes        | Yes         |
| testSetRanDaoAvailableBadAuth   | setRanDaoAvailable() without authorization.       | No         | Yes         |
| testAddOffchainRandomConsumer   | addOffchainRandomConsumer().                      | Yes        | Yes         |
| testAddOffchainRandomConsumerBadAuth | addOffchainRandomConsumer() without authorization.| No    | Yes         |
| testRemoveOffchainRandomConsumer| removeOffchainRandomConsumer().                   | Yes        | Yes         |
| testRemoveOffchainRandomConsumerBadAuth | removeOffchainRandomConsumer() without authorization.| No | Yes      |

Operational functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testTradNextBlock               | Check basic request flow                          | Yes        | Yes         |
| testRanDaoNextBlock             | Check basic request flow                          | Yes        | Yes         |
| testOffchainNextBlock           | Check basic request flow                          | Yes        | Yes         |
| testOffchainNotReady            | Attempt to fetch offchain random when not ready   | No         | Yes         |
| testTradTwoInOneBlock           | Two calls to requestRandomSeed in one block       | Yes        | Yes         |
| testRanDaoTwoInOneBlock         | Two calls to requestRandomSeed in one block       | Yes        | Yes         |
| testOffchainTwoInOneBlock       | Two calls to requestRandomSeed in one block       | Yes        | Yes         |
| testTradDelayedFulfillment      | Request then wait several blocks before fulfillment | Yes      | Yes         |
| testRanDaoDelayedFulfillment    | Request then wait several blocks before fulfillment | Yes      | Yes         |

Scenario: Generate some random numbers, switch random generation methodology, generate some more
numbers, check that the numbers generated earlier are still available:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testSwitchTraditionalOffchain   | Traditional -> Off-chain.                         | Yes        | Yes         |
| testSwitchRandaoOffchain        | RanDAO -> Off-chain.                              | Yes        | Yes         |
| testSwitchOffchainOffchain      | Off-chain to another off-chain source.            | Yes        | Yes         |
| testSwitchOffchainTraditional   | Disable off-chain source.                         | Yes        | Yes         |



## ChainlinkSource.sol
This section defines tests for contracts/random/ChainlinkSource.sol. 
All of these tests are in test/random/ChainlinkSource.t.sol.

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
| testBadFulfilment               | Return a set of random numbers rather than one.   | No         | Yes         |
| testRequestTooEarly             | Request before ready.                             | No         | Yes         |

Integration tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testEndToEnd                    | Request a random value from randomValues.         | Yes        | Yes         |


## RandomValues.sol

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that contructor worked.                     | Yes        | Yes         |


Operational tests: 

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testFirstValue                  | Return a single value                             | Yes        | Yes         |
| testSecondValue                 | Return two values                                 | Yes        | Yes         |
| testMultiFetch                  | Fetch a generated number multiple times.          | Yes        | Yes         |
| testMultiInterleaved            | Interleave multiple requests                      | Yes        | Yes         |
| testFirstValues                 | Return a single set of values                     | Yes        | Yes         |
| testSecondValues                | Return two sets of values                         | Yes        | Yes         |
| testMultiFetchValues            | Fetch a generated set of numbers multiple times.  | Yes        | Yes         |
| testMultipleGames               | Multiple games in parallel.                       | Yes        | Yes         |

