# Stake Holder Threat Model

## Introduction

This threat model document for the [StakeHolderWIMX, StakeHolderERC20 and StakeHolderNative](../../contracts/staking/README.md) contracts has been created in preparation for an internal audit.

## Rationale

Immutable operates a system whereby people can place native IMX in a holding contract, do some actions (which are outside of the scope of this threat model), and then are paid a reward. The people, known as stakers, have full custody of their tokens they place in the holding contract; they can withdraw deposited IMX at any time. Administrators can choose to distribute rewards to stakers at any time.

The StakeHolderERC20 contract can be used for any staking system that uses ERC20 tokens. The StakeHolderNative contract is an alternative implementation that allows native IMX, rather than ERC20 tokens, to be used for staking. The difference between the StakeHolderNative and StakeHolderWIMX is that the StakeHolderWIMX holds the staked value as wrapped IMX (WIMX), an ERC20 contract.


## Threat Model Scope

The threat model is limited to the stake holder Solidity files at GitHash [`bf327c7abdadd48fd51ae632500510ac2b07b5f0`](https://github.com/immutable/contracts/tree/aee3f35d76117a1a22dab96fd6dfd8e92444757b/contracts/staking):

* [IStakeHolder.sol](https://github.com/immutable/contracts/blob/bf327c7abdadd48fd51ae632500510ac2b07b5f0/contracts/staking/IStakeHolder.sol) is the interface that all staking implementations comply with.
* [StakeHolderBase.sol](https://github.com/immutable/contracts/tree/aee3f35d76117a1a22dab96fd6dfd8e92444757b/contracts/staking/StakeHolderBase.sol) is the abstract base contract that all staking implementation use.
* [StakeHolderWIMX.sol](https://github.com/immutable/contracts/tree/aee3f35d76117a1a22dab96fd6dfd8e92444757b/contracts/staking/StakeHolderWIMX.sol) allows the native token, IMX, to be used as the staking currency.
* [StakeHolderERC20.sol](https://github.com/immutable/contracts/tree/aee3f35d76117a1a22dab96fd6dfd8e92444757b/contracts/staking/StakeHolderERC20.sol) allows an ERC20 token to be used as the staking currency.
* [StakeHolderNative.sol](https://github.com/immutable/contracts/tree/aee3f35d76117a1a22dab96fd6dfd8e92444757b/contracts/staking/StakeHolderNative.sol) uses the native token, IMX, to be used as the staking currency.

Additionally, this threat model analyses whether the documentation for the time controller contract correctly advises operators how to achieve the required time delay upgrade functionality:

* [TimelockController.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.9.3/contracts/governance/TimelockController.sol) can be used with the staking contracts to provide a one week delay between when upgrade or other admin changes are proposed and when they are executed. 


## Background

See the [README](https://github.com/immutable/contracts/tree/bf327c7abdadd48fd51ae632500510ac2b07b5f0/contracts/staking/README.md) file for information about the usage and design of the stake holder contract system.

### Other Information

This section provides links to test plans and test code.

#### Test Plans and Test Code

The test plan is available here: [Test Plan](../../test/staking/README.md). The test code is contained in the same directory at the test plan.

#### Continuous Integration

Each time a commit is pushed to a pull request, the [continuous integration loop executes](https://github.com/immutable/contracts/actions).

#### Building, Testing, Coverage and Static Code Analysis

For instructions on building the code, running tests, coverage, and Slither, see the [BUILD.md](https://github.com/immutable/contracts/blob/main/BUILD.md).

## Attack Surfaces

The following sections list attack surfaces evaluated as part of this threat modelling exercise.

### Externally Visible Functions

An attacker could formulate an attack in which they send one or more transactions that execute one or more of the externally visible functions.

The list of functions and their function selectors was determined by the following commands. The additional information was obtained by reviewing the code. `StakeHolderWIMX`, `StakeHolderERC20` and `StakeHolderNative` have identical functions with the exception of the `initialize` function. `StakeHolderWIMX` and `StakeHolderERC20` use the `initialize` function that has four parameters and `StakeHolderNative` uses the `initialize` function with three parameters.

```
forge inspect StakeHolderWIMX methods
forge inspect StakeHolderERC20 methods
forge inspect StakeHolderNative methods
```

Functions that *change* state:

| Name                                    | Function Selector | Access Control      |
| --------------------------------------- | ----------------- | ------------------- |
| `distributeRewards((address,uint256)[])`| 00cfb539          | Permissionless      |
| `grantRole(bytes32,address)`            | 2f2ff15d          | Role admin          |
| `initialize(address,address,address)`   | c0c53b8b          | Can only be called once during deployment |
| `initialize(address,address,address,address)` | f8c8765e  | Can only be called once during deployment |
| `renounceRole(bytes32,address)`         | 36568abe          | `msg.sender`        |
| `revokeRole(bytes32,address)`           | d547741f          | Role admin          |
| `stake(uint256)`                        | a694fc3a          | Operations based on msg.sender |
| `unstake(uint256)`                      | 2e17de78          | Operations based on msg.sender |
| `upgradeStorage(bytes)`                 | ffd0016f          | Can only be called once during upgrade  |
| `upgradeTo(address)`                    | 3659cfe6          | Upgrade role only  |
| `upgradeToAndCall(address,bytes)`       | 4f1ef286          | Upgrade role only  |


Functions that *do not change* state:

| Name                             | Function Selector |
| -------------------------------- | ----------------- |
| `DEFAULT_ADMIN_ROLE()`           | a217fddf          |
| `DISTRIBUTE_ROLE()`              | 7069257d          |
| `UPGRADE_ROLE()`                 | b908afa8          |
| `getBalance(address)`            | f8b2cb4f          |
| `getNumStakers()`                | bc788d46          |
| `getRoleAdmin(bytes32)`          | 248a9ca3          |
| `getRoleMember(bytes32,uint256)` | 9010d07c          |
| `getRoleMemberCount(bytes32)`    | ca15c873          |
| `getStakers(uint256,uint256)`    | ad71bd36          |
| `getToken()`                     | 21df0da7          |
| `hasRole(bytes32,address)`       | 91d14854          |
| `hasStaked(address)`             | c93c8f34          |
| `proxiableUUID()`                | 52d1902d          |
| `supportsInterface(bytes4)`      | 01ffc9a7          |
| `version()`                      | 54fd4d50          |



### Admin Roles

Accounts with administrative privileges could be used by attackers to facilitate attacks. This section analyses what each role can do.

#### Accounts with `DEFAULT_ADMIN_ROLE` on StakeHolderERC20 and StakeHolderNative contracts

The `DEFAULT_ADMIN_ROLE` is the role that is granted to the `roleAdmin` specified in the `initialize` function of the `StakeHolderERC20` and `StakeHolderNative` contracts. Accounts with the `DEFAULT_ADMIN_ROLE` can:

* Grant administrator roles to any account, including the `DEFAULT_ADMIN_ROLE`.
* Revoke administrator roles from any account, including the `DEFAULT_ADMIN_ROLE`.
* Renounce the `DEFAULT_ADMIN_ROLE` for itself.

Exploiting this attack surface requires compromising an account with `DEFAULT_ADMIN_ROLE`.

#### Accounts with `UPGRADE_ROLE` on StakeHolderERC20 and StakeHolderNative contracts

An account with `UPGRADE_ROLE` can:

* Upgrade the implementation contract.
* Renounce the `UPGRADE_ROLE` for itself.

Exploiting this attack surface requires compromising an account with `UPGRADE_ROLE`.

#### Accounts with `DISTRIBUTE_ROLE` on StakeHolderERC20 and StakeHolderNative contracts

An account with `DISTRIBUTE_ROLE` can:

* Call the `distributeRewards` function to distribute rewards.
* Renounce the `DISTRIBUTE_ROLE` for itself.

Exploiting this attack surface requires compromising an account with `DISTRIBUTE_ROLE`.


### Upgrade and Storage Slots

#### Upgrade and Storage Slots for StakeHolderWIMX

The table was constructed by using the command described below, and analysing the source code.

```
forge inspect StakeHolderWIMX storage
```

| Name                              | Type                                                           | Slot | Offset | Bytes | Source File |
| --------------------------------- | -------------------------------------------------------------- | ---- | ------ | ----- | ----------- |
| \_initialized                     | uint8                                                          | 0    | 0      | 1     | OpenZeppelin Contracts v4.9.3: proxy/utils/Initializable.sol |
| \_initializing                    | bool                                                           | 0    | 1      | 1     | OpenZeppelin Contracts v4.9.3: proxy/utils/Initializable.sol |
| \_\_gap                           | uint256[50]                                                    | 1    | 0      | 1600  | OpenZeppelin Contracts v4.9.3: utils/Context.sol            |
| \_\_gap                           | uint256[50]                                                    | 51   | 0      | 1600  | OpenZeppelin Contracts v4.9.3: utils/introspection/ERC165.sol |
| \_roles                           | mapping(bytes32 => struct AccessControlUpgradeable.RoleData)   | 101  | 0      | 32    | OpenZeppelin Contracts v4.9.3: access/AccessControlUpgradeable.sol |
| \_\_gap                           | uint256[49]                                                    | 102  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: access/AccessControlUpgradeable.sol |
| \_roleMembers                     | mapping(bytes32 => struct EnumerableSetUpgradeable.AddressSet) | 151  | 0      | 32    | OpenZeppelin Contracts v4.9.3: access/AccessControlEnumerableUpgradeable.sol |
| \_\_gap                           | uint256[49]                                                    | 152  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: access/AccessControlEnumerableUpgradeable.sol |
| \_\_gap                           | uint256[50]                                                    | 201  | 0      | 1600  | OpenZeppelin Contracts v4.9.3: proxy/ERC1967/ERC1967Upgrade.sol |
| \_\_gap                           | uint256[50]                                                    | 251  | 0      | 1600  | OpenZeppelin Contracts v4.9.3: proxy/utils/UUPSUpgradeable.sol  |
| \_status                         | uint256                                                        | 301  | 0      | 32    | OpenZeppelin Contracts v4.9.3: security/ReentrancyGuardUpgradeable.sol  |
| \_\_gap                           | uint256[49]                                                    | 302  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: security/ReentrancyGuardUpgradeable.sol  |
| balances                          | mapping(address => struct StakeHolder.StakeInfo)               | 351  | 0      | 32    | StakeHolderBase.sol |
| stakers                           | address[]                                                      | 352  | 0      | 32    | StakeHolderBase.sol |
| version                           | uint256                                                        | 353  | 0      | 32    | StakeHolderBase.sol |
| \_\_StakeHolderBaseGap            | uint256[50]                                                    | 354  | 0      | 1600  | StakeHolderBase.sol |
| \_\_StakeHolderNativeGap          | uint256[50]                                                    | 404  | 0      | 1600  | StakeHolderNative.sol |
| wIMX                              | contract IWIMX                                                 | 454  | 0      | 20    | StakeHolderWIMX.sol |
| \_\_StakeHolderWIMXGap            | uint256[50]                                                    | 455  | 0      | 1600  | StakeHolderWIMX.sol |


#### Upgrade and Storage Slots for StakeHolderERC20

The table was constructed by using the command described below, and analysing the source code.

```
forge inspect StakeHolderERC20 storage
```

| Name                              | Type                                                           | Slot | Offset | Bytes | Source File |
| --------------------------------- | -------------------------------------------------------------- | ---- | ------ | ----- | ----------- |
| \_initialized                     | uint8                                                          | 0    | 0      | 1     | OpenZeppelin Contracts v4.9.3: proxy/utils/Initializable.sol |
| \_initializing                    | bool                                                           | 0    | 1      | 1     | OpenZeppelin Contracts v4.9.3: proxy/utils/Initializable.sol |
| \_\_gap                           | uint256[50]                                                    | 1    | 0      | 1600  | OpenZeppelin Contracts v4.9.3: utils/Context.sol            |
| \_\_gap                           | uint256[50]                                                    | 51   | 0      | 1600  | OpenZeppelin Contracts v4.9.3: utils/introspection/ERC165.sol |
| \_roles                           | mapping(bytes32 => struct AccessControlUpgradeable.RoleData)   | 101  | 0      | 32    | OpenZeppelin Contracts v4.9.3: access/AccessControlUpgradeable.sol |
| \_\_gap                           | uint256[49]                                                    | 102  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: access/AccessControlUpgradeable.sol |
| \_roleMembers                     | mapping(bytes32 => struct EnumerableSetUpgradeable.AddressSet) | 151  | 0      | 32    | OpenZeppelin Contracts v4.9.3: access/AccessControlEnumerableUpgradeable.sol |
| \_\_gap                           | uint256[49]                                                    | 152  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: access/AccessControlEnumerableUpgradeable.sol |
| \_\_gap                           | uint256[50]                                                    | 201  | 0      | 1600  | OpenZeppelin Contracts v4.9.3: proxy/ERC1967/ERC1967Upgrade.sol |
| \_\_gap                           | uint256[50]                                                    | 251  | 0      | 1600  | OpenZeppelin Contracts v4.9.3: proxy/utils/UUPSUpgradeable.sol  |
| \_status                         | uint256                                                        | 301  | 0      | 32    | OpenZeppelin Contracts v4.9.3: security/ReentrancyGuardUpgradeable.sol  |
| \_\_gap                           | uint256[49]                                                    | 302  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: security/ReentrancyGuardUpgradeable.sol  |
| balances                          | mapping(address => struct StakeHolder.StakeInfo)               | 351  | 0      | 32    | StakeHolderBase.sol |
| stakers                           | address[]                                                      | 352  | 0      | 32    | StakeHolderBase.sol |
| version                           | uint256                                                        | 353  | 0      | 32    | StakeHolderBase.sol |
| \_\_StakeHolderBaseGap            | uint256[50]                                                    | 354  | 0      | 1600  | StakeHolderBase.sol |
| token                             | contract IERC20Upgradeable                                     | 404  | 0      | 20    | StakeHolderERC20.sol |
| \_\_StakeHolderERC20Gap           | uint256[50]                                                    | 405  | 0      | 1600  | StakeHolderERC20.sol |


#### Upgrade and Storage Slots for StakeHolderNative

The table was constructed by using the command described below, and analysing the source code.

```
forge inspect StakeHolderNative storage
```

| Name                              | Type                                                           | Slot | Offset | Bytes | Source File |
| --------------------------------- | -------------------------------------------------------------- | ---- | ------ | ----- | ----------- |
| \_initialized                     | uint8                                                          | 0    | 0      | 1     | OpenZeppelin Contracts v4.9.3: proxy/utils/Initializable.sol |
| \_initializing                    | bool                                                           | 0    | 1      | 1     | OpenZeppelin Contracts v4.9.3: proxy/utils/Initializable.sol |
| \_\_gap                           | uint256[50]                                                    | 1    | 0      | 1600  | OpenZeppelin Contracts v4.9.3: utils/Context.sol            |
| \_\_gap                           | uint256[50]                                                    | 51   | 0      | 1600  | OpenZeppelin Contracts v4.9.3: utils/introspection/ERC165.sol |
| \_roles                           | mapping(bytes32 => struct AccessControlUpgradeable.RoleData)   | 101  | 0      | 32    | OpenZeppelin Contracts v4.9.3: access/AccessControlUpgradeable.sol |
| \_\_gap                           | uint256[49]                                                    | 102  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: access/AccessControlUpgradeable.sol |
| \_roleMembers                     | mapping(bytes32 => struct EnumerableSetUpgradeable.AddressSet) | 151  | 0      | 32    | OpenZeppelin Contracts v4.9.3: access/AccessControlEnumerableUpgradeable.sol |
| \_\_gap                           | uint256[49]                                                    | 152  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: access/AccessControlEnumerableUpgradeable.sol |
| \_\_gap                           | uint256[50]                                                    | 201  | 0      | 1600  | OpenZeppelin Contracts v4.9.3: proxy/ERC1967/ERC1967Upgrade.sol |
| \_\_gap                           | uint256[50]                                                    | 251  | 0      | 1600  | OpenZeppelin Contracts v4.9.3: proxy/utils/UUPSUpgradeable.sol  |
| \_\status                         | uint256                                                        | 301  | 0      | 32    | OpenZeppelin Contracts v4.9.3: security/ReentrancyGuardUpgradeable.sol  |
| \_\_gap                           | uint256[49]                                                    | 302  | 0      | 1568  | OpenZeppelin Contracts v4.9.3: security/ReentrancyGuardUpgradeable.sol  |
| balances                          | mapping(address => struct StakeHolder.StakeInfo)               | 351  | 0      | 32    | StakeHolderBase.sol |
| stakers                           | address[]                                                      | 352  | 0      | 32    | StakeHolderBase.sol |
| version                           | uint256                                                        | 353  | 0      | 32    | StakeHolderBase.sol |
| \_\_StakeHolderBaseGap            | uint256[50]                                                    | 354  | 0      | 1600  | StakeHolderBase.sol |
| \_\_StakeHolderNativeGap           | uint256[50]                                                    | 404  | 0      | 1600  | StakeHolderNative.sol |


### Timelock Controller Bypass

To ensure time delay upgrades are enforced, the `StakeHolderERC20` or `StakeHolderNative` contracts should have the only account with `UPGRADE_ROLE` and `DEFAULT_ADMIN_ROLE` roles should be an instance of Open Zeppelin's [TimelockController](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/TimelockController.sol). This ensures any upgrade proposals or proposals to add more accounts with `DEFAULT_ADMIN_ROLE`, `UPGRADE_ROLE` or `DISTRIBUTE_ROLE` must go through a time delay before being actioned. The account with `DEFAULT_ADMIN_ROLE` could choose to renounce this role to ensure the `TimelockController` can not be bypassed at a later date by having a compromised account with  `DEFAULT_ADMIN_ROLE` adding additional accounts with `UPGRADE_ROLE`.

Once the `TimelockController` and staking contracts have been installed, the installation should be checked to ensure the configuration of the `TimelockController` is as expected. That is, check:

* The list of `proposer` accounts is what is expected.
* The list of `executor` accounts is what is expected.
* The time delay is the expected value.

## Perceived Attackers

This section lists the attackers that could attack the stake holder contract system.

It is assumed that all attackers have access to all documentation and source code of all systems related to the Immutable zkEVM, irrespective of whether the information resides in a public or private GitHub repository, email, Slack, Confluence, or any other information system.

### Spear Phisher

This attacker compromises accounts of people by using Spear Phishing attacks. For example they send a malicious PDF file to a user, which the user opens, the PDF file then installs malware on the user's computer. At this point, it is assumed that the Spear Phisher Attacker can detect all key strokes, mouse clicks, see all information retrieved, see any file in the user's file system, and execute any program on the user's computer.

### Immutable zkEVM Block Proposer

An operator of an Immutable zkEVM Block Proposer could, within narrow limits, alter the block timestamp of the block they produce. 

### Insider

This attacker works for a company helping operate the Immutable zkEVM. This attacker could be being bribed or blackmailed. They can access the keys that they as an individual employee have access to. For instance, they might be one of the signers of the multi-signer administrative role.

### General Public

This attacker targets the public API of the `StakeHolder` contract.

## Attack Mitigation

This section outlines possible attacks against the attack surfaces by the attackers, and how those attacks are mitigated.

### Public API Attack

**Detection**: Staker funds are stolen.

An attacker could target the public API in an attempt to steal funds. As shown in the `Externally Visible Functions` section, all functions that update state are protected by access control methods (`grantRole`, `revokeRole`, `upgradeTo`, `upgradeToAndCall`), operate on value owned by msg.sender (`distributeRewards`, `stake`, `unstake`), operate on state related to msg.sender (`renounceRole`), or are protected by state machine logic (`initialize`, `upgradeStorage`). As such, there is no mechanism by which an attacker could attack the contract using the public API.


### `DEFAULT_ADMIN` Role Account Compromise

**Detection**: Monitoring role change events.

The mitigation is to assume that the role will be operated by multi-signature addresses such that an attacker would need to compromise multiple signers simultaneously. As such, even if some keys are compromised due to the Spear Phishing Attacker or the Insider Attacker, the administrative actions will not be able to be executed as a threshold number of keys will not be available.

### `UPGRADE` Role Account Compromise

**Detection**: Monitoring upgrade events.

The mitigation is to assume that the role will be operated by multi-signature addresses such that an attacker would need to compromise multiple signers simultaneously. As such, even if some keys are compromised due to the Spear Phishing Attacker or the Insider Attacker, the administrative actions will not be able to be executed as a threshold number of keys will not be available.

### Immutable zkEVM Block Proposer Censoring Transactions

**Detection**: A staker could attempt to unstake some or all of their IMX. The block proposer could refuse to include this transaction. 

The mitigation for this attack is that Immutable zkEVM Block Proposers software is written such that no transactions are censored unless the transaction has been signed by an account on [OFAC's Sanctions List](https://ofac.treasury.gov/sanctions-list-service).


## Conclusion

This threat model has presented the architecture of the system, determined attack surfaces, and identified possible attackers and their capabilities. It has walked through each attack surface and based on the attackers, determined how the attacks are mitigated.
