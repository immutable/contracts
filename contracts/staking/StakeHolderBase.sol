// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.19 <0.8.29;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/security/ReentrancyGuardUpgradeable.sol";
import {IStakeHolder} from "./IStakeHolder.sol";
import {StakeHolderBase} from "./StakeHolderBase.sol";

/**
 * @title StakeHolderBase: allows anyone to stake any amount of an ERC20 token and to then remove all or part of that stake.
 * @dev The StakeHolderERC20 contract is designed to be upgradeable.
 */
abstract contract StakeHolderBase is IStakeHolder, AccessControlEnumerableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    /// @notice Only UPGRADE_ROLE can upgrade the contract
    bytes32 public constant UPGRADE_ROLE = bytes32("UPGRADE_ROLE");

    /// @notice Only DISTRIBUTE_ROLE can call the distribute function
    bytes32 public constant DISTRIBUTE_ROLE = bytes32("DISTRIBUTE_ROLE");

    /// @notice Version 0 version number
    uint256 internal constant _VERSION0 = 0;

    /// @notice Holds staking information for a single staker.
    struct StakeInfo {
        /// @notice Amount of stake.
        uint256 stake;
        /// @notice True if this account has ever staked.
        bool hasStaked;
    }

    /// @notice The amount of value owned by each staker
    // solhint-disable-next-line private-vars-leading-underscore
    mapping(address staker => StakeInfo stakeInfo) internal balances;

    /// @notice A list of all stakers who have ever staked.
    /// @dev The list make contain stakers who have completely unstaked (that is, have
    ///    a balance of 0). This array is never re-ordered. As such, off-chain services
    ///    could cache the results of getStakers().
    // solhint-disable-next-line private-vars-leading-underscore
    address[] internal stakers;

    /// @notice version number of the storage variable layout.
    uint256 public version;

    /**
     * @notice Initialises the upgradeable contract, setting up admin accounts.
     * @param _roleAdmin the address to grant `DEFAULT_ADMIN_ROLE` to
     * @param _upgradeAdmin the address to grant `UPGRADE_ROLE` to
     * @param _distributeAdmin the address to grant `DISTRIBUTE_ROLE` to
     */
    function __StakeHolderBase_init(
        address _roleAdmin,
        address _upgradeAdmin,
        address _distributeAdmin
    ) internal {
        __UUPSUpgradeable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(UPGRADE_ROLE, _upgradeAdmin);
        _grantRole(DISTRIBUTE_ROLE, _distributeAdmin);
        version = _VERSION0;
    }

    /**
     * @notice Function to be called when upgrading this contract.
     * @dev Call this function as part of upgradeToAndCall().
     *      This initial version of this function reverts. There is no situation
     *      in which it makes sense to upgrade to the V0 storage layout.
     *      Note that this function is permissionless. Future versions must
     *      compare the code version and the storage version and upgrade
     *      appropriately. As such, the code will revert if an attacker calls
     *      this function attempting a malicious upgrade.
     * @ param _data ABI encoded data to be used as part of the contract storage upgrade.
     */
    function upgradeStorage(bytes memory /* _data */) external virtual {
        revert CanNotUpgradeToLowerOrSameVersion(version);
    }


    /**
     * @inheritdoc IStakeHolder
     */
    function getBalance(address _account) external view override (IStakeHolder) returns (uint256 _balance) {
        return balances[_account].stake;
    }

    /**
     * @inheritdoc IStakeHolder
     */
    function hasStaked(address _account) external view override (IStakeHolder) returns (bool _everStaked) {
        return balances[_account].hasStaked;
    }

    /**
     * @inheritdoc IStakeHolder
     */
    function getNumStakers() external view override (IStakeHolder) returns (uint256 _len) {
        return stakers.length;
    }

    /**
     * @inheritdoc IStakeHolder
     */
    function getStakers(
        uint256 _startOffset,
        uint256 _numberToReturn
    ) external view override (IStakeHolder) returns (address[] memory _stakers) {
        address[] memory stakerPartialArray = new address[](_numberToReturn);
        for (uint256 i = 0; i < _numberToReturn; i++) {
            stakerPartialArray[i] = stakers[_startOffset + i];
        }
        return stakerPartialArray;
    }

    // Override the _authorizeUpgrade function
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADE_ROLE) {}

    /**
     * @notice Prevent revoke or renounce role for the last DEFAULT_ADMIN_ROLE / the last role admin.
     * @param _role The role to be renounced.
     * @param _account Account to be revoked.
     */
    function _revokeRole(bytes32 _role, address _account) internal override {
        if (_role == DEFAULT_ADMIN_ROLE && getRoleMemberCount(_role) == 1) {
            revert MustHaveOneRoleAdmin();
        }
        super._revokeRole(_role, _account);
    }

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StakeHolderBaseGap;
    // slither-disable-end unused-state
}
