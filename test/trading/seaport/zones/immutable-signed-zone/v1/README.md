# Test plan for ImmutableSignedZone

ImmutableSignedZone is a implementation of the SIP-7 specification with substandard 3.

## E2E tests with signing server

E2E tests will be handled in the server repository separate to the contract.

## Validate order unit tests

The core function of the contract is `validateOrder` where signature verification and a variety of validations of the `extraData` payload is verified by the zone to determine whether an order is considered valid for fulfillment. This function will be called by the settlement contract upon order fulfillment.

| Test name                                                                           | Description                                                        | Happy Case | Implemented |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------------------ | ---------- | ----------- |
| validateOrder reverts without extraData                                             | base failure case                                                  | No         | Yes         |
| validateOrder reverts with invalid extraData                                        | base failure case                                                  | No         | Yes         |
| validateOrder reverts with expired timestamp                                        | asserts the expiration verification behaviour                      | No         | Yes         |
| validateOrder reverts with invalid fulfiller                                        | asserts the fulfiller verification behaviour                       | No         | Yes         |
| validateOrder reverts with non 0 SIP6 version                                       | asserts the SIP6 version verification behaviour                    | No         | Yes         |
| validateOrder reverts with wrong consideration                                      | asserts the consideration verification behaviour                   | No         | Yes         |
| validates correct signature with context                                            | Happy path of a valid order                                        | Yes        | Yes         |
| validateOrder validates correct context with multiple order hashes - equal arrays   | Happy path with bulk order hashes - expected == actual             | Yes        | Yes         |
| validateOrder validates correct context with multiple order hashes - partial arrays | Happy path with bulk order hashes - expected is a subset of actual | Yes        | Yes         |
| validateOrder reverts when not all expected order hashes are in zone parameters     | Error case with bulk order hashes - actual is a subset of expected | No         | Yes         |
| validateOrder reverts incorrectly signed signature with context                     | asserts active signer behaviour                                    | No         | Yes         |
| validateOrder reverts a valid order after expiration time passes                    | asserts active signer behaviour                                    | No         | Yes         |

## Ownership unit tests

Test the ownership behaviour of the contract

| Test name                       | Description                 | Happy Case | Implemented |
| ------------------------------- | --------------------------- | ---------- | ----------- |
| deployer becomes owner          | base  case                  | Yes        | Yes         |
| transferOwnership works         | base  case                  | Yes        | Yes         |
| non owner cannot add signers    | asserts ownership behaviour | No         | Yes         |
| non owner cannot remove signers | asserts ownership behaviour | No         | Yes         |
| non owner cannot update owner   | asserts ownership behaviour | No         | Yes         |

## Active signer unit tests

Test the signer management behaviour of the contract

| Test name                          | Description                                         | Happy Case | Implemented |
| ---------------------------------- | --------------------------------------------------- | ---------- | ----------- |
| owner can add active signer        | base  case                                          | Yes        | Yes         |
| owner can deactivate signer        | base  case                                          | Yes        | Yes         |
| deactivate non active signer fails | asserts signers can only be deactivated when active | No         | Yes         |
| activate deactivated signer fails  | asserts signer cannot be recycled behaviour         | No         | Yes         |
