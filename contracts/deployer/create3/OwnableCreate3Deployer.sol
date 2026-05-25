// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Deployer} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Deployer.sol";

import {OwnableCreate3} from "./OwnableCreate3.sol";

/**
 * @title OwnableCreate3Deployer
 * @notice The contract deploys contracts to deterministic addresses using the `CREATE3` method.
 *         This address of deployed contracts depends only on the deployer address, and a provided salt.
 *         Unlike the `CREATE2` deployment approach implemented in {OwnableCreate2Deployer}, the address of
 *         contracts does not depend on the bytecode of the contract or constructor parameters.
 *
 * @dev This contract extends the {Deployer} contract from the Axelar SDK, by adding basic access control to the deployment functions.
 *      The contract has an owner, which is the only entity that can deploy new contracts.
 *
 * @dev The contract deploys a contract with the same salt and sender to the same address.
 *      The address where a contract will be deployed can be found using {deployedAddress}.
 *
 * @dev The contract deploys an single use intermediary contract using the `CREATE2` opcode, and then uses the intermediary contract to deploy the new contract using the `CREATE` opcode.
 *      The intermediary contract is an instance of the {OwnableCreateDeploy} contract and can only be called by this contract.
 */
contract OwnableCreate3Deployer is Ownable, OwnableCreate3, Deployer {
    constructor(address owner) Ownable() {
        transferOwnership(owner);
    }

    /**
     * @dev Deploys a contract using the `CREATE3` method.
     *      This function is called by {deploy} and {deployAndInit} external functions in the {Deployer} contract.
     *      This function can only be called by the owner of this contract, hence the external {deploy} and {deployAndInit} functions can only be called by the owner.
     *      The address where the contract will be deployed can be found using the {deployedAddress} function.
     * @param bytecode The bytecode of the contract to be deployed
     * @param deploySalt A salt which is a hash of the salt provided by the sender and the sender's address.
     * @return The address of the deployed contract
     */
    // Slither 0.10.4 is mistakenly seeing this as dead code. It is called from Deployer.deploy
    // slither-disable-next-line dead-code
    function _deploy(bytes memory bytecode, bytes32 deploySalt) internal override onlyOwner returns (address) {
        return _create3(bytecode, deploySalt);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} or {deployAndInit}.
     *      This function is called by the {deployedAddress} external functions in the {Deployer} contract.
     * @param deploySalt A salt which is a hash of the sender's address and the `salt` provided by the sender, when calling the {deployedAddress} function.
     * @return The predicted deployment address of the contract
     */
    function _deployedAddress(bytes memory, bytes32 deploySalt) internal view override returns (address) {
        return _create3Address(deploySalt);
    }
}
