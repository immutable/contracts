// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OwnableCreateDeploy} from "../create/OwnableCreateDeploy.sol";

/**
 * @title OwnableCreate3Address contract
 * @notice This contract can be used to predict the deterministic deployment address of a contract deployed with the `CREATE3` technique.
 * @dev This contract is a copy of the `Create3Address` contract in Axelar's SDK, with a minor modification to use `OwnableCreateDeploy` instead of `CreateDeploy`.
 *      See: https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/1d3dd9a42abd37a315c18ec51163ddc5e5a08c21/contracts/deploy/Create3Address.sol
 */
abstract contract OwnableCreate3Address {
    /// @dev bytecode hash of the CreateDeploy helper contract
    bytes32 internal immutable createDeployBytecodeHash;

    constructor() {
        createDeployBytecodeHash = keccak256(type(OwnableCreateDeploy).creationCode);
    }

    /**
     * @notice Compute the deployed address that will result from the `CREATE3` method.
     * @param deploySalt A salt to influence the contract address
     * @return deployed The deterministic contract address if it was deployed
     */
    function _create3Address(bytes32 deploySalt) internal view returns (address deployed) {
        address deployer = address(
            uint160(uint256(keccak256(abi.encodePacked(hex"ff", address(this), deploySalt, createDeployBytecodeHash))))
        );

        deployed = address(uint160(uint256(keccak256(abi.encodePacked(hex"d694", deployer, hex"01")))));
    }
}
