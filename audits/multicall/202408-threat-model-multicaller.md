# Background

The Guarded Multi-Caller contract is a security enhanced multi-caller contract. The Multicall contract pattern allows multiple smart contract function calls to be grouped into a single call. This provides the guarantee that function calls are executed atomically in a single transaction - they either all succeed or they all revert.

Additionally, this has the benefit that it reduces the number of JSON RPC requests that need to be sent to the blockchain's RPC provider. The security enhancements offered by the Guarded Multi-caller system are described in the sections below.

# Architecture

## Contract High-Level Design

The core of the `Guarded Multi-caller` system is `Multi-call`, allowing for the minting and burning of multiple NFTs from various collections in a single transaction. Due to the high level of security needed when working with NFTs, additional safety measures have been implemented to meet security standards.

- `Signature Validation` prevents multi-call instructions from random parties and only allows multi-call instructions from trusted parties.
- `Signer Access Control` manages these trusted parties.
- `References` provide anti-replay protection and help sync with any web2 system listening to events.

## System High-Level Design
---
![alt text](202309-threat-model-multicaller/architecture.png "Architecture")
### Components
---
| Component                    	| Ownership 	| Description                                                                                                             	|
|------------------------------	|-----------	|-------------------------------------------------------------------------------------------------------------------------	|
| Client                       	| Customer  	| This can be a game client or a mobile client that the players interact with.                                            	|
| Central Authority            	| Customer  	| It generates a list of function calls to be executed and gets a valid signature for those calls from `Multi-call Signer`. 	|
| Multi-call Signer            	| Customer 	  | It takes a list of function calls and generates a valid signature using a `EOA` with `MULTICALL_SIGNER_ROLE`.              	|
| Guarded Multicaller Contract 	| Customer  	| It validates an input signature and executes an authorized list of function calls.                                      	|

### Flow
---
Let’s look at the flow for basic crafting, where players burn one NFT from the `ERC721Card` contract and mint a new NFT on the `ERC721Pet` contract:

1. An `EOA` with `DEFAULT_ADMIN_ROLE` calls the `Guarded Multi-caller` contract to permit mint function `mint(address,uint256)` with the `ERC721Pet` contract.
2. An `EOA` with `DEFAULT_ADMIN_ROLE` calls the `ERC721Pet` contract to grant `MINTER_ROLE` to the `Guarded Multi-caller` contract.
3. A client requests the `Central Authority` to generate a list of function calls to burn and mint and request a signature from the `Multi-call Signer`.
4. The `Multi-call Signer` uses an account with `MULTICALL_SIGNER_ROLE` to sign the function calls and returns the signature back to the `Central Authority`.
5. The `Central Authority` returns the list of function calls and the signature to the client.
6. The `Client` approves the `Guarded Multi-caller` contract as a spender for their `ERC721Card` NFT.
7. The `Client` submits a transaction to the `Guarded Multi-caller` contract to execute the list of function calls.
8. The `GuardedMulticaller` contract calls the `ERC721Card` contract to burn the NFT and calls the `ERC721Pet` contract to mint a new NFT to the player’s wallet.

# Attack Surfaces

## Compromised Admin Keys
The compromised admin keys are able to assign the `MULTICALL_SIGNER_ROLE` to malicious parties and allow them to generate signatures that are valid to invoke function calls that are damaging, e.g. minting tokens on ERC20 contracts to attackers' addresses, or burning tokens from wallets that grant the contract approvals to their tokens.

## Compromised Signer Keys
The compromised signer keys can generate signatures that are valid to invoke function calls that are damaging, e.g. minting tokens on ERC20 contracts to attackers' addresses, or burning tokens from wallets that grant the contract approvals to their tokens.

# Attack Mitigation

- The keys associated with the `DEFAULT_ADMIN_ROLE` and `MULTICALL_SIGNER_ROLE` should be operated by a secure manner, for example a multi-signature wallet such that an attacker would need to compromise multiple signers simultaneously, or a securely stored hardware wallet.
- If admin keys are compromised, admins of token contracts should revoke `MINTER_ROLE` granted on the Guarded Multi-caller contract.
- If signer keys are compromised, admins of Guarded Multi-caller contracts should revoke the signer keys.
- If users grant access to their tokens, they should only grant approvals to the tokens needed for the multi-call transaction. If users have to grant access to all of their tokens, they should revoke the access immediately after the multi-call transaction is completed. With smart contract wallet's batch transaction, users can batch approvals, multi-call transaction, or approval revocation in one batch transaction.
- If the last account with DEFAULT_ADMIN_ROLE accidentally renounces or revokes their role, the contract becomes permissionless, and admins can no longer grant/revoke accesses. The following should happen:
  - Accounts with `MULTICALL_SIGNER_ROLE` should renounce their roles
  - A new Guarded Multi-caller contract should be deployed. 
  - All roles/accesses granted to the contract should be revoked. 

# Functions

Functions that _change_ state:
| Name | Function Selector | Access Control |
| ------------------------------------------------------------- | ----------------- | --------------------- |
| execute(address,bytes32,(address,string,bytes)[],uint256,bytes) | 29d4244c | Caller must have a valid signature |
| grantMulticallSignerRole(address) | 5910fd78 | DEFAULT_ADMIN_ROLE |
| grantRole(bytes32,address) | 2f2ff15d | DEFAULT_ADMIN_ROLE |
| renounceRole(bytes32,address) | 36568abe | Caller must have role to be renounced |
| revokeMulticallSignerRole(address) | 8f8d6ba0 | DEFAULT_ADMIN_ROLE |
| revokeRole(bytes32,address) | d547741f | DEFAULT_ADMIN_ROLE |

Functions that _do not change_ state (they are all permissionless):
| Name | Function Selector |
| ------------------------------------------------------------- | ----------------- |
| DEFAULT_ADMIN_ROLE() | a217fddf |
| eip712Domain() | 84b0196e |
| getRoleAdmin(bytes32) | 248a9ca3 |
| hasBeenExecuted(bytes32) | 3ddd8215 |
| hasRole(bytes32,address) | 91d14854 |
| supportsInterface(bytes4) | 01ffc9a7 |
| MULTICALL_SIGNER_ROLE() | 953ff95b |

## Tests

`forge test` will run all the related tests.
