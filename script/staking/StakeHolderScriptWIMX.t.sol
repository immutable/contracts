// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {ERC1967Proxy} from "openzeppelin-contracts-4.9.3/proxy/ERC1967/ERC1967Proxy.sol";
import {TimelockController} from "openzeppelin-contracts-4.9.3/governance/TimelockController.sol";
import {IERC20} from "openzeppelin-contracts-4.9.3/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";

import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderBase} from "../../contracts/staking/StakeHolderBase.sol";
import {StakeHolderWIMXV2} from "../../contracts/staking/StakeHolderWIMXV2.sol";
import {WIMX} from "../../contracts/staking/WIMX.sol";
import {OwnableCreate3Deployer} from "../../contracts/deployer/create3/OwnableCreate3Deployer.sol";

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

// Args needed for compex deployment using CREATE3 and a TimelockController
struct ComplexDeploymentArgs {
    address signer;
    address factory;
    string salt;
}
struct ComplexStakeHolderContractArgs {
    address distributeAdmin;
    address token;
}
struct ComplexTimelockContractArgs {
    uint256 timeDelayInSeconds;
    address proposerAdmin;
    address executorAdmin;
}


// Args needed for simple deployment
struct SimpleDeploymentArgs {
    address deployer;
}
struct SimpleStakeHolderContractArgs {
    address roleAdmin;
    address upgradeAdmin;
    address distributeAdmin;
    address token;
}



/**
 * @notice Deployment script and test code for the deployment script.
 * @dev testDeploy is the test.
 * @dev deploy() is the function the script should call.
 * For more details on deployment see ../../contracts/staking/README.md
 */
