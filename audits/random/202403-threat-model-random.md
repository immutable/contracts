# Random Number Generation Threat Model

# Contents

- [Introduction](#introduction)
- [Architecture](#architecture)
- [Attack Surfaces](#attack-surfaces)
- [Perceived Attackers](#preceived-attackers)
- [Attack Mitigation](#attack-mitigation)
- [Conclusion](#conclusion)

# Introduction

This document is a threat model for the Random Number Generation contracts in preparation for external audit. The threat model is limited to the following Solidity files: `RandomSeedProvider.sol`,`RandomValues.sol`, `RandomSequences.sol`, `IOffchainRandomSource.sol`, and `SourceAdaptorBase.sol`. See the [Source Code](#source-code) for links to these files and more information about the how the code has been tested.


# Architecture

## Top Level Architecture

The Random Number Generation system on the Immutable platform is shown in the diagram below.

![Random number genration](./202402-threat-model-random/random-architecture.png)

Game contracts can extend ```RandomValues.sol``` or ```RandomSequences.sol```. 
```RandomSequences.sol``` is an extension of ```RandomValues.sol```. 
```RandomValues.sol``` interacts with the ```RandomSeedProvider.sol``` contract to request and retreive random seed values. 

There is one ```RandomSeedProvider.sol``` contract deployed per chain. Each game has its own instance of ```RandomValues.sol``` and / or ```RandomSequences.sol``` as this contract is integrated directly into the game contract. 

The ```RandomSeedProvider.sol``` operates behind a transparent proxy, ```ERC1967Proxy.sol```, with the upgrade
logic included in the ```UUPSUpgradeable.sol``` contract that ```RandomSeedProvider.sol``` extends. Using an upgradeable pattern allows the random manager contract to be upgraded to extend its feature set and resolve issues. 

The ```RandomSeedProvider.sol``` contract can be configured to use an off-chain random number source. This source is accessed via the ```IOffchainRandomSource.sol``` interface. To allow the flexibility to switch between off-chain random sources, there is an adaptor contract between the offchain random source contract and the random seed provider.

The architecture diagram shows a ChainLink VRF source and a Supra VRF source. This is purely to show the possibility of integrating with one off-chain service and then, at a later point choosing to switch to an alternative off-chain source. At present, there is no agreement to use any specific off-chain source.

```RandomValues.sol``` provides an API in which random numbers are requested in one transaction and then 
fulfilled in a later transaction. ```RandomSequences.sol``` provides an API in which a random number
is supplied and the next one is requested in the same transaction. Whereas the API offered by 
```RandomValues.sol``` provides numbers that can not be predicted, the API offered by 
```RandomSequences.sol``` means that savvy game players that can analyse blockchain state can 
predict the next random value to be generated. However, they are unable to the random number 
that will be generated. ```RandomSequences.sol```'s API can be used securely by ensuring 
the purpose of random numbers used in a game are clearly segregated, and that a different
sequence type is given for each purpose. 

## Random Seed Provider Design

TODO talk about roles

## Source Adaptor Base Design

TODO talk about roles

## Random Values Design

TODO talk about generating id, rather being passed in.

TODO talk about size being specified, rather than being dynamic

TODO talk about storing source as well as id, and source is address thus allowing for changing / upgrading source

## Random Sequences Design




## Other Information

This section provides links to all source code, test plans, test code.

### TODO Source Code
TODO update

This threat model pertains to the following source code:

- [RootERC20PredicateFlowRate.sol](https://github.com/immutable/poly-core-contracts/blob/d0a3be95ac9d2d7820903558d4668197f9d77d9a/contracts/root/flowrate/RootERC20PredicateFlowRate.sol): Version of ERC 20 Bridge contract to be deployed on Ethereum for ERC 20 tokens that originate on Ethereum, that includes security features.


### TODO Test Plans
TODO update


The following test plans were created to evaluate the tests required for adding Ether support and the security enhancements to the ERC 20 bridge. All tests described in the test plans were implemented.

- [Root ERC 20 Predicate, Ether Support](https://github.com/immutable/poly-core-contracts/blob/d0a3be95ac9d2d7820903558d4668197f9d77d9a/test/forge/root/RootERC20Predicate.tree)
- [Root ERC 20 Predicate, Security Enhancements](https://github.com/immutable/poly-core-contracts/blob/d0a3be95ac9d2d7820903558d4668197f9d77d9a/test/forge/root/flowrate/README.md)

### TODO Test Code
TODO update



The following test code was created to test the ERC 20 bridge Ether support and security enhancements.

- [Tests for RootERC20Predicate.sol, focusing on Ether support](https://github.com/immutable/poly-core-contracts/blob/d0a3be95ac9d2d7820903558d4668197f9d77d9a/test/forge/root/RootERC20Predicate.t.sol)


### TODO Continuous Integration

TODO REvise Each time a commit is pushed to a pull request, the [continuous integration loop executes](https://github.com/immutable/poly-core-contracts/actions).

### TODO Building, Testing, Coverage and Static Code Analysis

TODO: Revise 
For instructions on building the code, running tests, coverage, and Slither, see the [Using this Repo](https://github.com/immutable/poly-core-contracts/blob/d0a3be95ac9d2d7820903558d4668197f9d77d9a/README.md#using-this-repo) section of the README.md at the root of this repo.

# Attack Surfaces

The following sections list attack surfaces evaluated as part of this threat modelling exercise.

## TODO RootERC20PredicateFlowRate Externally Visible Functions

This section describes the externally visible functions available in `RootERC20PredicateFlowRate`. An attacker could formulate an attack in which they send one or more transactions that execute one or more of these functions.

The table below shows the list of externally visible functions. In addition to the name and function selector, the function type (transaction or view), and access control mechanisms are listed.

The list of functions and their function selectors was determined by the following command. The additional information was obtained by reviewing the code.

```
cd contracts/root/flowrate
forge inspect RootERC20PredicateFlowRate --pretty methods
```

| Name                                                                                 | Function Selector | Type        | Access Control       |
| ------------------------------------------------------------------------------------ | ----------------- | ----------- | -------------------- |
| DEFAULT_ADMIN_ROLE()                                                                 | a217fddf          | view        | -                    |
| DEPOSIT_SIG()                                                                        | d41f1771          | view        | -                    |
| MAP_TOKEN_SIG()                                                                      | f6451255          | view        | -                    |
| NATIVE_TOKEN()                                                                       | 31f7d964          | view        | -                    |
| WITHDRAW_SIG()                                                                       | b1768065          | view        | -                    |
| activateWithdrawalQueue()                                                            | af8bbb5e          | transaction | RATE role            |
| childERC20Predicate()                                                                | d57184e4          | view        | -                    |



## TODO Immutable zkEVM Validators: Block Hash Attack

## TODO Immutable zkEVM Validators: RANDAO Attack

## TODO VRF Key Compromise

## TODO Reuse a Random Value 



## TODO Accounts with DEFAULT_ADMIN, PAUSE, UNPAUSE, and RATE roles

Accounts with administrative privileges could be used by attackers to facilitate attacks. For example, an attacker could maliciously pause the bridge thus disrupting the bridge. Alternatively, used in conjunction with other attacks, the attacker could post malicious exits, which might enter the withdrawal queue, and then disable the withdrawal queue. Exploiting this attack surface requires compromising the administrative accounts with certain administrative roles.

## TODO: RootERC20PredicateFlowRate, ExitHelper, CheckpointManager, CustomSupernetsManager Contract Upgrade

This RootERC20PredicateFlowRate, ExitHelper, CheckpointManager, CustomSupernetsManager, StakeManager, and StateSender contracts are each deployed with a [TransparentUpgradeProxy](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/17c1a3a4584e2cbbca4131f2f1d16168c92f2310/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) and a [Proxy Admin](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/17c1a3a4584e2cbbca4131f2f1d16168c92f2310/contracts/proxy/transparent/ProxyAdmin.sol) contract. An account, that can be thought of as the Proxy Administrator, deploys the `TransparentUpgradeProxy` contract and the `ProxyAdmin` contract. This Proxy Administrator can at some later point call the [upgradeAndCall](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/17c1a3a4584e2cbbca4131f2f1d16168c92f2310/contracts/proxy/transparent/ProxyAdmin.sol#L74) function to upgrade the implementation of the contract. The `TransparentUpgradeProxy` contract executes code in the contracts via `delegateCall`, thus executing the code in logic contract in the context of the `TransparentUpgradeProxy` contract. For example, the Proxy Administrator could use the ability to update the implementation of `RootERC20PredicateFlowRate` to deploy a malicious version of the contract.Exploiting this attack surface requires compromising the administrative account responsible for upgrading the contracts.

## TODO RootERC20PredicateFlowRate Contract Storage Slots: Upgrade

An attack vector on future versions of this contract could be misaligned storage slots between a version and the subsequent version. That is, a new storage variable could be added without adjusting the storage gap variable for the file the variable is added to, thus moving the storage locations used by the new version of code relative to the old version of code. To monitor this attack surface, the storage slot utilisation or this initial version is shown in the table below. The table was constructed by using the commands described below.

```
cd contracts/root/flowrate
forge inspect RootERC20PredicateFlowRate --pretty storage
```

| Name                              | Type                                                                   | Slot | Offset | Bytes |
| --------------------------------- | ---------------------------------------------------------------------- | ---- | ------ | ----- |
| \_initialized                     | uint8                                                                  | 0    | 0      | 1     |
| \_initializing                    | bool                                                                   | 0    | 1      | 1     |
| stateSender                       | contract IStateSender                                                  | 0    | 2      | 20    |
| exitHelper                        | address                                                                | 1    | 0      | 20    |
| childERC20Predicate               | address                                                                | 2    | 0      | 20    |
| childTokenTemplate                | address                                                                | 3    | 0      | 20    |
| rootTokenToChildToken             | mapping(address => address)                                            | 4    | 0      | 32    |
| \_\_gapRootERC20Predicate         | uint256[50]                                                            | 5    | 0      | 1600  |
| \_\_gap                           | uint256[50]                                                            | 55   | 0      | 1600  |
| \_paused                          | bool                                                                   | 105  | 0      | 1     |
| \_\_gap                           | uint256[49]                                                            | 106  | 0      | 1568  |
| \_\_gap                           | uint256[50]                                                            | 155  | 0      | 1600  |
| \_roles                           | mapping(bytes32 => struct AccessControlUpgradeable.RoleData)           | 205  | 0      | 32    |
| \_\_gap                           | uint256[49]                                                            | 206  | 0      | 1568  |
| \_status                          | uint256                                                                | 255  | 0      | 32    |
| \_\_gap                           | uint256[49]                                                            | 256  | 0      | 1568  |
| flowRateBuckets                   | mapping(address => struct FlowRateDetection.Bucket)                    | 305  | 0      | 32    |
| withdrawalQueueActivated          | bool                                                                   | 306  | 0      | 1     |
| \_\_gapFlowRateDetecton           | uint256[50]                                                            | 307  | 0      | 1600  |
| pendingWithdrawals                | mapping(address => struct FlowRateWithdrawalQueue.PendingWithdrawal[]) | 357  | 0      | 32    |
| withdrawalDelay                   | uint256                                                                | 358  | 0      | 32    |
| \_\_gapFlowRateWithdrawalQueue    | uint256[50]                                                            | 359  | 0      | 1600  |
| largeTransferThresholds           | mapping(address => uint256)                                            | 409  | 0      | 32    |
| \_\_gapRootERC20PredicateFlowRate | uint256[50]                                                            | 410  | 0      | 1600  |

# Perceived Attackers

This section lists the attackers that could attack the ERC 20 bridge system.

It is assumed that all attackers have access to all documentation and source code of all systems related to the Immutable zkEVM, irrespective of whether the information resides in a public or private GitHub repository, email, Slack, Confluence, or any other information system.

## General Public

The General Public attacker can submit transactions on Ethereum or on the Immutable zkEVM. They use the standard interfaces of contracts to attempt to compromise the briding system.

## MEV Bot

MEV Bots observe transactions in the transaction pool either on Immutable zkEVM. They can front run transactions.

## Immutable zkEVM Block Proposer

TODO: Operator of an Ethereum Block Proposer could, within narrow limits, alter the block time stamp of the block they produce. If this block included transactions related to the withdrawal queue or flow rate mechanism, they might be able to have an affect on this mechanism.

## TODO: Spear Phisher

This attacker compromises accounts of people by using Spear Phishing attacks. For example they send a malicious PDF file to a user, which the user opens, the PDF file then installs malware on the user's computer. At this point, it is assumed that the Spear Phisher Attacker can detect all key strokes, mouse clicks, see all information retrieved, see any file in the user's file system, and execute any program on the user's computer.

## TODO: Server Powner

This attacker is able to compromise any server computer, _Powerfully Owning_ the computer. For instance, they can compromise a validator node on the Immutable zkEVM. They might do this by finding a buffer overflow vulnerability in the public API of the computer. They can read values from the computer's RAM. Importantly, they can access the BLS private key of the validator node.

## TODO: Insider

This attacker works for a company helping operate the Immutable zkEVM. This attacker could be being bribed or blackmailed. They can access the keys that they as an individual employee has access to. For instance, they might be one of the signers of the multi-signer administrative role.

# Attack Mitigation

This section outlines possible attacks against the attack surfaces by the attackers, and how those attacks are mitigated.

## Overview of Attacks on Functions in RootERC20PredicateFlowRate

The functions in RootERC20PredicateFlowRate fall into five categories:

- View functions that don't update state. These functions can not be used to attack the system as they do not alter the state of the blockchain.
- Transaction functions that have access control. These functions are considered in the section [Functions with Access Control](#functions-with-access-control).
- Transaction functions that have no access control. These functions are considered in the section [Functions with no Access Control](#functions-with-no-access-control).
- The `onL2StateReceive(uint256,address,bytes)` function has a form of access control, being limited to only being called by the `ExitHelper`. It is considered in the section [onL2StateReceiver](#onl2statereceive).
- The `initialize(address,address,address,address,address)` function is needed for compatibility with `RootERC20Predicate`. Transactions that call this function in the context of `RootERC20PredicateFlowRate` revert.
- The `initialize(address,address,address,address,address, address,address,address,address)` function can only be called once. It is called by the [TransparentUpgradeProxy](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/17c1a3a4584e2cbbca4131f2f1d16168c92f2310/contracts/proxy/transparent/TransparentUpgradeableProxy.sol) during the `TransparentUpgradeProxy`'s [constructor](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/17c1a3a4584e2cbbca4131f2f1d16168c92f2310/contracts/proxy/ERC1967/ERC1967Proxy.sol#L23), in the [context of the `TransparentUpgradeProxy`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/17c1a3a4584e2cbbca4131f2f1d16168c92f2310/contracts/proxy/ERC1967/ERC1967Upgrade.sol#L62). An attacker could not call this function again in the context of the `TransparentUpgradeProxy`, as it reverts when called a second time. Calling this function on the `RootERC20PredicateFlowRate` contract directly would only change the state of `RootERC20PredicateFlowRate`, and not that of the `TransparentUpgradeProxy`.

## Attacks on RootERC20PredicateFlowRate Functions with no Access Control

The [General Public Attacker](#general-public) could attempt to attack functions with no access control. The [MEV Bot Attacker](#mev-bot) could see transactions to these functions and attempt to front run them. The following sections analyse what a [General Public Attacker](#general-public) and an [MEV Bot Attacker](#mev-bot) could achieve.

### deposit(address,uint256), depositTo(address,address,uint256), and depositNativeTo(address)

The `deposit` and `depositTo` functions allow users to deposit ERC 20 tokens into the bridge, and have them bridged to the Immutable zkEVM. The `depositNativeTo` allows users to deposit Ether into the bridge, and wrapped Ether tokens bridge to the Immutable zkEVM. For the function variants ending in `To`, the recipient account on the Immutable zkEVM can be specified.

Attackers need to supply their own tokens. They are unable to switch the type of token to a more desirable token, or increase the amount of tokens they receive. The [General Public Attacker](#general-public) and the [MEV Bot Attacker](#mev-bot) are unable to mount successful attacks on these functions.

### finaliseQueuedWithdrawal(address,uint256) and finaliseQueuedWithdrawalsAggregated(address,address,uint256[])

The `finaliseQueuedWithdrawal` and the `finaliseQueuedWithdrawalsAggregated` allow withdrawals that are in the withdrawal queue to be dequeued and the funds distributed. Whereas the `finaliseQueuedWithdrawal` finalises one withdrawal, the `finaliseQueuedWithdrawalsAggregated` allows multiple withdrawals for the same token to be accumulated into a single withdrawal, thus saving on gas cost of executing multiple ERC 20 transfers or multiple Ether transfers.

The receiver of the funds is specified in the function call. The receiver only receives tokens or Ether that are in their withdrawal queue, and which have been in the withdrawal queue longer than the withdrawal period. The `finaliseQueuedWithdrawalsAggregated` checks that all withdrawals are for the same specified token.

The [General Public Attacker](#general-public) could send the receiver some coins that the receiver did not want. For example, they could attempt to implicate the receiver in a scandal, by sending the receiver tainted coins. Then, despite the receiver not finalising the tainted coins, a [General Public Attacker](#general-public) could finalise the coins on the receiver's behalf. This is not deemed to be an attack as the account submitting the transaction to `finaliseQueuedWithdrawal` or `finaliseQueuedWithdrawalsAggregated` to dequeue the tainted coins is recorded in Ethereum, and could be readily identified as not being associated with the receiver.

The [MEV Bot Attacker](#mev-bot) can not front run these calls as the tokens are sent to the receiver, and not to `msg.sender`.

The [Ethereum Block Proposer](#ethereum-block-proposer) could mount an attack by slightly altering the [block timestamp](#ethereum-block-timing-attacks). The attacker could force a withdrawal that was on the very of becoming available to have to wait an extra block. Any transactions hoping to finalise the withdrawal would revert as the finalise function call would be deemed too early. The attacker could change the block timestamp slightly, thus causing a withdrawal to cause the automatic flow rate detection mechanism to activate. These attacks seem unlikely to occur because [Ethereum Block Proposers](#ethereum-block-proposer) are not focused on attacking the Immutable zkEVM, a single system within the larger Ethereum ecosystem. Additionally, these attacks on withdrawal time or flow rate are only slightly moving the timing and thresholds, in a way that is insignificant relative to the standard settings. That is, the default withdrawal delay is one day. Causing the delay to be even one second longer appears insignificant. Assuming the flow rate bucket has its capacity set such that it is averaging the flow rate over a period of an hour or more, changing the block timestamp by even a second will have little effect.

### mapToken(address)

The `mapToken` function sets the mapping between a token contract address on Ethereum and the corresponding token contract on the Immutable zkEVM. The mapping algorithm is deterministic. The function call initiates a crosschain transaction, which results in the token contract on the Immutable zkEVM being deployed.

The [General Public Attacker](#general-public) could call this function multiple times for any token. They could then complete the crosschain transaction on the Immutable zkEVM, calling `commit` on the `StateReceiver` contract. The first time the function was called, the `ChildERC20Predicate` contract would deploy the contract. On the second attempt the function call would revert when the `ChildERC20Predicate` contract attempted to re-deploy the token contract. As such, the only possible attack could be that the [General Public Attacker](#general-public) deploys a multitude of ERC 20 contracts, filling up the Immutable zkEVM state. This is not deemed a significant attack.

The [MEV Bot Attacker](#mev-bot) would gain no benefit from front running calls to this function. As such, it would not call this function.

## Attacks on RootERC20PredicateFlowRate Functions with Access Control

The table below outlines functions in `RootERC20PredicateFlowRate` that have access control. The mitigation for all is to assume that all roles will be operated by multi-signature addresses such that an attacker would need to compromise multiple signers simultaneously. As such, even if some keys are compromised due to the [Spear Phishing Attacker](#spear-phisher) or the [Insider Attacker](#insider), the administrative actions will not be able to be executed as a threshold number of keys will not be available.

It should be noted that the intention is to have the threshold of number of signatures for the PAUSE role lower than for the other roles to make it easier for administrators to pause the bridge in a time of attack. However, the threshold will still be high enough that it will be difficult for an attacker to successfully mount such an attack. Even if they did successfully mount this attack, they would cause reputational damage, but would be unable to steal funds.

| Name                                                     | Function Selector | Type        | Access Control       |
| -------------------------------------------------------- | ----------------- | ----------- | -------------------- |
| activateWithdrawalQueue()                                | af8bbb5e          | transaction | RATE role            |
| deactivateWithdrawalQueue()                              | 1657a6e5          | transaction | RATE role            |
| grantRole(bytes32,address)                               | 2f2ff15d          | transaction | Role Admin for role. |
| pause()                                                  | 8456cb59          | transaction | PAUSE role           |
| renounceRole(bytes32,address)                            | 36568abe          | transaction | msg.sender           |
| revokeRole(bytes32,address)                              | d547741f          | transaction | Role Admin for role. |
| setRateControlThreshold(address,uint256,uint256,uint256) | 8f3a4e4f          | transaction | RATE role            |
| setWithdrawalDelay(uint256)                              | d2c13da5          | transaction | RATE role            |
| unpause()                                                | 3f4ba83a          | transaction | UNPAUSE role         |

## Attacks on RootERC20PredicateFlowRate onL2StateReceive Function

Attacks related to compromising the attack surfaces [Root Chain Bridge Contracts](#root-chain-bridge-contracts), [Child Chain Bridge Contracts](#child-chain-bridge-contracts), [Immutable zkEVM Validators](#immutable-zkevm-validators), and [Custom Supernets Manager, Owner role](#custom-supernets-manager-owner-role) all result in creating a malicious `exit`. `Exits` supplied to the `ExitHelper` call the `RootERC20PredicateFlowRate`'s `onL2StateReceive` function. These are used to execute withdrawals. These attacks are mitigated by the high value withdrawal threshold and flow rate detection mechanisms that will detect large outflows, and add the withdrawals to the withdrawal queue. The administrators of the system would then have time to make the determination that the system was under attack and pause the bridge. Once the bridge has been paused, the attack could be mitigated, possibly by upgrading the RootERC20PredicateFlowRate to remove the malicious withdrawals.

The [Server Powner Attacker](#server-powner) or other attacker that could create a malicious `exit`. They could then work with a [Spear Phishing Attacker](#spear-phisher) or the [Insider Attacker](#insider), to attempt to unpause the bridge and reduce the withdrawal delay so that they could finalise their malicious withdrawal. As per the [Attacks on RootERC20PredicateFlowRate Functions with Access Control](#attacks-on-rooterc20predicateflowrate-functions-with-access-control) section, the mitigation for this attack is to assume that all roles will be operated by multi-signature addresses such that an attacker would need to compromise multiple signers simultaneously.

## Upgrade Attacks

As described in the [RootERC20PredicateFlowRate, ExitHelper, CheckpointManager, CustomSupernetsManager Contract Upgrade](#rooterc20predicateflowrate-exithelper-checkpointmanager-customsupernetsmanager-contract-upgrade) section, a Proxy Administrator can upgrade the RootERC20PredicateFlowRate contract and other important contracts, changing the functionality to allow them to steal funds. As per the [Attacks on RootERC20PredicateFlowRate Functions with Access Control](#attacks-on-rooterc20predicateflowrate-functions-with-access-control) section, the mitigation for this attack is to assume that the Proxy Administrator will be operated by multi-signature addresses such that an attacker would need to compromise multiple signers simultaneously.

# Conclusion

This thread model has presented the architecture of the system, determined attack surfaces, and identified possible attackers and their capabilities. It has walked through each attack surface and based on the attackers, determined how the attacks are mitigated.

The most likely attack will be compromising administrative keys that are part of multi-signature systems that control administrative roles via a combination of insider attacks or spear phishing attacks. The threshold number of signatures will be high for all but the PAUSE role, and hence attackers are extremely unlikely to compromise enough keys to mount an attack. The threshold number of signers for the PAUSE role is lower, so could possibly enough keys could be compromised to mount an attack. Pausing the bridge though disruptive, will not allow attackers to steal funds.
