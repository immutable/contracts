// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {IDeploy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeploy.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {ERC20MintableBurnable} from
    "@axelar-network/axelar-gmp-sdk-solidity/contracts/test/token/ERC20MintableBurnable.sol";
import {ERC20MintableBurnableInit} from
    "@axelar-network/axelar-gmp-sdk-solidity/contracts/test/token/ERC20MintableBurnableInit.sol";
import {ContractAddress} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/ContractAddress.sol";

import {OwnableCreate2Deployer} from "../../../contracts/deployer/create2/OwnableCreate2Deployer.sol";
import {Create2Utils} from "./Create2Utils.sol";

contract OwnableCreate2DeployerTest is Test, Create2Utils {
    OwnableCreate2Deployer private factory;
    bytes private erc20MockBytecode;
    bytes32 private erc20MockSalt;
    address private factoryOwner;

    event Deployed(address indexed deployedAddress, address indexed sender, bytes32 indexed salt, bytes32 bytecodeHash);

    using ContractAddress for address;

    function setUp() public {
        factoryOwner = address(0x123);
        factory = new OwnableCreate2Deployer(factoryOwner);

        erc20MockBytecode = type(ERC20Mock).creationCode;
        erc20MockSalt = Create2Utils.createSaltFromKey("erc20-mock-v1", factoryOwner);

        vm.startPrank(factoryOwner);
    }

    /// @dev deploying with empty bytecode should revert
    function test_RevertIf_DeployWithEmptyByteCode() public {
        vm.expectRevert(IDeploy.EmptyBytecode.selector);
        factory.deploy("", erc20MockSalt);
    }

    /// @dev only the owner should be able to deploy
    function test_RevertIf_DeployWithNonOwner() public {
        vm.stopPrank();

        address nonOwner = address(0x1);
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.deploy(erc20MockBytecode, erc20MockSalt);
    }

    /// @dev attempting to deploy a second contract with the same bytecode, salt and sender should revert
    function test_RevertIf_DeployAlreadyDeployedCreate2Contract() public {
        factory.deploy(erc20MockBytecode, erc20MockSalt);

        vm.expectRevert(IDeploy.AlreadyDeployed.selector);
        factory.deploy(erc20MockBytecode, erc20MockSalt);
    }

    /// @dev ensure contracts are deployed at the expected address
    function test_deploy_DeploysContractAtExpectedAddress() public {
        address expectedAddress = Create2Utils.predictCreate2Address(
            erc20MockBytecode, address(factory), address(factoryOwner), erc20MockSalt
        );

        /// forward the nonce of the owner and the factory, to confirm they doesn't influence address
        vm.setNonce(factoryOwner, vm.getNonce(factoryOwner) + 10);
        vm.setNonce(address(factory), vm.getNonce(address(factory)) + 20);

        vm.expectEmit();
        emit Deployed(expectedAddress, address(factoryOwner), erc20MockSalt, keccak256(erc20MockBytecode));
        address deployedAddress = factory.deploy(erc20MockBytecode, erc20MockSalt);

        assertTrue(deployedAddress.isContract(), "contract not deployed");
        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected address");
    }

    function test_deploy_DeploysContractWithConstructor() public {
        bytes memory erc20MintableBytecode =
            abi.encodePacked(type(ERC20MintableBurnable).creationCode, abi.encode("Test Token", "TEST", 18));
        bytes32 erc20MintableSalt = Create2Utils.createSaltFromKey("erc20-mintable-burnable-v1", factoryOwner);

        address expectedAddress = Create2Utils.predictCreate2Address(
            erc20MintableBytecode, address(factory), address(factoryOwner), erc20MintableSalt
        );

        vm.expectEmit();
        emit Deployed(expectedAddress, address(factoryOwner), erc20MintableSalt, keccak256(erc20MintableBytecode));
        address deployedAddress = factory.deploy(erc20MintableBytecode, erc20MintableSalt);
        ERC20MintableBurnable deployed = ERC20MintableBurnable(deployedAddress);

        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected");
        assertEq(deployed.name(), "Test Token", "deployed contract does not match expected");
        assertEq(deployed.symbol(), "TEST", "deployed contract does not match expected");
        assertEq(deployed.decimals(), 18, "deployed contract does not match expected");
    }

    function test_deploy_DeploysSameContractToDifferentAddresses_GivenDifferentSalts() public {
        address deployed1 = factory.deploy(erc20MockBytecode, erc20MockSalt);

        bytes32 newSalt = Create2Utils.createSaltFromKey("create2-deployer-test-v2", factoryOwner);
        address deployed2 = factory.deploy(erc20MockBytecode, newSalt);

        assertEq(deployed1.code, deployed2.code, "bytecodes of deployed contracts do not match");
        assertNotEq(deployed1, deployed2, "deployed contracts should not have the same address");
    }

    function test_deploy_DeploysContractChangedOwner() public {
        address newOwner = address(0x1);

        factory.transferOwnership(newOwner);
        assertEq(factory.owner(), newOwner, "owner did not change as expected");

        // check that the old owner cannot deploy
        vm.expectRevert("Ownable: caller is not the owner");
        factory.deploy(erc20MockBytecode, erc20MockSalt);

        // test that the new owner can deploy
        vm.startPrank(newOwner);
        address expectedAddress =
            Create2Utils.predictCreate2Address(erc20MockBytecode, address(factory), address(newOwner), erc20MockSalt);

        vm.expectEmit();
        emit Deployed(expectedAddress, address(newOwner), erc20MockSalt, keccak256(erc20MockBytecode));
        address deployedAddress = factory.deploy(erc20MockBytecode, erc20MockSalt);

        assertTrue(deployedAddress.isContract(), "contract not deployed");
        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected address");
    }

    /**
     * deployAndInit
     */
    function test_RevertIf_DeployAndInitWithNonOwner() public {
        vm.stopPrank();

        address nonOwner = address(0x1);
        vm.startPrank(nonOwner);
        vm.expectRevert("Ownable: caller is not the owner");
        factory.deployAndInit(erc20MockBytecode, erc20MockSalt, "");
    }

    function test_deployAndInit_DeploysAndInitsContract() public {
        bytes memory mintableInitBytecode =
            abi.encodePacked(type(ERC20MintableBurnableInit).creationCode, abi.encode(18));

        bytes32 mintableInitSalt = Create2Utils.createSaltFromKey("erc20-mintable-burnable-init-v1", factoryOwner);

        address expectedAddress = Create2Utils.predictCreate2Address(
            mintableInitBytecode, address(factory), address(factoryOwner), mintableInitSalt
        );

        bytes memory initPayload = abi.encodeWithSelector(ERC20MintableBurnableInit.init.selector, "Test Token", "TEST");
        vm.expectEmit();
        emit Deployed(expectedAddress, address(factoryOwner), mintableInitSalt, keccak256(mintableInitBytecode));
        address deployedAddress = factory.deployAndInit(mintableInitBytecode, mintableInitSalt, initPayload);
        ERC20MintableBurnableInit deployed = ERC20MintableBurnableInit(deployedAddress);

        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected");
        assertEq(deployed.name(), "Test Token", "deployed contract does not match expected");
        assertEq(deployed.symbol(), "TEST", "deployed contract does not match expected");
    }

    /**
     * deployedAddress
     */
    function test_deployedAddress_ReturnsPredictedAddress() public {
        address deployAddress = factory.deployedAddress(erc20MockBytecode, address(factoryOwner), erc20MockSalt);

        address predictedAddress = Create2Utils.predictCreate2Address(
            erc20MockBytecode, address(factory), address(factoryOwner), erc20MockSalt
        );
        address deployedAddress = factory.deploy(erc20MockBytecode, erc20MockSalt);

        assertEq(deployAddress, predictedAddress, "deployment address did not match predicted address");
        assertEq(deployAddress, deployedAddress, "deployment address did not match deployed address");
    }
}
