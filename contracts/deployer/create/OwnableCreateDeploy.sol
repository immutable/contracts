// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title OwnableCreateDeploy Contract
 * @notice This contract deploys new contracts using the `CREATE` opcode and is used as part of
 * the `CREATE3` deployment method.
 * @dev The contract can only be called by the owner of the contract, which is set to the deployer of the contract.
 * @dev This is a copy of the `CreateDeploy` contract in Axelar's SDK, with a modification that adds basic access control to the deployment function.
 *      see: https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/5f15a1036215f8b9c8eeb6438d352172b430dd38/contracts/deploy/CreateDeploy.sol
 */
contract OwnableCreateDeploy {
    // Address that is authorised to call the deploy function.
    address private immutable owner;

    constructor() {
        owner = msg.sender;
    }
    /**
     * @dev Deploys a new contract with the specified bytecode using the `CREATE` opcode.
     * @param bytecode The bytecode of the contract to be deployed
     */
    // slither-disable-next-line locked-ether

    function deploy(bytes memory bytecode) external payable {
        // solhint-disable-next-line custom-errors
        require(msg.sender == owner, "CreateDeploy: caller is not the owner");
        assembly {
            if iszero(create(callvalue(), add(bytecode, 32), mload(bytecode))) { revert(0, 0) }
        }
    }
}
