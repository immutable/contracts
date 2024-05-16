# Test Plan for Common Token contracts

## HubOwner.sol
This section defines tests for contracts/token/common/HubOwner.sol. 
All of these tests are in test/token/common/HubOwner.t.sol.

| Test name                       |Description                                        | Happy Case | Implemented |
|---------------------------------| --------------------------------------------------|------------|-------------|
| testInit                        | Check that deployment work.                       | Yes        | Yes         |
| testRenounceAdmin               | Check that default admins can call renounce.      | Yes        | Yes         |
| testRenounceLastAdminBlocked    | Check that the last admin can not call renounce.  | No         | Yes         |
| testRenounceHubOwner            | Check that hub owners can call renounce.          | Yes        | Yes         |
| testRenounceLastHubOwnerBlocked | Check that the last hub owner can not call renounce. | No      | Yes         |
| testOwnerWhenNoHubOwner         | Check operation when there are no hub owners.     | No         | Yes         |
