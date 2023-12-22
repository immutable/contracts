# Test Plan for Random Number Generation contracts

## RandomSeedProvider.sol
This section defines tests for contracts/random/RandomSeedProvider.sol. 
All of these tests are in test/random/RandomSeedProvider.t.sol.

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that deployment + initialize work.          | Yes        | No          |
| testGetRandomSeedInitTraditional | getRandomSeed(), initial value, method TRADITIONAL | Yes      | No          |
| testGetRandomSeedInitRandao     | getRandomSeed(), initial value, method RANDAO     | Yes        | No          |
| testGetRandomSeedNotGenTraditional | getRandomSeed(), when value not generated      | No         | No          |
| testGetRandomSeedNotGenRandao   | getRandomSeed(), when value not generated         | No         | No          |
| testGetRandomSeedNoOffchainSource | getRandomSeed(), when no offchain source configured | No     | No          |

Control functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testRoleAdmin                   | Check DEFAULT_ADMIN_ROLE can assign new roles.    | Yes        | No          |
| testRoleAdminBadAuth            | Check auth for create new admins.                 | No        | No          |
| testSetOffchainRandomSource     | setOffchainRandomSource().                        | Yes        | No          |
| testSetOffchainRandomSourceBadAuth | setOffchainRandomSource() without authorization. | No       | No          |
| testEnableRanDao                | enableRanDao().                                   | Yes        | No          |
| testEnableRanDaoBadAuth         | enableRanDao() without authorization.             | No         | No          |
| testEnableTraditional           | enableTraditional().                              | Yes        | No          |
| testEnableTraditionalBadAuth    | enableTraditional() without authorization.        | No         | No          |

Operational functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testTradNextBlock               | Check request id is for next block                | Yes        | No          |
| testRanDaoNextBlock             | Check request id is for next block                | Yes        | No          |
| testTradTwoInOneBlock           | Two calls to requestRandomSeed in one block       | Yes        | No          |
| testRanDaoTwoInOneBlock         | Two calls to requestRandomSeed in one block       | Yes        | No          |
| testOffchainTwoInOneBlock       | Two calls to requestRandomSeed in one block       | Yes        | No          |
| testTradDelayedFulfillment      | Request then wait several blocks before fulfillment | Yes        | No          |
| testRanDaoDelayedFulfillment    | Request then wait several blocks before fulfillment | Yes        | No          |
| testOffchainRateLimit           | Check can limit requests to once every N blocks     | Yes        | No          |

Scenario: Generate some random numbers, switch random generation methodology, generate some more
numbers, check that the numbers generated earlier are still available:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testSwitchTraditionalRandao     | Traditional -> RanDAO.                            | Yes        | No          |
| testSwitchTraditionalOffchain   | Traditional -> Off-chain.                         | Yes        | No          |
| testSwitchRandaoOffchain        | RanDAO -> Traditional.                            | Yes        | No          |
| testSwitchRandaoOffchain        | RanDAO -> Off-chain.                              | Yes        | No          |
| testSwitchOffchainTraditional   | Off-chain -> Traditional.                         | Yes        | No          |
| testSwitchOffchainRandao        | Off-chain -> RanDAO                               | Yes        | No          |
| testSwitchOffchainOffchain      | Off-chain to another off-chain source.            | Yes        | No          |



## ChainlinkSource.sol
This section defines tests for contracts/random/ChainlinkSource.sol. 
All of these tests are in test/random/ChainlinkSource.t.sol.

Initialize testing:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that deployment works.                      | Yes        | No          |
| TODO                            | TODO          | Yes      | No          |

Control functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testRoleAdmin                   | Check DEFAULT_ADMIN_ROLE can assign new roles.    | Yes        | No          |
| testRoleAdminBadAuth            | Check auth for create new admins.                 | No        | No          |
| TODO                            | TODO          | Yes      | No          |

Operational functions tests:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| TODO                            | TODO          | Yes      | No          |
