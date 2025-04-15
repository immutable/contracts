# Test Plan for Staking contracts

## [IStakeHolder.sol](../../contracts/staking/IStakeHolder.sol)

[StakeHolderNative.sol](../../contracts/staking/StakeHolderNative.sol) and [StakeHolderERC20.sol](../../contracts/staking/StakeHolderERC20.sol) use common base tests.

Initialize testing (in [StakeHolderInitBase.t.sol](../../contracts/staking/StakeHolderInitBase.t.sol)):

| Test name                       | Description                                                | Happy Case | Implemented |
|---------------------------------|------------------------------------------------------------|------------|-------------|
| testGetVersion                  | Check version number.                                      | Yes        | Yes         |
| testStakersInit                 | Check initial staker's array length is zero.               | Yes        | Yes         |
| testAdmins                      | Check that role and upgrade admin have been set correctly. | Yes        | Yes         |


Configuration tests (in [StakeHolderConfigBase.t.sol](../../contracts/staking/StakeHolderConfigBase.t.sol))::

| Test name                       | Description                                                | Happy Case | Implemented |
|---------------------------------|------------------------------------------------------------|------------|-------------|
| testUpgradeToV1                 | Check upgrade process.                                     | Yes        | Yes         |
| testUpgradeToV0                 | Check upgrade to V0 fails.                                 | No         | Yes         |
| testDowngradeV1ToV0             | Check downgrade from V1 to V0 fails.                       | No         | Yes         |
| testUpgradeAuthFail             | Try upgrade from account that doesn't have upgrade role.   | No         | Yes         |
| testAddRevokeRenounceRoleAdmin  | Check adding, removing, and renouncing role admins.        | Yes        | Yes         |
| testAddRevokeRenounceUpgradeAdmin | Check adding, removing, and renouncing upgrade admins.   | Yes        | Yes         |
| testRoleAdminAuthFail           | Attempt to add an upgrade admin from a non-role admin.     | No         | Yes         |


Operational tests (in [StakeHolderOperationalBase.t.sol](../../contracts/staking/StakeHolderOperationalBase.t.sol))::

| Test name                      | Description                                                 | Happy Case | Implemented |
|--------------------------------|-------------------------------------------------------------|------------|-------------|
| testStake                      | Stake some value.                                           | Yes        | Yes         |
| testStakeTwice                 | Stake some value and then some more value.                  | Yes        | Yes         |
| testStakeZeroValue             | Stake with msg.value = 0.                                   | No         | Yes         |
| testMultipleStakers            | Check multiple entities staking works.                      | Yes        | Yes         |
| testUnstake                    | Check that an account can unstake all their value.          | Yes        | Yes         |
| testUnstakeTooMuch             | Attempt to unstake greater than balance.                    | No         | Yes         |
| testUnstakePartial             | Check that an account can unstake part of their value.      | Yes        | Yes         |
| testUnstakeMultiple            | Unstake in multiple parts.                                  | Yes        | Yes         |
| testUnstakeReentrantAttack     | Attempt a reentrancy attack on unstaking.                   | No         | Yes         |
| testRestaking                  | Stake, unstake, restake.                                    | Yes        | Yes         |
| testGetStakers                 | Check getStakers in various scenarios.                      | Yes        | Yes         |
| testGetStakersOutOfRange       | Check getStakers for out of range request.                  | No         | Yes         |
| testDistributeRewardsOne       | Distribute rewards to one account.                          | Yes        | Yes         |
| testDistributeRewardsMultiple  | Distribute rewards to multiple accounts.                    | Yes        | Yes         |
| testDistributeZeroReward       | Fail when distributing zero reward.                         | No         | Yes         |
| testDistributeMismatch         | Fail if the total to distribute does not equal msg.value.   | No         | Yes         |
| testDistributeToEmptyAccount   | Stake, unstake, distribute rewards.                         | Yes        | Yes         |
| testDistributeToUnusedAccount  | Attempt to distribute rewards to an account that has never staked. | No  | Yes         |
| testDistributeBadAuth  | Attempt to distribute rewards using an unauthorised account.        | No  | Yes         |


