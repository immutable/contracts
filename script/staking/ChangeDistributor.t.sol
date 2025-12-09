// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";
import {TimelockController} from "openzeppelin-contracts-4.9.3/governance/TimelockController.sol";
import {IERC20} from "openzeppelin-contracts-4.9.3/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {IAccessControlUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/IAccessControlUpgradeable.sol";

import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderWIMXV2} from "../../contracts/staking/StakeHolderWIMXV2.sol";
import {WIMX} from "../../contracts/staking/WIMX.sol";
import {OwnableCreate3Deployer} from "../../contracts/deployer/create3/OwnableCreate3Deployer.sol";


/**
 * @notice Script for proposing and executing changes to which account has distributor role.
 * @dev testDeploy is the test.
 * @dev proposeChangeDistributor and executeChangeDistributor() are the functions the script should call.
 * For more details on deployment see ../../contracts/staking/README.md
 */
contract ChangeDistributor is Test {
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
    // Address configured for distributor when the stakeholder contracts were deployed.
    address private constant OLD_DISTRIBUTOR = DEPLOYER_ADDRESS;

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


    function proposeChangeDistributor() external {
        uint256 isMainnet = vm.envUint("IMMUTABLE_NETWORK");
        address newDistributor = (isMainnet == 1) ? MAINNET_NEW_DISTRIBUTOR : TESTNET_NEW_DISTRIBUTOR;
        address proposer = (isMainnet == 1) ? MAINNET_PROPOSER : TESTNET_PROPOSER;
        _proposeChangeDistributor(proposer, newDistributor);
    }

    function executeChangeDistributor() external {
        uint256 isMainnet = vm.envUint("IMMUTABLE_NETWORK");
        address newDistributor = (isMainnet == 1) ? MAINNET_NEW_DISTRIBUTOR : TESTNET_NEW_DISTRIBUTOR;
        address executor = (isMainnet == 1) ? MAINNET_EXECUTOR : TESTNET_EXECUTOR;
        _executeChangeDistributor(executor, newDistributor);
    }

    function _proposeChangeDistributor(address _proposer, address _newDistributor) internal {
        assertTrue(stakeHolderTimeDelay.hasRole(PROPOSER_ROLE, _proposer), "Proposer does not have proposer role");

        (address[] memory targets, uint256[] memory values, bytes[] memory data, 
            bytes32 predecessor, bytes32 salt) = 
            _getChangeDistributorProposalParams(OLD_DISTRIBUTOR, _newDistributor);

        vm.startBroadcast(_proposer);
        stakeHolderTimeDelay.scheduleBatch(targets, values, data, predecessor, salt, TIMELOCK_DELAY);
        vm.stopBroadcast();
    }

    function _executeChangeDistributor(address _executor, address _newDistributor) internal {
        stakeHolderTimeDelay = TimelockController(payable(TIMELOCK_CONTROLLER));
        assertTrue(stakeHolderTimeDelay.hasRole(EXECUTOR_ROLE, _executor), "Executor does not have executor role");

        (address[] memory targets, uint256[] memory values, bytes[] memory data, 
            bytes32 predecessor, bytes32 salt) = 
            _getChangeDistributorProposalParams(OLD_DISTRIBUTOR, _newDistributor);

        bytes32 id = stakeHolderTimeDelay.hashOperationBatch(targets, values, data, predecessor, salt);
        assertTrue(stakeHolderTimeDelay.isOperationReady(id), "Operation is not yet ready");

        vm.startBroadcast(_executor);
        stakeHolderTimeDelay.executeBatch(targets, values, data, predecessor, salt);
        vm.stopBroadcast();
    }

    function _getChangeDistributorProposalParams(address _oldAccount, address _newAccount) private returns (
        address[] memory targets, uint256[] memory values, bytes[] memory data, bytes32 predecessor, bytes32 salt) {

        stakeHolderTimeDelay = TimelockController(payable(TIMELOCK_CONTROLLER));

        bytes memory callData0 = abi.encodeWithSelector(
            IAccessControlUpgradeable.revokeRole.selector, 
            DISTRIBUTOR_ROLE,
            _oldAccount);
        bytes memory callData1 = abi.encodeWithSelector(
            IAccessControlUpgradeable.grantRole.selector, 
            DISTRIBUTOR_ROLE,
            _newAccount);

        targets = new address[](2);
        values = new uint256[](2);
        data = new bytes[](2);
        targets[0] = STAKE_HOLDER_PROXY;
        values[0] = 0;
        data[0] = callData0;
        targets[1] = STAKE_HOLDER_PROXY;
        values[1] = 0;
        data[1] = callData1;

        predecessor = bytes32(0);
        salt = bytes32(uint256(1));
    }


    // Test the remainder of the upgrade process.
    function testRemainderChangeDistributor() public {
        uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
        vm.selectFork(mainnetFork);

        IStakeHolder stakeHolder = IStakeHolder(STAKE_HOLDER_PROXY);
        if (!stakeHolder.hasRole(DISTRIBUTOR_ROLE, OLD_DISTRIBUTOR)) {
            // Change distributor has occurred.
            return;
        }

        (address[] memory targets, uint256[] memory values, bytes[] memory data, 
            bytes32 predecessor, bytes32 salt) = 
            _getChangeDistributorProposalParams(OLD_DISTRIBUTOR, MAINNET_NEW_DISTRIBUTOR);
        bytes32 id = stakeHolderTimeDelay.hashOperationBatch(targets, values, data, predecessor, salt);

        if (!stakeHolderTimeDelay.isOperation(id)) {
            _proposeChangeDistributor(MAINNET_PROPOSER, MAINNET_NEW_DISTRIBUTOR);
        }

        uint256 earliestExecuteTime = stakeHolderTimeDelay.getTimestamp(id);
        uint256 time = earliestExecuteTime;
        if (time < block.timestamp) {
            time = block.timestamp;
        }
        vm.warp(time);

        _executeChangeDistributor(MAINNET_EXECUTOR, MAINNET_NEW_DISTRIBUTOR);

        require(!stakeHolder.hasRole(DISTRIBUTOR_ROLE, OLD_DISTRIBUTOR), "Old distributor still has role");
        require(stakeHolder.hasRole(DISTRIBUTOR_ROLE, MAINNET_NEW_DISTRIBUTOR), "New distributor does not have role");
    }
}
