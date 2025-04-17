// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";
import {ERC20PresetFixedSupply} from "openzeppelin-contracts-4.9.3/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import {IERC20} from "openzeppelin-contracts-4.9.3/token/ERC20/IERC20.sol";

import {IStakeHolder} from "../../contracts/staking/IStakeHolder.sol";
import {StakeHolderERC20} from "../../contracts/staking/StakeHolderERC20.sol";

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
contract StakeHolderScript is Test {
    /**
     * Deploy StakeHolderERC20 using Create3, with the TimelockController.
     */
    function deployComplex() external {
        address signer = vm.envAddress("DEPLOYER_ADDRESS");
        address factory = vm.envAddress("OWNABLE_CREATE3_FACTORY_ADDRESS");
        address distributeAdmin = vm.envAddress("DISTRIBUTE_ADMIN");
        address token = vm.envAddress("ERC20_STAKING_TOKEN");
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
     * Deploy StakeHolderERC20 using an EOA.
     */
    function deploySimple() external {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address roleAdmin = vm.envAddress("ROLE_ADMIN");
        address upgradeAdmin = vm.envAddress("UPGRADE_ADMIN");
        address distributeAdmin = vm.envAddress("DISTRIBUTE_ADMIN");
        address token = vm.envAddress("ERC20_STAKING_TOKEN");

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
     * Deploy StakeHolderERC20 using Create3, with the TimelockController.
     */
    function _deployComplex(
        ComplexDeploymentArgs memory deploymentArgs, 
        ComplexStakeHolderContractArgs memory stakeHolderArgs,
        ComplexTimelockContractArgs memory timelockArgs)
        private
        returns (StakeHolderERC20 stakeHolderContract, TimelockController timelockController)
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


        // Deploy StakeHolderERC20 via the Ownable Create3 factory.
        // Create deployment bytecode and encode constructor args
        deploymentBytecode = abi.encodePacked(
            type(StakeHolderERC20).creationCode
        );
        /// @dev Deploy the contract via the Ownable CREATE3 factory
        vm.startBroadcast(deploymentArgs.signer);
        address stakeHolderImplAddress = ownableCreate3.deploy(deploymentBytecode, salt2);
        vm.stopBroadcast();

        // Deploy ERC1967Proxy via the Ownable Create3 factory.
        // Create init data for the ERC1967 Proxy
        bytes memory initData = abi.encodeWithSelector(
            StakeHolderERC20.initialize.selector, 
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

        stakeHolderContract = StakeHolderERC20(stakeHolderContractAddress);
        timelockController = TimelockController(payable(timelockAddress));
    }

    /**
     * Deploy StakeHolderERC20 using an EOA and no time lock.
     */
    function _deploySimple(
        SimpleDeploymentArgs memory deploymentArgs, 
        SimpleStakeHolderContractArgs memory stakeHolderArgs)
        private
        returns (StakeHolderERC20 stakeHolderContract) {

        bytes memory initData = abi.encodeWithSelector(
            StakeHolderERC20.initialize.selector, 
            stakeHolderArgs.roleAdmin,
            stakeHolderArgs.upgradeAdmin,
            stakeHolderArgs.distributeAdmin,
            stakeHolderArgs.token);

        vm.startBroadcast(deploymentArgs.deployer);
        StakeHolderERC20 impl = new StakeHolderERC20();
        vm.stopBroadcast();
        vm.startBroadcast(deploymentArgs.deployer);
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);
        vm.stopBroadcast();

        stakeHolderContract = StakeHolderERC20(address(proxy));
    }

    function _stake(IStakeHolder _stakeHolder, address _staker, uint256 _amount) private {
        address tokenAddress = _stakeHolder.getToken();
        IERC20 erc20 = IERC20(tokenAddress);

        uint256 bal = erc20.balanceOf(_staker);
        if (bal < _amount) {
            revert("Insufficient balance");
        }

        vm.startBroadcast(_staker);
        erc20.approve(address(_stakeHolder), _amount);
        _stakeHolder.stake(_amount);
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

        address bank = makeAddr("bank");
        vm.startBroadcast(bank);
        ERC20PresetFixedSupply erc20 = 
            new ERC20PresetFixedSupply("Name", "SYM", 1000 ether, bank);
        vm.stopBroadcast();

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
        StakeHolderERC20 stakeHolder;
        TimelockController timelockController;
        (stakeHolder, timelockController) = 
            _deployComplex(deploymentArgs, stakeHolderArgs, timelockArgs);

        _commonTest(true, IStakeHolder(stakeHolder), address(timelockController), 
            bank, immTestNetCreate3, address(0), address(0), distributeAdmin);

        assertTrue(timelockController.hasRole(timelockController.PROPOSER_ROLE(), proposer), "Proposer not set correcrly");
        assertTrue(timelockController.hasRole(timelockController.EXECUTOR_ROLE(), executor), "Executor not set correcrly");
        assertEq(timelockController.getMinDelay(), delay, "Delay not set correctly");
    }

    function testSimple() external {
        /// @dev Fork the Immutable zkEVM testnet for this test
        string memory rpcURL = "https://rpc.testnet.immutable.com";
        vm.createSelectFork(rpcURL);

        address deployer = makeAddr("deployer");
        address bank = makeAddr("bank");

        vm.startBroadcast(deployer);
        ERC20PresetFixedSupply erc20 = 
            new ERC20PresetFixedSupply("Name", "SYM", 1000 ether, bank);
        vm.stopBroadcast();

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
        StakeHolderERC20 stakeHolder = _deploySimple(deploymentArgs, stakeHolderContractArgs);

        _commonTest(false, IStakeHolder(stakeHolder), address(0), 
           bank, deployer, roleAdmin, upgradeAdmin, distributeAdmin);
    }

    function _commonTest(
            bool _isComplex, 
            IStakeHolder _stakeHolder, 
            address _timelockControl,
            address _bank,
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
            StakeHolderERC20 temp = new StakeHolderERC20();
            bytes32 defaultAdminRole = temp.DEFAULT_ADMIN_ROLE();
            assertTrue(_stakeHolder.hasRole(_stakeHolder.UPGRADE_ROLE(), upgradeAdmin), "Upgrade admin should have upgrade role");
            assertTrue(_stakeHolder.hasRole(defaultAdminRole, roleAdmin), "Role admin should have default admin role");
            assertTrue(_stakeHolder.hasRole(_stakeHolder.DISTRIBUTE_ROLE(), _distributeAdmin), "Distribute admin should have distribute role");
            // The DEFAULT_ADMIN_ROLE should be revoked from the deployer account
            assertFalse(_stakeHolder.hasRole(defaultAdminRole, _deployer), "msg.sender should not be an admin");
        }

        address user1 = makeAddr("user1");
        vm.startBroadcast(_bank);
        erc20.transfer(user1, 100 ether);
        vm.stopBroadcast();

        _stake(_stakeHolder, user1, 10 ether);

        assertEq(erc20.balanceOf(user1), 90 ether, "User1 balance after stake");
        assertEq(erc20.balanceOf(address(_stakeHolder)), 10 ether, "StakeHolder balance after stake");

        _unstake(_stakeHolder, user1, 7 ether);
        assertEq(erc20.balanceOf(user1), 97 ether, "User1 balance after unstake");
        assertEq(erc20.balanceOf(address(_stakeHolder)), 3 ether, "StakeHolder balance after unstake");
    }
}
