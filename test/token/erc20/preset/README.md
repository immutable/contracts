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
