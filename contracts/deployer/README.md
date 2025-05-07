# Contract Deployers

This directory provides two types of contract deployers: CREATE2 and CREATE3. Both deployer types facilitate contract deployment to predictable addresses, independent of the deployer account’s nonce. The deployers offer a more reliable alternative to using a Nonce Reserver Key (a key that is only used for deploying contracts, and has specific nonces reserved for deploying specific contracts), particularly across different chains. These factories can also be utilized for contracts that don't necessarily need predictable addresses. The advantage of this method, compared to using a deployer key in conjunction with a deployment factory contract, is that it can enable better standardisation and simplification of deployment processes and enables the rotation of the deployer key without impacting the consistency of the perceived deployer address for contracts.

Deployments via these factories can only be performed by the owner of the factory. 

**CAUTION**: When deploying a contract using one of these factories, it's crucial to note that `msg.sender` in the contract's constructor will refer to the contract factory's address and not to the deployer EOA. Therefore, any logic in a constructor that refers to `msg.sender` or assigns special privileges to this address would need to be changed.
An example of this type of logic is the [`Ownable` contract in OpenZeppelin's v4.x](https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable) library, which assigns default ownership of an inheriting contract to its deployer. When deploying a contract that inherits from `Ownable` using one of these factories, the contract's owner would thus be the factory. This would result in a loss of control over the contract. Hence, when deploying such a contract, it is necessary to ensure that a transfer of ownership from the factory to the desired owner is performed as part of the contract's construction. Specifically, a call to `transferOwnership(newOwner)` could be made to transfer ownership from the factory to the desired owner in the contract's constructor.


# Status

Contract audits and threat models:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Internal audit            | Work in Progress |                 |                |


# Architecture

## Create2 Deployer

**Contract:** [`OwnableCreate2Deployer`](./create2/OwnableCreate2Deployer.sol)

The [`OwnableCreate2Deployer`](./create2/OwnableCreate2Deployer.sol) uses the `CREATE2` opcode to deploy contracts to predictable addresses. The address of the deployed contract is determined by the following inputs:
- **Contract Bytecode**: A contract's creation code. In Solidity this can be obtained using `type(contractName).creationCode`. For contracts with constructor arguments, the bytecode has to be encoded along with the relevant constructor arguments e.g. `abi.encodePacked(type(contractName).creationCode, abi.encode(args...))`.
- **Salt**: The salt is a 32 byte value that is used to differentiate between different deployments.
- **Deployer Address**: The address of the authorised deployer.
- **Factory Address**: The address of the factory contract.

The contract offers two functions for deployment:
- `deploy(bytes memory bytecode, bytes32 salt)`: Deploys a contract to the address determined by the bytecode, salt and sender address. The bytecode should be encoded with the constructor arguments, if any.
- `deployAndInit(bytes memory bytecode, bytes32 salt, bytes memory initCode)`: Deploys a contract to the address determined by the bytecode, salt and sender address, and executes the provided initialisation function after deployment. Contracts that are deployed on different chains, with the same salt and sender, will produce different addresses if the constructor parameters are different. `deployAndInit` offers one way to get around this issue, wherein contracts can define a separate `init` function that can be called after deployment, in place of having a constructor.

The address that a contract will be deployed to, can be determined by calling the view function below:
- `deployedAddress(bytes memory bytecode, bytes32 salt, address deployer)`: Returns the address that a contract will be deployed to, given the bytecode, salt and authorised deployer address.

**Note:**  Alternatively, you can use the `CREATE3` deployer, described below.

## Create3 Deployer
**Contract:** [`OwnableCreate3Deployer`](./create3/OwnableCreate3Deployer.sol) 

A limitation of the [`OwnableCreate2Deployer`](./create2/OwnableCreate2Deployer.sol) deployer is that the deployment addresses for contracts are influenced by specific constructor parameters used. This can pose a problem when identical contract addresses are needed across chains, but each chain requires different constructor arguments. The [`OwnableCreate3Deployer`](./create3/OwnableCreate3Deployer.sol) deployer addresses this issue by not requiring the contract bytecode as an input to determine the deployment address. The address of the deployed contract is determined solely by the following inputs:
- **Salt**: A 32-byte value used to differentiate between various deployments.
- **Deployer Address**: The address of the authorized deployer.
- **Factory Address**: The address of the factory contract.

Similar to the `OwnableCreate2Deployer`, the contract offers two functions for deployment:
- `deploy(bytes memory bytecode, bytes32 salt)`: Deploys a contract to the address determined by the salt and sender address. The bytecode should be encoded with the constructor arguments, if any.
- `deployAndInit(bytes memory bytecode, bytes32 salt, bytes memory initCode)`: Deploys a contract to the address determined by the salt and sender address, and executes the provided initialisation function after deployment.

The address that a contract will be deployed to, can be determined by calling:
- `deployedAddress(bytes memory, bytes32 salt, address deployer)`: Returns the address that a contract will be deployed to, given the salt and authorised deployer address. The first parameter is the bytecode of the contract, and can be left empty in the case of the `OwnableCreate3Deployer`, which is not influenced by the contract bytecode.



# Deployed Addresses
The addresses of the deployed factories are listed below. The addresses of the factories are the same on both the Ethereum and Immutable chain, for each environment.

## Create2 Deployer
There are two instances of the Create2 deployer deployed on Mainnet and Testnet. 
While the contract behind both deployments are the same, their deployment configurations are different. The recommended deployer, as detailed below, ensures consistent addresses are generated for a given salt and bytecode across both chains (L1 and L2) and environments (Testnet and Mainnet). This means that a contract deployed with a given salt, will have the same address across L1 and L2 and across Testnet and Mainnet environments.
The second Create2 deployer is now deprecated. While it ensures consistent addresses across chains (L1 and L2), it does not maintain this consistency across environments (Testnet vs Mainnet). Thus, a deployment with identical bytecode and salt will result in different addresses on Mainnet compared to Testnet.

### Recommended

|         | Testnet and Mainnet                          |
|---------|----------------------------------------------|
| Address | `0xeC3AAc81D3CE025E14620105d5e424c9a72B67B8` |
| Owner   | `0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333` |


### Deprecated

|         | Testnet                                      | Mainnet                                      |
|---------|----------------------------------------------|----------------------------------------------|
| Address | `0xFd30E66f968F93F4c0C5AeA33601096A3fB2c48c` | `0x90DA206238384D33d7A35DCd7119c0CE76D37921` |
| Owner   | `0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333` | `0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333` |

## Create3 Deployer

|         | Testnet and Mainnet                          |
|---------|----------------------------------------------|
| Address | `0x37a59A845Bb6eD2034098af8738fbFFB9D589610` |
| Owner   | `0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333` |


