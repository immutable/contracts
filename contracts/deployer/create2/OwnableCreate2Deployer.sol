// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Deployer} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Deployer.sol";
import {Create2} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/deploy/Create2.sol";

/**
 * @title OwnableCreate2Deployer
 * @notice Deploys and initializes contracts using the `CREATE2` opcode. The contract exposes two functions, {deploy} and {deployAndInit}.
 *         {deploy} deploys a contract using the `CREATE2` opcode, and {deployAndInit} additionally initializes the contract using provided data.
 *         The latter offers a way of ensuring that the constructor arguments do not affect the deployment address.
 *
 * @dev This contract extends the {Deployer} contract from the Axelar SDK, by adding basic access control to the deployment functions.
 *      The contract has an owner, which is the only entity that can deploy new contracts.
 *
 * @dev The contract deploys a contract with the same bytecode, salt, and sender to the same address.
 *      The address where the contract will be deployed can be found using {deployedAddress}.
 */
contract OwnableCreate2Deployer is Ownable, Create2, Deployer {
    constructor(address owner) Ownable() {
        transferOwnership(owner);
    }

    /**
     * @dev Deploys a contract using the `CREATE2` opcode.
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
        return _create2(bytecode, deploySalt);
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} or {deployAndInit}.
     *      This function is called by the {deployedAddress} external functions in the {Deployer} contract.
     * @param bytecode The bytecode of the contract to be deployed
     * @param deploySalt A salt which is a hash of the sender's address and the `salt` provided by the sender, when calling the {deployedAddress} function.
     * @return The predicted deployment address of the contract
     */
    function _deployedAddress(bytes memory bytecode, bytes32 deploySalt) internal view override returns (address) {
        return _create2Address(bytecode, deploySalt);
    }
}
