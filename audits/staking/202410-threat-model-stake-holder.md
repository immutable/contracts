# Stake Holder Threat Model

## Introduction

This threat model document for the [Stake Holder](../../contracts/staking/README.md) contract has been created in preparation for external audit.

## Rationale

Immutable operates a system whereby people can place native IMX in a holding contract, do some actions (which are outside of the scope of this threat model), and then are paid a reward. The people, known as stakers, have full custody of their tokens they place in the holding contract; they can withdraw deposited IMX at any time. Anyone can choose to distribute rewards to stakers at any time.

## Threat Model Scope

The threat model is limited to the following Solidity file at GitHash [`fd982abc49884af41e05f18349b13edc9eefbc1e`](https://github.com/immutable/contracts/blob/fd982abc49884af41e05f18349b13edc9eefbc1e/contracts/staking/README.md):

* [StakeHolder.sol](https://github.com/immutable/contracts/blob/fd982abc49884af41e05f18349b13edc9eefbc1e/contracts/staking/StakeHolder.sol)

## Background

See the [README](https://github.com/immutable/contracts/blob/fd982abc49884af41e05f18349b13edc9eefbc1e/contracts/staking/README.md) file for information about the usage and design of the `StakeHolder` contract.

### Other Information

This section provides links to test plans and test code.

#### Test Plans and Test Code

The test plan is available here: [Test Plan](../test/staking/README.md). The test code is contained in the same directory at the test plan.

#### Continuous Integration

Each time a commit is pushed to a pull request, the [continuous integration loop executes](https://github.com/immutable/contracts/actions).

#### Building, Testing, Coverage and Static Code Analysis

For instructions on building the code, running tests, coverage, and Slither, see the [BUILD.md](https://github.com/immutable/contracts/blob/main/BUILD.md).

## Attack Surfaces

The following sections list attack surfaces evaluated as part of this threat modelling exercise.

### Externally Visible Functions

An attacker could formulate an attack in which they send one or more transactions that execute one or more of the externally visible functions.

The list of functions and their function selectors was determined by the following command. The additional information was obtained by reviewing the code.

```
forge inspect StakeHolder --pretty methods
```

Functions that *change* state:

| Name                                    | Function Selector | Access Control      |
| --------------------------------------- | ----------------- | ------------------- |
| `distributeRewards((address,uint256)[])`| 00cfb539          | Permissionless      |
| `grantRole(bytes32,address)`            | 2f2ff15d          | Role admin          |
| `initialize(address,address)`           | 485cc955          | Can only be called once during deployment |
| `renounceRole(bytes32,address)`         | 36568abe          | `msg.sender`        |
| `revokeRole(bytes32,address)`           | d547741f          | Role admin          |
| `stake()`                               | 3a4b66f1          | Operations based on msg.sender |
| `unstake(uint256)`                      | 2e17de78          | Operations based on msg.sender |
| `upgradeStorage(bytes)`                 | ffd0016f          | Can only be called once during upgrade  |
| `upgradeTo(address)`                    | 3659cfe6          | Upgrade role only  |
| `upgradeToAndCall(address,bytes)`       | 4f1ef286          | Upgrade role only  |


Functions that *do not change* state:

| Name                             | Function Selector |
| -------------------------------- | ----------------- |
| `DEFAULT_ADMIN_ROLE()`           | a217fddf          |
| `UPGRADE_ROLE()`                 | b908afa8          |
| `getBalance(address)`            | f8b2cb4f          |
| `getNumStakers()`                | bc788d46          |
| `getRoleAdmin(bytes32)`          | 248a9ca3          |
| `getRoleMember(bytes32,uint256)` | 9010d07c          |
| `getRoleMemberCount(bytes32)`    | ca15c873          |
| `getStakers(uint256,uint256)`    | ad71bd36          |
| `hasRole(bytes32,address)`       | 91d14854          |
| `hasStaked(address)`             | c93c8f34          |
| `proxiableUUID()`                | 52d1902d          |
| `supportsInterface(bytes4)`      | 01ffc9a7          |
| `version()`                      | 54fd4d50          |


### Admin Roles

Accounts with administrative privileges could be used by attackers to facilitate attacks. This section analyses what each role can do.

#### Accounts with `DEFAULT_ADMIN` role on StakeHolder contract

This role is granted to the `roleAdmin` specified in the `initialize` function of the contract. Accounts with the `DEFAULT_ADMIN` account can:

* Grant administrator roles to any account, including the `DEFAULT_ADMIN` role
* Revoke administrator roles from any account, including the `DEFAULT_ADMIN` role
  * The `DEFAULT_ADMIN` role cannot be revoked from an account if it the only account with the `DEFAULT_ADMIN` role
* Renounce the `DEFAULT_ADMIN` role for itself, unless it is the only account with the `DEFAULT_ADMIN` role

Exploiting this attack surface requires compromising an account with `DEFAULT_ADMIN` role.

#### Accounts with `UPGRADE` role on StakeHolder contract

An account with `UPGRADE` role can:

* Upgrade the implementation contract.

Exploiting this attack surface requires compromising an account with `UPGRADE` role.


### Upgrade and Storage Slots

The table was constructed by using the command described below, and analysing the source code.

```
forge inspect StakeHolder --pretty storage
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
| balances                          | mapping(address => struct StakeHolder.StakeInfo)               | 301  | 0      | 32    | StakeHolder.sol |
| stakers                           | address[]                                                      | 302  | 0      | 32    | StakeHolder.sol |
| version                           | uint256                                                        | 303  | 0      | 32    | StakeHolder.sol |
| \_\_StakeHolderGap                | uint256[50]                                                    | 304  | 0      | 640   | StakeHolder.sol |


## Perceived Attackers

This section lists the attackers that could attack the `StakeHolder` contract.

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
