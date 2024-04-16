# Test Plan for Immutable ERC20 Preset contracts

## ImmutableERC20FixedSupplyNoBurn.sol
This section defines tests for contracts/erc20/preset/ImmutableERC20FixedSupplyNoBurn.sol. Note
that this contract extends Open Zeppelin's ERC 20 contract which is extensively tested here:
https://github.com/OpenZeppelin/openzeppelin-contracts/tree/release-v4.9/test/token/ERC20 .

All of the tests defined in the table below are in test/erc20/preset/ImmutableERC20FixedSupplyNoBurn.t.sol.

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check constructor.                                | Yes        | Yes         |
| testChangeOwner                 | Check change ownership.                           | Yes        | Yes         |
| testRenounceOwnershipBlocked    | Ensure renounceOwnership reverts.                 | No         | Yes         |


## ImmutableERC20MinterBurnerPermit.sol
This section defines tests for contracts/erc20/preset/ImmutableERC20MinterBurnerPermit.sol. Note
that this contract extends Open Zeppelin's ERC 20 contract which is extensively tested here:
https://github.com/OpenZeppelin/openzeppelin-contracts/tree/release-v4.9/test/token/ERC20 .

All of the tests defined in the table below are in test/erc20/preset/ImmutableERC20MinterBurnerPermit.t.sol.

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check constructor.                                | Yes        | Yes         |
| testChangeOwner                 | Check change ownership.                           | Yes        | Yes         |
| testRenounceOwnershipBlocked    | Ensure renounceOwnership reverts.                 | No         | Yes         |
| testOnlyMinterCanMunt           | Ensure Only minter role can mint reverts.         | No         | Yes         |
| testMint                        | Ensure successful minting by minter               | No         | Yes         |
| testCanOnlyMintUpToMaxSupply    | Ensure can only mint up to max supply             | No         | Yes         |
| testRenounceLastHubOwnerBlocked | Ensure the last hub owner cannot be renounced     | No         | Yes         |
| testRenounceLastAdminBlocked    | Ensure the last default admin cannot be renounced | No         | Yes         |
| testRenounceAdmin               | Ensure admin role can be renounced                | No         | Yes         |
| testRenounceHubOwner            | Ensure hub owner role can be renounced            | No         | Yes         |
| testBurnFrom                    | Ensure allowance is required to burnFrom          | Yes        | Yes         |
| testPermit                      | Ensure Permit works                               | Yes        | Yes         |
