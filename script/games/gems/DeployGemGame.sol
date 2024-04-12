// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {GemGame} from "../../../contracts/games/gems/GemGame.sol";

/**
 * @title IDeployer Interface
 * @notice This interface defines the contract responsible for deploying and optionally initializing new contracts
 *  via a specified deployment method.
 * @dev Credit to axelarnetwork https://github.com/axelarnetwork/axelar-gmp-sdk-solidity/blob/main/contracts/interfaces/IDeployer.sol
 */
interface IDeployer {
    function deploy(bytes memory bytecode, bytes32 salt) external payable returns (address deployedAddress_);
    function deployAndInit(bytes memory bytecode, bytes32 salt, bytes calldata init)
        external
        payable
        returns (address deployedAddress_);
    function deployedAddress(bytes calldata bytecode, address sender, bytes32 salt)
        external
        view
        returns (address deployedAddress_);
}

struct DeploymentArgs {
    address signer;
    address deployer;
    string salt;
}

contract DeployGemGame is Test {
    function deploy() external {
        address signer = vm.envAddress("DEPLOYER_ADDRESS");
        address deployer = vm.envAddress("OWNABLE_CREATE3_FACTORY_ADDRESS");
        string memory salt = vm.envString("GEM_GAME_SALT");

        DeploymentArgs memory deploymentArgs = DeploymentArgs({signer: signer, deployer: deployer, salt: salt});

        _deploy(deploymentArgs);
    }

    function _deploy(DeploymentArgs memory args) internal returns (GemGame gemGameContract) {
        IDeployer ownableCreate3 = IDeployer(args.deployer);

        // Create deployment bytecode and encode constructor args
        bytes memory bytecode = abi.encodePacked(type(GemGame).creationCode);

        bytes32 saltBytes = keccak256(abi.encode(args.salt));

        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(args.signer);

        address gemGameContractAddress = ownableCreate3.deploy(bytecode, saltBytes);
        gemGameContract = GemGame(gemGameContractAddress);

        vm.stopBroadcast();
    }
}
