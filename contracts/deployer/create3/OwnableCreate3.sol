// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IDeploy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeploy.sol";
import {ContractAddress} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/ContractAddress.sol";

import {OwnableCreate3Address} from "./OwnableCreate3Address.sol";
import {OwnableCreateDeploy} from "../create/OwnableCreateDeploy.sol";

/**
 * @title OwnableCreate3 contract
 * @notice This contract can be used to deploy a contract with a deterministic address that depends only on
 *         the deployer address and deployment salt, not the contract bytecode and constructor parameters.
 * @dev This contract is a copy of the `Create3` contract in Axelar's SDK, with a minor modification to use `OwnableCreateDeploy` instead of `CreateDeploy`.
 *      See: https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/1d3dd9a42abd37a315c18ec51163ddc5e5a08c21/contracts/deploy/Create3.sol
 */
contract OwnableCreate3 is OwnableCreate3Address, IDeploy {
    using ContractAddress for address;

    /**
     * @notice Deploys a new contract using the `CREATE3` method.
     * @dev This function first deploys the CreateDeploy contract using
     * the `CREATE2` opcode and then utilizes the CreateDeploy to deploy the
     * new contract with the `CREATE` opcode.
     * @param bytecode The bytecode of the contract to be deployed
     * @param deploySalt A salt to influence the contract address
     * @return deployed The address of the deployed contract
     */
    function _create3(bytes memory bytecode, bytes32 deploySalt) internal returns (address deployed) {
        deployed = _create3Address(deploySalt);

        if (bytecode.length == 0) revert EmptyBytecode();
        if (deployed.isContract()) revert AlreadyDeployed();

        // Deploy using create2
        OwnableCreateDeploy create = new OwnableCreateDeploy{salt: deploySalt}();

        if (address(create) == address(0)) revert DeployFailed();

        // Deploy using create
        create.deploy(bytecode);
    }
}
