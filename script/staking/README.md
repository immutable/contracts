# Staking Scripts

This directory contains a range of scripts for interacting with staking contracts. 

## Common Environment Variables

The following variables must be specified for all scripts. They can be supplied via the environment or a `.env` file.

* `IMMUTABLE_NETWORK`: Must be 1 for Immutable zkEVM Mainnet, 0 for Testnet.
* `BLOCKSCOUT_APIKEY`: API key for verifying contracts on Blockscout. The key for use with Immutable zkEVM Mainnet will be different to the one used for Testnet. API keys for Immtuable zkEVM Mainnet can be obtained in the [block explorer](https://explorer.immutable.com/account/api-key).
* `HARDWARE_WALLET`: Set to `ledger` for a Ledger hardware wallet, `trezor` for a Trezor hardware wallet, and not set when using a private key. See [Forge's documentation](https://book.getfoundry.sh/reference/forge/forge-script#wallet-options---hardware-wallet) for more information on hardware wallet configuration.
* `HD_PATH`: Hierarchical Deterministic path. Must be set if using a Ledger or Trezor hardware wallet. Should be of the form: `HD_PATH="m/44'/60'/0'/0/0"`.
* PRIVATE_KEY: A private key must be specified if HARDWARE_WALLET is not specified. The value should not be prefixed with `0x`. 
* `DISTRIBUTE_ADMIN`: Initial account that will be authorised to distribute token to stakers. Specify 0x0000000000000000000000000000000000000000 to have no account with distribute administrator access.
* `STAKEHOLDER_TYPE`: The stake holder configuration can allow for an ERC20 token or native IMX to be staked. For the ERC20 token variant, `STAKEHOLDER_TYPE` must be `ERC20`. For native IMX, `STAKEHOLDER_TYPE` must be `WIMX`.
* `ERC20_STAKING_TOKEN`: Address of ERC20 token to be used for staking. For use by ERC20 deployment script, which is used when `STAKEHOLDER_TYPE`=`ERC20`.
* `WIMX_TOKEN`: Address of WIMX token contract. For use by the WIMX deployment scirpt, which is used when `STAKEHOLDER_TYPE`=`WIMX`.



## Simple Deployment

To deploy the `StakeHolderERC20.sol` or the `StakeHolderWIMX.sol` contract with a `ERC1967Proxy.sol`, use the `deploySimple.sh` script.

In addition to the common variables described above, the following variables must be specified via the environment or a `.env` file for the `deploySimple.sh` script:

* `DEPLOYER_ADDRESS`: Address that corresponds to the hardware wallet or private key. This account is used to deploy the `StakeHolderERC20` or `StakeHolderWIMX` and the `ERC1967Proxy` contracts.
* `ROLE_ADMIN`: Account that will be the initial role administrator. Accounts with the role administrator access can manage which accounts have `UPGRADE_ADMIN` and `DISTRIBUTED_ADMIN` access. Specify 0x0000000000000000000000000000000000000000 to have no account with role administrator access.
* `UPGRADE_ADMIN`: Initial account that will be authorised to upgrade the StakeHolderERC20 contract. Specify 0x0000000000000000000000000000000000000000 to have no account with upgrade administrator access.

## Complex Deployment

To deploy the `StakeHolderERC20.sol` or the `StakeHolderWIMX.sol` contract with a `ERC1967Proxy.sol` and a `TimelockController` using an `OwnableCreate3Deployer`, use the `deployComplex.sh` script. If you do not have access to an `OwnableCreate3Deployer` contract, use the `deployDeployer.sh` script to deploy this contract first.

In addition to the common variables described above, the following variables must be specified via the environment or a `.env` file for the `deployDeployer.sh` script:

* `DEPLOYER_ADDRESS`: Address that corresponds to the hardware wallet of private key. This account is used to deploy the `OwnableCreate3Deployer` contract.

In addition to the common variables described above, the following variables must be specified via the environment or a `.env` file for the `deployComplex.sh` script:

* `DEPLOYER_ADDRESS`: Address that corresponds to the hardware wallet or private key. This account is used to deploy the contracts via the `OwnableCreate3Deployer` contract.
* `OWNABLE_CREATE3_FACTORY_ADDRESS`: Address of the `OwnableCreate3Deployer` contract.
* `TIMELOCK_DELAY_SECONDS`: Time in seconds between proposing actions and executing them.
* `TIMELOCK_PROPOSER_ADMIN`: Address of account that can propose actions. Multiple proposers can be specified by modifying `StakeHolderScript.t.sol`.
* `TIMELOCK_EXECUTOR_ADMIN`: Address of account that can execute actions. Multiple executors can be specified by modifying `StakeHolderScript.t.sol`.
* `SALT`: Value used as the basis of salts used to deploy contracts to deterministic addresses. 

## Staking and Unstaking

The `stake.sh` script can be called to stake tokens and the `unstake.sh` script can be called to unstake tokens. Both scripts use the following variables:

* `STAKE_HOLDER_CONTRACT`: The address of the deployed stake holder contract.
* `STAKER_ADDRESS`: The address of the staker. The address corresponds to the hardware wallet or the private key. 
* `STAKER_AMOUNT`: The number of tokens. Note that the number of decimal places must be taken into account. For example, 1 IMX would be 1000000000000000000.
