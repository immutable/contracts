// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";
import {IDeploy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeploy.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {ERC20MintableBurnable} from
    "@axelar-network/axelar-gmp-sdk-solidity/contracts/test/token/ERC20MintableBurnable.sol";
import {ERC20MintableBurnableInit} from
    "@axelar-network/axelar-gmp-sdk-solidity/contracts/test/token/ERC20MintableBurnableInit.sol";
import {ContractAddress} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/libs/ContractAddress.sol";

import {OwnableCreate3Deployer} from "../../../contracts/deployer/create3/OwnableCreate3Deployer.sol";
import {OwnableCreateDeploy} from "../../../contracts/deployer/create/OwnableCreateDeploy.sol";
import {Create3Utils} from "./Create3Utils.sol";

contract OwnableCreate3DeployerTest is Test, Create3Utils {
    OwnableCreate3Deployer private factory;
    bytes private erc20MockBytecode;
    bytes32 private erc20MockSalt;
    address private factoryOwner;

    event Deployed(address indexed deployedAddress, address indexed sender, bytes32 indexed salt, bytes32 bytecodeHash);

    using ContractAddress for address;

    function setUp() public {
        factoryOwner = address(0x123);
        factory = new OwnableCreate3Deployer(factoryOwner);

        erc20MockBytecode = type(ERC20Mock).creationCode;
        erc20MockSalt = _createSaltFromKey("erc20-mock-v1");

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
    function test_RevertIf_DeployAlreadyDeployedCreate3Contract() public {
        factory.deploy(erc20MockBytecode, erc20MockSalt);

        vm.expectRevert(IDeploy.AlreadyDeployed.selector);
        factory.deploy(erc20MockBytecode, erc20MockSalt);
    }

    /// @dev ensure contracts are deployed at the expected address
    function test_deploy_DeploysContractAtExpectedAddress() public {
        address expectedAddress = predictCreate3Address(factory, address(factoryOwner), erc20MockSalt);

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
        bytes32 erc20MintableSalt = _createSaltFromKey("erc20-mintable-burnable-v1");

        address expectedAddress = predictCreate3Address(factory, address(factoryOwner), erc20MintableSalt);

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

        bytes32 newSalt = _createSaltFromKey("create3-deployer-test-v2");
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
        address expectedAddress = predictCreate3Address(factory, address(newOwner), erc20MockSalt);

        vm.expectEmit();
        emit Deployed(expectedAddress, address(newOwner), erc20MockSalt, keccak256(erc20MockBytecode));
        address deployedAddress = factory.deploy(erc20MockBytecode, erc20MockSalt);

        assertTrue(deployedAddress.isContract(), "contract not deployed");
        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected address");
    }

    /// @dev The Create3 deployer spawns a single use create deployer contract for a given salt.
    ///  This contract should be permissioned and only callable by the factory
    function test_deploy_SingleUseDeployerIsPermissioned() public {
        factory.deploy(erc20MockBytecode, erc20MockSalt);
        OwnableCreateDeploy singleUseDeployer = _getSingleUseCreateDeployer(erc20MockSalt);
        assertTrue(address(singleUseDeployer).isContract(), "single use deployer contract not detected");

        // as the factory owner
        vm.expectRevert("CreateDeploy: caller is not the owner");
        singleUseDeployer.deploy(erc20MockBytecode);

        // as any other user
        vm.startPrank(address(0x1));
        vm.expectRevert("CreateDeploy: caller is not the owner");
        singleUseDeployer.deploy(erc20MockBytecode);

        // as the factory. This should succeed
        vm.startPrank(address(factory));
        singleUseDeployer.deploy(erc20MockBytecode);
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

        bytes32 mintableInitSalt = _createSaltFromKey("erc20-mintable-burnable-init-v1");

        address expectedAddress = predictCreate3Address(factory, address(factoryOwner), mintableInitSalt);

        bytes memory initPayload = abi.encodeWithSelector(ERC20MintableBurnableInit.init.selector, "Test Token", "TEST");
        vm.expectEmit();
        emit Deployed(expectedAddress, address(factoryOwner), mintableInitSalt, keccak256(mintableInitBytecode));
        address deployedAddress = factory.deployAndInit(mintableInitBytecode, mintableInitSalt, initPayload);
        ERC20MintableBurnableInit deployed = ERC20MintableBurnableInit(deployedAddress);

        assertEq(deployedAddress, expectedAddress, "deployed address does not match expected");
        assertEq(deployed.name(), "Test Token", "deployed contract does not match expected");
        assertEq(deployed.symbol(), "TEST", "deployed contract does not match expected");
    }

    /// @dev The Create3 deployer spawns a single use create deployer contract for a given salt.
    ///  This contract should be permissioned and only callable by the factory
    function test_deployAndInit_SingleUseDeployerIsPermissioned() public {
        bytes memory mintableInitBytecode =
            abi.encodePacked(type(ERC20MintableBurnableInit).creationCode, abi.encode(18));

        bytes32 mintableInitSalt = _createSaltFromKey("erc20-mintable-burnable-init-v1");
        bytes memory initPayload = abi.encodeWithSelector(ERC20MintableBurnableInit.init.selector, "Test Token", "TEST");

        factory.deployAndInit(mintableInitBytecode, mintableInitSalt, initPayload);

        OwnableCreateDeploy singleUseDeployer = _getSingleUseCreateDeployer(mintableInitSalt);
        assertTrue(address(singleUseDeployer).isContract(), "single use deployer contract not detected");

        // as the factory owner
        vm.expectRevert("CreateDeploy: caller is not the owner");
        singleUseDeployer.deploy(erc20MockBytecode);

        // as any other user
        vm.startPrank(address(0x1));
        vm.expectRevert("CreateDeploy: caller is not the owner");
        singleUseDeployer.deploy(erc20MockBytecode);

        // as the factory. This should succeed
        vm.startPrank(address(factory));
        singleUseDeployer.deploy(erc20MockBytecode);
    }
    /**
     * deployedAddress
     */

    /// @dev Same contracts initialised with different constructor parameters, should be deployed to the same address if using the same sender and salt
    function test_deployedAddress_SameContractSameSaltDifferentConstructorParams() public {
        bytes memory bytecode1 =
            abi.encodePacked(type(ERC20MintableBurnable).creationCode, abi.encode("Token 1", "T1", 18));
        bytes memory bytecode2 =
            abi.encodePacked(type(ERC20MintableBurnable).creationCode, abi.encode("Token 2", "T2", 18));
        bytes32 salt = _createSaltFromKey("erc20-mintable-burnable-v1");

        address expectedAddress1 = factory.deployedAddress(bytecode1, address(factoryOwner), salt);
        address expectedAddress2 = factory.deployedAddress(bytecode2, address(factoryOwner), salt);

        assertEq(expectedAddress1, expectedAddress2, "address for contracts with same salt and sender don't match");
    }

    /// @dev Different contracts should be deployed to the same address if using the same sender and salt
    function test_deployedAddress_DifferentContractsSameSalt() public {
        bytes32 salt = _createSaltFromKey("test-salt");
        bytes memory bytecode1 = type(ERC20Mock).creationCode;
        bytes memory bytecode2 = type(ERC20MintableBurnable).creationCode;

        address expectedAddress1 = factory.deployedAddress(bytecode1, address(factoryOwner), salt);
        address expectedAddress2 = factory.deployedAddress(bytecode2, address(factoryOwner), salt);

        assertEq(expectedAddress1, expectedAddress2, "address for contracts with same salt and sender don't match");
    }

    /**
     * private helper functions
     */
    function _createSaltFromKey(string memory key) private view returns (bytes32) {
        return keccak256(abi.encode(address(factoryOwner), key));
    }

    function _getSingleUseCreateDeployer(bytes32 salt) private view returns (OwnableCreateDeploy) {
        return OwnableCreateDeploy(
            _create2Address(type(OwnableCreateDeploy).creationCode, salt, address(factory), address(factoryOwner))
        );
    }

    /**
     * @notice Computes the deployed address that will result from the `CREATE2` method.
     * @param bytecode The bytecode of the contract to be deployed
     * @param salt A salt to influence the contract address
     * @param deployer The address of the deployer contract
     * @param sender The address of the authorised sender that calls the deployer contract
     * @return address The deterministic contract address if it was deployed
     */
    function _create2Address(bytes memory bytecode, bytes32 salt, address deployer, address sender)
        internal
        view
        returns (address)
    {
        bytes32 deploySalt = keccak256(abi.encode(sender, salt));
        console.logBytes32(salt);
        return address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(deployer),
                            deploySalt,
                            keccak256(bytecode) // init code hash
                        )
                    )
                )
            )
        );
    }
}
