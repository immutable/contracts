# Immutable X Contracts

The immutable x v4 contracts provide functionality for enabling immutable-x users to off-ramp assets from the StarkEx network to Ethereum network.
From v4 onwards, Starkex changed the deposit, withdrawal and registration flows to be more efficient and more trustless, and this contract acts as a wrapper around the StarkEx contract to provide a more user-friendly interface.

# Status

Contract audits and threat models:

| Description    | Date             |Version Audited  | Link to Report |
|----------------|------------------|-----------------|----------------|
| Internal audit | Feb 16, 2024     | [4f0fd701e357e2bc9c94d13a6a46babdb6a5fbf2](https://github.com/immutable/contracts/tree/4f0fd701e357e2bc9c94d13a6a46babdb6a5fbf2/contracts/bridge/x/v4) | [202402-internal-audit-immutablex-bridge-v4](../../../../audits/bridge/x/202402-internal-audit-immutablex-bridge-v4.pdf) |


## Immutable Contract Addresses

| Environment/Network      | Core (StarkEx Bridge) Contract                                                                                                 | User Registration Contract                                                                                                     |
|--------------------------|--------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| **Dev (Sepolia)**        | [0x590c809bd5ff50dcb39e4320b60139b29b880174](https://sepolia.etherscan.io/address/0x590c809bd5ff50dcb39e4320b60139b29b880174)  | [0x31D79A2b1E0150b73D243826b93ba7BCaE7fCB60](https://sepolia.etherscan.io/address/0x31D79A2b1E0150b73D243826b93ba7BCaE7fCB60)  |
| **Sandbox (Sepolia)**    | [0x2d5C349fD8464DA06a3f90b4B0E9195F3d1b7F98](https://sepolia.etherscan.io/address/0x2d5C349fD8464DA06a3f90b4B0E9195F3d1b7F98)  | [0xd1527c65c6287ec5ab816d328eb83bb4cb690e92](https://sepolia.etherscan.io/address/0xd1527c65c6287ec5ab816d328eb83bb4cb690e92)  |
| **Production (Mainnet)** | [0x5fdcca53617f4d2b9134b29090c87d01058e27e9](https://etherscan.io/address/0x5FDCCA53617f4d2b9134B29090C87D01058e27e9)          | [0xac88a57943b5BBa1ecd931F8494cAd0B7F717590](https://etherscan.io/address/0xac88a57943b5BBa1ecd931F8494cAd0B7F717590)          |

## RegistrationV4

This contract is a wrapper around the StarkEx contract to provide a more user-friendly interface for executing multiple transactions on the StarkEx contract at once.

## CoreV4

This contract is an interface for the StarkEx Core contract v4 version.
It is used to interact with the StarkEx Core contract from the Registration contract.
The Core contract is used to register and withdraw users and assets from the StarkEx system.
