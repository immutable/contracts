# Staking

The Immutable zkEVM staking system consists of the Staking Holder contract. This contract holds staked native IMX. Any account (EOA or contract) can stake any amount at any time. An account can remove all or some of their stake at any time. The contract has the facility to distribute rewards to stakers. 

## Immutable Contract Addresses

| Environment/Network      | Deployment Address | Commit Hash |
|--------------------------|--------------------|-------------|
| Immutable zkEVM Testnet  | Not deployed yet   |   -|
| Immutable zkEVM Mainnet  | Not deployed yet   |   -|

# Status

Contract threat models and audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Threat model              | Oct 21, 2024     | [`fd982abc49884af41e05f18349b13edc9eefbc1e`](https://github.com/immutable/contracts/blob/fd982abc49884af41e05f18349b13edc9eefbc1e/contracts/staking/README.md) | [202410-threat-model-stake-holder.md](../../audits/staking/202410-threat-model-stake-holder.md)              |



# Deployment

**Deploy and verify using CREATE3 factory contract:**

This repo includes a script for deploying via a CREATE3 factory contract. The script is defined as a test contract as per the examples [here](https://book.getfoundry.sh/reference/forge/forge-script#examples) and can be found in `./script/staking/DeployStakeHolder.sol`.

See the `.env.example` for required environment variables.

```sh
forge script script/stake/DeployStakeHolder.sol --tc DeployStakeHolder --sig "deploy()" -vvv --rpc-url {rpc-url} --broadcast --verifier-url https://explorer.immutable.com/api --verifier blockscout --verify --gas-price 10gwei
```

Optionally, you can also specify `--ledger` or `--trezor` for hardware deployments. See docs [here](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---hardware-wallet).


# Usage

To stake, any account should call `stake()`, passing in the amount to be staked as the msg.value.

To unstake, the account that previously staked should call, `unstake(uint256 _amountToUnstake)`.

Accounts that have DISTRIBUTE_ROLE that wish to distribute rewards should call, `distributeRewards(AccountAmount[] calldata _recipientsAndAmounts)`. The `AccountAmount` structure consists of recipient address and amount to distribute pairs. Distributions can only be made to accounts that have previously or are currently staking. The amount to be distributed must be passed in as msg.value and must equal to the sum of the amounts specified in the `_recipientsAndAmounts` array.

The `stakers` array needs to be analysed to determine which accounts have staked and how much. The following functions provide access to this data structure:

* `getNumStakers() returns (uint256 _len)`: Return the length of the stakers array. This is the number of accounts that ever staked using the contract.
* `getStakers(uint256 _startOffset, uint256 _numberToReturn) returns (address[] memory _stakers)`: Return all or a subset of the stakers array. The stakers array never changes order. As such, off-chain systems can cache previous results.
* `getBalance(address _account) returns (uint256 _balance)`: Return the amount staked by an account.
* `hasStaked(address _account) returns (bool _everStaked)`: Returns true if the account has ever staked.

# Administration Notes

The `StakeHolder` contract is `AccessControlEnumerableUpgradeable`, with the following minor modification:

* `_revokeRole(bytes32 _role, address _account)` has been overridden to prevent the last DEFAULT_ADMIN_ROLE (the last role admin) from either being revoked or renounced. 

The `StakeHolder` contract is `UUPSUpgradeable`. Only accounts with `UPGRADE_ROLE` are authorised to upgrade the contract.

## Upgrade Concept

The `upgradeStorage` function should be updated each new contract version. It should do the following:

* Check the value returned by `version`. This is the version of the code and associated storage format from the previous version prior to the upgrade. Three alternatives are possible:
  * The value is less than the new version: Upgrade as per the bullet points below.
  * The value is higher than the new version: This probably indicates that an attempt to upgrade the contract has mistakenly downgraded the contract to a previous version. The function should revert. 
  * The value is the same as the newt version: Someone (an attacker) has called the `upgradeStorage` function after the code has been upgraded. The function should revert.
* Based on the old code version and storage format indicated by the `version`, update the storage variables. Typically, upgrades only involve code changes, and require no storage variable changes. However, in some circumstances storage variables should also be updated.
* Update the `version` storage variable to indicate the new code version.
