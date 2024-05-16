# Test Plan for Immutable ERC20 Preset contracts

The ERC 20 contracts test the additional features supplied over and above the Open Zeppelin contracts.
These base contracts are extensively tested here:
https://github.com/OpenZeppelin/openzeppelin-contracts/tree/release-v4.9/test/token/ERC20 .


## Common Tests
ERC20TestCommon.t.sol provides a test that is common to all ERC20 contracts: checking initialisation.

ERC20MinternBurnerPermitCommon.t.sol provides tests used by both ImmutableERC20MinterBurnerPermit.t.sol 
and ImmutableERC20MinterBurnerPermitV2.t.sol. The ERC20MinternBurnerPermitCommon.t.sol tests are shown below:

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInitExtended                | Check initialisation.                             | Yes        | Yes         |
| testMint                        | Ensure successful minting by minter               | Yes         | Yes         |
| testOnlyMinterCanMint           | Ensure Only minter role can mint reverts.         | No         | Yes         |
| testCanOnlyMintUpToMaxSupply    | Ensure can only mint up to max supply             | No         | Yes         |
| testBurn                        | Ensure allowance is required to burn              | Yes        | Yes         |
| testBurnFrom                    | Ensure allowance is required to burnFrom          | Yes        | Yes         |
| testPermit                      | Ensure Permit works                               | Yes        | Yes         |


## ImmutableERC20FixedSupplyNoBurn.sol
This section defines tests for contracts/erc20/preset/ImmutableERC20FixedSupplyNoBurn.sol. 
All of the tests defined in the table below are in test/erc20/preset/ImmutableERC20FixedSupplyNoBurn.t.sol.

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInitExtended                | Check constructor.                                | Yes        | Yes         |
| testChangeOwner                 | Check change ownership.                           | Yes        | Yes         |
| testRenounceOwnershipBlocked    | Ensure renounceOwnership reverts.                 | No         | Yes         |

## ImmutableERC20FixedSupplyNoBurnV2.sol
This section defines tests for contracts/erc20/preset/ImmutableERC20FixedSupplyNoBurnV2.sol. 
All of the tests defined in the table below are in test/erc20/preset/ImmutableERC20FixedSupplyNoBurnV2.t.sol.
Note that ImmutableERC20FixedSupplyNoBurnV2 extends HubOwner.sol. The ownership features reside in 
HubOwner.sol, and hence are tested in HubOwner.t.sol.

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInitExtended                | Check constructor.                                | Yes        | Yes         |


## ImmutableERC20MinterBurnerPermit.sol
This section defines tests for contracts/erc20/preset/ImmutableERC20MinterBurnerPermit.sol. 
All of the tests defined in the table below are in test/erc20/preset/ImmutableERC20MinterBurnerPermit.t.sol.
Minter, Burner and Permit features are tested in ERC20MinternBurnerPermitCommon.t.sol, described above.

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInitExtended                | Check constructor.                                | Yes        | Yes         |
| testRenounceAdmin               | Check that default admins can call renounce.      | Yes        | Yes         |
| testRenounceLastAdminBlocked    | Check that the last admin can not call renounce.  | No         | Yes         |
| testRenounceHubOwner            | Check that hub owners can call renounce.          | Yes        | Yes         |
| testRenounceLastHubOwnerBlocked | Check that the last hub owner can not call renounce. | No      | Yes         |

## ImmutableERC20MinterBurnerPermitV2.sol
This section defines tests for contracts/erc20/preset/ImmutableERC20MinterBurnerPermitV2.sol. 
All of the tests defined in the table below are in test/erc20/preset/ImmutableERC20MinterBurnerPermitV2.t.sol.
Note that ImmutableERC20MinterBurnerPermitV2 extends HubOwner.sol. The ownership features reside in 
HubOwner.sol, and hence are tested in HubOwner.t.sol. Minter, Burner and Permit features are 
tested in ERC20MinternBurnerPermitCommon.t.sol, described above.


| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInitExtended                | Check constructor.                                | Yes        | Yes         |
| testRenounceAdmin               | Check that default admins can call renounce.      | Yes        | Yes         |
| testRenounceLastAdminBlocked    | Check that the last admin can not call renounce.  | No         | Yes         |
| testRenounceHubOwner            | Check that hub owners can call renounce.          | Yes        | Yes         |
| testRenounceLastHubOwnerBlocked | Check that the last hub owner can not call renounce. | No      | Yes         |
