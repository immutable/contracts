// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {TimelockController} from "openzeppelin-contracts-4.9.3/governance/TimelockController.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";

import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderWIMXV2} from "../../contracts/staking/StakeHolderWIMXV2.sol";

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

/**
 * @notice Deployment script and test code for the deployment script.
 * @dev testRemainderOfUpgradeProcessToV2 Tests the upgrade
 * @dev deployV2() to deploy the V2 contract.
 * @dev proposeUpgradeToV2() to propose the upgrade.
 * @dev executeUpgradeToV2deploy() to execute the upgrade.
 * For more details on deployment see ../../contracts/staking/README.md
 */
contract UpgradeToWIMXV2 is Test {
    // Values that are the same on Testnet and Mainnet
    // Timelock controller proposer.
    bytes32 constant PROPOSER_ROLE = 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1;
    // Timelock controller executor.
    bytes32 constant EXECUTOR_ROLE = 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63;
    // StakeHolder distributor.
    bytes32 private constant DISTRIBUTOR_ROLE = 0x444953545249425554455f524f4c450000000000000000000000000000000000;
    // Timelock controller contract.
    address constant TIMELOCK_CONTROLLER = 0x994a66607f947A47F33C2fA80e0470C03C30e289;
    // EIP1697 proxy.
    address constant STAKE_HOLDER_PROXY = 0xb6c2aA8690C8Ab6AC380a0bb798Ab0debe5C4C38;
    // Deployer of contracts and initial configuration.
    address constant DEPLOYER_ADDRESS = 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333;
    // Ownable create3 factory used to deploy contracts.
    address constant OWNABLE_CREATE3_FACTORY = 0x37a59A845Bb6eD2034098af8738fbFFB9D589610;
    // One week time delay.
    uint256 constant TIMELOCK_DELAY = 604800;
    // Address that StakeHolderWIMX v2 is deployed to.
    address constant STAKE_HOLDER_V2 = 0x2dE15aB8337a86787bEc585cd9159dfb75aFf97F;

    // Values that are different on Testnet and Mainnet
    // On mainnet Proposer and Execute are a GnosisSafeProxy.
    address constant MAINNET_PROPOSER = 0xaA53161A1fD22b258c89bA76B4bA11019034612D;
    address constant MAINNET_EXECUTOR = 0xaA53161A1fD22b258c89bA76B4bA11019034612D;
    // On testnet Proposer and Execute are the deployer address.
    address constant TESTNET_PROPOSER = DEPLOYER_ADDRESS;
    address constant TESTNET_EXECUTOR = DEPLOYER_ADDRESS;
    // Distrubtor accounts
    address constant TESTNET_NEW_DISTRIBUTOR = 0x8BA97cE2C64E2d1b9826bb6aB5e288524873f63D;
    address constant MAINNET_NEW_DISTRIBUTOR = 0xAd34133D4EA0c6F0a98FdE5FA2c668E12062C33D;

    // Used for fork testing
    string constant MAINNET_RPC_URL = "https://rpc.immutable.com/";

    TimelockController stakeHolderTimeDelay = TimelockController(payable(TIMELOCK_CONTROLLER));


    function deployV2() external {
        address stakeHolderV2 = _deployV2();
        console.log("Deployed StakeHolderWIMXV2 to: %s", stakeHolderV2);
    }

    function proposeUpgradeToV2() external {
        uint256 isMainnet = vm.envUint("IMMUTABLE_NETWORK");
        address proposer = (isMainnet == 1) ? MAINNET_PROPOSER : TESTNET_PROPOSER;
        _proposeUpgradeToV2(proposer, STAKE_HOLDER_V2);
    }

    function executeUpgradeToV2() external {
        uint256 isMainnet = vm.envUint("IMMUTABLE_NETWORK");
        address executor = (isMainnet == 1) ? MAINNET_EXECUTOR : TESTNET_EXECUTOR;
        _executeUpgradeToV2(executor, STAKE_HOLDER_V2);
    }

    function _deployV2() internal returns (address) {
        bytes32 salt = bytes32(uint256(17));

        IDeployer ownableCreate3 = IDeployer(OWNABLE_CREATE3_FACTORY);

        // Deploy StakeHolderWIMXV2 via the Ownable Create3 factory.
        // Create deployment bytecode and encode constructor args
        bytes memory deploymentBytecode = abi.encodePacked(
            type(StakeHolderWIMXV2).creationCode
        );
        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(DEPLOYER_ADDRESS);
        address stakeHolderImplAddress = ownableCreate3.deploy(deploymentBytecode, salt);
        vm.stopBroadcast();
        return stakeHolderImplAddress;
    }

    function _proposeUpgradeToV2(address _proposer, address _v2Impl) internal {
        assertTrue(stakeHolderTimeDelay.hasRole(PROPOSER_ROLE, _proposer), "Proposer does not have proposer role");

        (address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) = 
            _getProposalParams(_v2Impl);

        vm.startBroadcast(_proposer);
        stakeHolderTimeDelay.schedule(target, value, data, predecessor, salt, TIMELOCK_DELAY);
        vm.stopBroadcast();
    }

    function _executeUpgradeToV2(address _executor, address _v2Impl) internal {
        stakeHolderTimeDelay = TimelockController(payable(TIMELOCK_CONTROLLER));
        assertTrue(stakeHolderTimeDelay.hasRole(EXECUTOR_ROLE, _executor), "Executor does not have executor role");

        (address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) = 
            _getProposalParams(_v2Impl);

        bytes32 id = stakeHolderTimeDelay.hashOperation(target, value, data, predecessor, salt);
        assertTrue(stakeHolderTimeDelay.isOperationReady(id), "Operation is not yet ready");

        vm.startBroadcast(_executor);
        stakeHolderTimeDelay.execute(target, value, data, predecessor, salt);
        vm.stopBroadcast();

        IStakeHolder stakeHolder = IStakeHolder(STAKE_HOLDER_PROXY);
        assertEq(stakeHolder.version(), 2, "Upgrade did not upgrade to version 2");
    }

    function _getProposalParams(address _v2Impl) private returns (
        address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) {

        stakeHolderTimeDelay = TimelockController(payable(TIMELOCK_CONTROLLER));
        assertNotEq(_v2Impl, address(0), "StakeHolderV2 can not be address(0)");

        bytes memory callData = abi.encodeWithSelector(StakeHolderBase.upgradeStorage.selector, bytes(""));
        bytes memory upgradeCall = abi.encodeWithSelector(
            UUPSUpgradeable.upgradeToAndCall.selector, _v2Impl, callData);

        target = STAKE_HOLDER_PROXY;
        value = 0;
        data = upgradeCall;
        predecessor = bytes32(0);
        salt = bytes32(uint256(1));
    }


    // Test the remainder of the upgrade process.
    function testRemainderOfUpgradeProcessToV2() public {
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);

        IStakeHolder stakeHolder = IStakeHolder(STAKE_HOLDER_PROXY);
        if (stakeHolder.version() != 0) {
            // Upgrade has occurred. Nothing to test.
            return;
        }

        address stakeHolderV2 = STAKE_HOLDER_V2;
        if (stakeHolderV2.code.length == 0) {
            // StakeHolderWIMXV2 has not been deployed yet.
            stakeHolderV2 = _deployV2();
            require(stakeHolderV2 == STAKE_HOLDER_V2, "Incorrect deployment address");
        }

        (address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) = 
            _getProposalParams(stakeHolderV2);
        bytes32 id = stakeHolderTimeDelay.hashOperation(target, value, data, predecessor, salt);
        if (!stakeHolderTimeDelay.isOperation(id)) {
            // The upgrade hasn't been proposed yet.
            _proposeUpgradeToV2(MAINNET_PROPOSER, stakeHolderV2);
        }

        uint256 earliestExecuteTime = stakeHolderTimeDelay.getTimestamp(id);
        uint256 time = earliestExecuteTime;
        if (time < block.timestamp) {
            time = block.timestamp;
        }
        vm.warp(time);

        uint256 numStakersBefore = stakeHolder.getNumStakers();
        _executeUpgradeToV2(MAINNET_EXECUTOR, stakeHolderV2);
        uint256 numStakersAfter = stakeHolder.getNumStakers();
        assertEq(numStakersBefore, numStakersAfter, "Number of stakers before and after upgrade do not match");
    }
}