contract StakeHolderScriptWIMX is Test {

    /**
     * Deploy the OwnableCreate3Deployer needed for the complex deployment.
     */
    function deployDeployer() external {
        address signer = vm.envAddress("DEPLOYER_ADDRESS");
        _deployDeployer(signer);
    }

    /**
     * Deploy StakeHolderWIMXV2 using Create3, with the TimelockController.
     */
    function deployComplex() external {
        address signer = vm.envAddress("DEPLOYER_ADDRESS");
        address factory = vm.envAddress("OWNABLE_CREATE3_FACTORY_ADDRESS");
        address distributeAdmin = vm.envAddress("DISTRIBUTE_ADMIN");
        address token = vm.envAddress("WIMX_TOKEN");
        uint256 timeDelayInSeconds = vm.envUint("TIMELOCK_DELAY_SECONDS");
        address proposerAdmin = vm.envAddress("TIMELOCK_PROPOSER_ADMIN");
        address executorAdmin = vm.envAddress("TIMELOCK_EXECUTOR_ADMIN");
        string memory salt = vm.envString("SALT");

        ComplexDeploymentArgs memory deploymentArgs = ComplexDeploymentArgs({signer: signer, factory: factory, salt: salt});

        ComplexStakeHolderContractArgs memory stakeHolderArgs =
            ComplexStakeHolderContractArgs({distributeAdmin: distributeAdmin, token: token});

        ComplexTimelockContractArgs memory timelockArgs = 
            ComplexTimelockContractArgs({timeDelayInSeconds: timeDelayInSeconds, proposerAdmin: proposerAdmin, executorAdmin: executorAdmin});
        _deployComplex(deploymentArgs, stakeHolderArgs, timelockArgs);
    }

    /**
     * Deploy StakeHolderWIMXV2 using an EOA.
     */
    function deploySimple() external {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address roleAdmin = vm.envAddress("ROLE_ADMIN");
        address upgradeAdmin = vm.envAddress("UPGRADE_ADMIN");
        address distributeAdmin = vm.envAddress("DISTRIBUTE_ADMIN");
        address token = vm.envAddress("WIMX_TOKEN");

        SimpleDeploymentArgs memory deploymentArgs = SimpleDeploymentArgs({deployer: deployer});

        SimpleStakeHolderContractArgs memory stakeHolderArgs =
            SimpleStakeHolderContractArgs({
                roleAdmin: roleAdmin, upgradeAdmin: upgradeAdmin, 
                distributeAdmin: distributeAdmin, token: token});
        _deploySimple(deploymentArgs, stakeHolderArgs);
    }

    function stake() external {
        address stakeHolder = vm.envAddress("STAKE_HOLDER_CONTRACT");
        address staker = vm.envAddress("STAKER_ADDRESS");
        uint256 amount = vm.envUint("STAKER_AMOUNT");
        _stake(IStakeHolder(stakeHolder), staker, amount);
    }

    function unstake() external {
        address stakeHolder = vm.envAddress("STAKE_HOLDER_CONTRACT");
        address staker = vm.envAddress("STAKER_ADDRESS");
        uint256 amount = vm.envUint("STAKER_AMOUNT");
        _unstake(IStakeHolder(stakeHolder), staker, amount);
    }

    /**
     * Deploy the OwnableCreate3Deployer contract. Set the owner to the
     * contract deployer.
     */
    function _deployDeployer(address _deployer) private {
        vm.startBroadcast(_deployer);
        new OwnableCreate3Deployer(_deployer);
        vm.stopBroadcast();
    }

    /**
     * Deploy StakeHolderWIMXV2 using Create3, with the TimelockController.
     */
    function _deployComplex(
        ComplexDeploymentArgs memory deploymentArgs, 
        ComplexStakeHolderContractArgs memory stakeHolderArgs,
        ComplexTimelockContractArgs memory timelockArgs)
        private
        returns (StakeHolderWIMXV2 stakeHolderContract, TimelockController timelockController)
    {
        IDeployer ownableCreate3 = IDeployer(deploymentArgs.factory);

        bytes32 salt1 = keccak256(abi.encode(deploymentArgs.salt));
        bytes32 salt2 = keccak256(abi.encode(salt1));
        bytes32 salt3 = keccak256(abi.encode(salt2));

        // Deploy TimelockController via the Ownable Create3 factory.
        address timelockAddress;
        bytes memory deploymentBytecode;
        {
            address[] memory proposers = new address[](1);
            proposers[0] = timelockArgs.proposerAdmin;
            address[] memory executors = new address[](1);
            executors[0] = timelockArgs.executorAdmin;
            // Create deployment bytecode and encode constructor args
            deploymentBytecode = abi.encodePacked(
                type(TimelockController).creationCode, 
                abi.encode(
                    timelockArgs.timeDelayInSeconds,
                    proposers,
                    executors,
                    address(0)
                )
            );
            /// @dev Deploy the contract via the Ownable CREATE3 factory
            vm.startBroadcast(deploymentArgs.signer);
            timelockAddress = ownableCreate3.deploy(deploymentBytecode, salt1);
            vm.stopBroadcast();
        }


        // Deploy StakeHolderWIMXV2 via the Ownable Create3 factory.
        // Create deployment bytecode and encode constructor args
        deploymentBytecode = abi.encodePacked(
            type(StakeHolderWIMXV2).creationCode
        );
        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(deploymentArgs.signer);
        address stakeHolderImplAddress = ownableCreate3.deploy(deploymentBytecode, salt2);
        vm.stopBroadcast();

        // Deploy ERC1967Proxy via the Ownable Create3 factory.
        // Create init data for the ERC1967 Proxy
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderWIMXV2.initialize.selector, 
            timelockAddress, // roleAdmin
            timelockAddress, // upgradeAdmin
            stakeHolderArgs.distributeAdmin,
            stakeHolderArgs.token
        );
        // Create deployment bytecode and encode constructor args
        deploymentBytecode = abi.encodePacked(
            type(ERC1967Proxy).creationCode,
            abi.encode(stakeHolderImplAddress, initData)
        );
        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(deploymentArgs.signer);
        address stakeHolderContractAddress = ownableCreate3.deploy(deploymentBytecode, salt3);
        vm.stopBroadcast();

        stakeHolderContract = StakeHolderWIMXV2(payable(stakeHolderContractAddress));
        timelockController = TimelockController(payable(timelockAddress));
    }

    /**
     * Deploy StakeHolderWIMXV2 using an EOA and no time lock.
     */
    function _deploySimple(
        SimpleDeploymentArgs memory deploymentArgs, 
        SimpleStakeHolderContractArgs memory stakeHolderArgs)
        private
        returns (StakeHolderWIMXV2 stakeHolderContract) {

        bytes memory initData = abi.encodeWithSelector(
            StakeHolderWIMXV2.initialize.selector, 
            stakeHolderArgs.roleAdmin,
            stakeHolderArgs.upgradeAdmin,
            stakeHolderArgs.distributeAdmin,
            stakeHolderArgs.token);

        vm.startBroadcast(deploymentArgs.deployer);
        StakeHolderWIMXV2 impl = new StakeHolderWIMXV2();
        vm.stopBroadcast();
        vm.startBroadcast(deploymentArgs.deployer);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        vm.stopBroadcast();

        stakeHolderContract = StakeHolderWIMXV2(payable(address(proxy)));
    }

    function _stake(IStakeHolder _stakeHolder, address _staker, uint256 _amount) private {
        uint256 bal = _staker.balance;
        console.log("Balance is: %x", bal);
        console.log("Amount is: %x", _amount);
        if (bal < _amount) {
            revert("Insufficient balance");
        }

        vm.startBroadcast(_staker);
        _stakeHolder.stake{value: _amount} (_amount);
        vm.stopBroadcast();
    }

    function _unstake(IStakeHolder _stakeHolder, address _staker, uint256 _amount) private {
        vm.startBroadcast(_staker);
        _stakeHolder.unstake(_amount);
        vm.stopBroadcast();
    }

    function testComplex() external {
        /// @dev Fork the Immutable zkEVM testnet for this test
        string memory rpcURL = "https://rpc.testnet.immutable.com";
        vm.createSelectFork(rpcURL);

        address payable wimxOnTestnet = payable(address(0x1CcCa691501174B4A623CeDA58cC8f1a76dc3439));
        WIMX erc20 = WIMX(wimxOnTestnet);

        /// @dev These are Immutable zkEVM testnet values where necessary
        address immTestNetCreate3 = 0x37a59A845Bb6eD2034098af8738fbFFB9D589610;
        ComplexDeploymentArgs memory deploymentArgs = ComplexDeploymentArgs({
            signer: 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333,
            factory: immTestNetCreate3,
            salt: "salt"
        });

        address distributeAdmin = makeAddr("distribute");
        ComplexStakeHolderContractArgs memory stakeHolderArgs = 
            ComplexStakeHolderContractArgs({
                distributeAdmin: distributeAdmin,
                token: address(erc20)
            });

        uint256 delay = 604800; // 604800 seconds = 1 week
        address proposer = makeAddr("proposer");
        address executor = makeAddr("executor");

        ComplexTimelockContractArgs memory timelockArgs = 
            ComplexTimelockContractArgs({
                timeDelayInSeconds: delay,
                proposerAdmin: proposer,
                executorAdmin: executor
            });

        // Run deployment against forked testnet
        StakeHolderWIMXV2 stakeHolder;
        TimelockController timelockController;
        (stakeHolder, timelockController) = 
            _deployComplex(deploymentArgs, stakeHolderArgs, timelockArgs);

        _commonTest(true, IStakeHolder(stakeHolder), address(timelockController), 
            immTestNetCreate3, address(0), address(0), distributeAdmin);

        assertTrue(timelockController.hasRole(timelockController.PROPOSER_ROLE(), proposer), "Proposer not set correcrly");
        assertTrue(timelockController.hasRole(timelockController.EXECUTOR_ROLE(), executor), "Executor not set correcrly");
        assertEq(timelockController.getMinDelay(), delay, "Delay not set correctly");
    }

    function testSimple() external {
        /// @dev Fork the Immutable zkEVM testnet for this test
        string memory rpcURL = "https://rpc.testnet.immutable.com";
        vm.createSelectFork(rpcURL);

        address deployer = makeAddr("deployer");

        address payable wimxOnTestnet = payable(address(0x1CcCa691501174B4A623CeDA58cC8f1a76dc3439));
        WIMX erc20 = WIMX(wimxOnTestnet);

        /// @dev These are Immutable zkEVM testnet values where necessary
        SimpleDeploymentArgs memory deploymentArgs = SimpleDeploymentArgs({
            deployer: deployer
        });

        address roleAdmin = makeAddr("role");
        address upgradeAdmin = makeAddr("upgrade");
        address distributeAdmin = makeAddr("distribute");

        SimpleStakeHolderContractArgs memory stakeHolderContractArgs = 
            SimpleStakeHolderContractArgs({
                roleAdmin: roleAdmin,
                upgradeAdmin: upgradeAdmin,
                distributeAdmin: distributeAdmin,
                token: address(erc20)
            });

        // Run deployment against forked testnet
        StakeHolderWIMXV2 stakeHolder = _deploySimple(deploymentArgs, stakeHolderContractArgs);

        _commonTest(false, IStakeHolder(stakeHolder), address(0), 
           deployer, roleAdmin, upgradeAdmin, distributeAdmin);
    }

    function _commonTest(
            bool _isComplex, 
            IStakeHolder _stakeHolder, 
            address _timelockControl,
            address _deployer,
            address _roleAdmin,
            address _upgradeAdmin,
            address _distributeAdmin
            ) private {
        address roleAdmin = _isComplex ? _timelockControl : _roleAdmin;
        address upgradeAdmin = _isComplex ? _timelockControl : _upgradeAdmin;

        address tokenAddress = _stakeHolder.getToken();
        IERC20 erc20 = IERC20(tokenAddress);

        // Post deployment checks
        {
            StakeHolderWIMXV2 temp = new StakeHolderWIMXV2();
            bytes32 defaultAdminRole = temp.DEFAULT_ADMIN_ROLE();
            assertTrue(_stakeHolder.hasRole(_stakeHolder.UPGRADE_ROLE(), upgradeAdmin), "Upgrade admin should have upgrade role");
            assertTrue(_stakeHolder.hasRole(defaultAdminRole, roleAdmin), "Role admin should have default admin role");
            assertTrue(_stakeHolder.hasRole(_stakeHolder.DISTRIBUTE_ROLE(), _distributeAdmin), "Distribute admin should have distribute role");
            // The DEFAULT_ADMIN_ROLE should be revoked from the deployer account
            assertFalse(_stakeHolder.hasRole(defaultAdminRole, _deployer), "msg.sender should not be an admin");
        }

        address user1 = makeAddr("user1");
        vm.deal(user1, 100 ether);

        _stake(_stakeHolder, user1, 10 ether);

        assertEq(user1.balance, 90 ether, "User1 balance after stake");
        assertEq(erc20.balanceOf(address(_stakeHolder)), 10 ether, "StakeHolder balance after stake");

        _unstake(_stakeHolder, user1, 7 ether);
        assertEq(user1.balance, 97 ether, "User1 balance after unstake");
        assertEq(erc20.balanceOf(address(_stakeHolder)), 3 ether, "StakeHolder balance after unstake");
    }


    // *********************** UPGRADE TO V2 ***************************

    string constant MAINNET_RPC_URL = "https://rpc.immutable.com/";
    address constant STAKE_HOLDER_PROXY = 0xb6c2aA8690C8Ab6AC380a0bb798Ab0debe5C4C38;
    address constant TIMELOCK_CONTROLLER = 0x994a66607f947A47F33C2fA80e0470C03C30e289;
    bytes32 constant PROPOSER_ROLE = 0xb09aa5aeb3702cfd50b6b62bc4532604938f21248a27a1d5ca736082b6819cc1;
    bytes32 constant EXECUTOR_ROLE = 0xd8aa0f3194971a2a116679f7c2090f6939c8d4e01a2a8d7e41d55e5351469e63;
    
    // On mainnet Proposer and Execute are a GnosisSafeProxy.
    address constant PROPOSER = 0xaA53161A1fD22b258c89bA76B4bA11019034612D;
    address constant EXECUTOR = 0xaA53161A1fD22b258c89bA76B4bA11019034612D;
    uint256 constant TIMELOCK_DELAY = 604800;

    address constant DEPLOYER_ADDRESS = 0xdDA0d9448Ebe3eA43aFecE5Fa6401F5795c19333;
    address constant OWNABLE_CREATE3_FACTORY = 0x37a59A845Bb6eD2034098af8738fbFFB9D589610;

    address constant STAKE_HOLDER_V2 = address(0x123);

    TimelockController stakeHolderTimeDelay = TimelockController(payable(TIMELOCK_CONTROLLER));


    function deployV2() external {
        address stakeHolderV2 = _deployV2();
        console.log("Deployed StakeHolderWIMXV2 to: %s", stakeHolderV2);
    }

    function proposeUpgradeToV2() external {
        _proposeUpgradeToV2(STAKE_HOLDER_V2);
    }

    function executeUpgradeToV2() external {
        _executeUpgradeToV2(STAKE_HOLDER_V2);
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

    function _proposeUpgradeToV2(address _v2Impl) internal {
        assertTrue(stakeHolderTimeDelay.hasRole(PROPOSER_ROLE, PROPOSER), "Proposer does not have proposer role");
        assertTrue(stakeHolderTimeDelay.hasRole(EXECUTOR_ROLE, EXECUTOR), "Executor does not have executor role");

        (address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) = 
            _getProposalParams(_v2Impl);

        vm.startBroadcast(PROPOSER);
        stakeHolderTimeDelay.schedule(target, value, data, predecessor, salt, TIMELOCK_DELAY);
        vm.stopBroadcast();
    }

    function _executeUpgradeToV2(address _v2Impl) internal {
        stakeHolderTimeDelay = TimelockController(payable(TIMELOCK_CONTROLLER));
        assertTrue(stakeHolderTimeDelay.hasRole(EXECUTOR_ROLE, EXECUTOR), "Executor does not have executor role");

        (address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) = 
            _getProposalParams(_v2Impl);

        bytes32 id = stakeHolderTimeDelay.hashOperation(target, value, data, predecessor, salt);
        assertTrue(stakeHolderTimeDelay.isOperationReady(id), "Operation is not yet ready");

        vm.startBroadcast(EXECUTOR);
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
        if (stakeHolderV2 == address(0)) {
            // StakeHolderWIMXV2 has not been deployed yet.
            stakeHolderV2 = _deployV2();
        }

        (address target, uint256 value, bytes memory data, bytes32 predecessor, bytes32 salt) = 
            _getProposalParams(stakeHolderV2);
        bytes32 id = stakeHolderTimeDelay.hashOperation(target, value, data, predecessor, salt);
        if (!stakeHolderTimeDelay.isOperation(id)) {
            // The upgrade hasn't been proposed yet.
            _proposeUpgradeToV2(stakeHolderV2);
        }

        uint256 earliestExecuteTime = stakeHolderTimeDelay.getTimestamp(id);
        uint256 time = earliestExecuteTime;
        if (time < block.timestamp) {
            time = block.timestamp;
        }
        vm.warp(time);

        uint256 numStakersBefore = stakeHolder.getNumStakers();
        _executeUpgradeToV2(stakeHolderV2);
        uint256 numStakersAfter = stakeHolder.getNumStakers();
        assertEq(numStakersBefore, numStakersAfter, "Number of stakers before and after upgrade do not match");
    }
}
