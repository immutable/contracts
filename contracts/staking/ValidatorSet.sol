// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";



/**
 * @dev This contract is upgradeable.
 */
contract ValidatorSet is  AccessControlEnumerableUpgradeable {
    struct ValidatorInfo {
        // Used for adding and removing stake and paying block rewards to.
        address stakingAccount;
        // BLS public key used for RanDAO.
        bytes blsPublicKey;
        // Block number of last block produced by this validator.
        uint256 lastTimeBlockProducer;
        // Index into validators array.
        uint256 index;
    }


    error ValidatorNodeAlreadyAdded(address _nodeAccount);
    error StakerForOtherValidator(address _stakingAccount);
    error StakerNotConfigured(address _stakingAccount);
    error MustHaveAtLeastOneValidator(address _stakingAccount);
    error BlockRewardAlreadyPaid(uint256 _blockNumber);



    // Code and storage layout version number.
    uint256 internal constant VERSION0 = 0;

    /// @notice Only accounts with UPGRADE_ADMIN_ROLE can upgrade the contract.
    bytes32 private constant UPGRADE_ADMIN_ROLE = bytes32("UPGRADE_ROLE");

    // Number of blocks per epoch.
    uint256 private constant BLOCKS_PER_EPOCH = 300; 



    // @notice The version of the storage layout.
    // @dev This storage slot will be used during upgrades.
    uint256 public version;


    // Mapping node validator's node address => Validator Info.
    mapping (address nodeAddress => ValidatorInfo info) public validatorSetByValidatorAccount;

    // Mapping validator's staking account => validator's node address.
    mapping (address => address) public validatorSetByStakingAccount;

    address[] public validators;

    // The last block that block rewards were paid out on. Ensures block rewards are not paid 
    // out twice on the same block.
    uint256 public blockNumberBlockRewardPaidUpTo;

    // Block rewards yet to be paid out.
    mapping (address => uint256) public pendingBlockRewards;



    /**
     * @notice Initialize the contract for use with a transparent proxy.
     * @param _roleAdmin is the account that can add and remove addresses that have
     *        RANDOM_ADMIN_ROLE privilege.
     * @param _upgradeAdmin is the account that has UPGRADE_ADMIN_ROLE privilege.
     */
    function initialize(
        address _roleAdmin,
        address _upgradeAdmin
    ) public virtual initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(UPGRADE_ADMIN_ROLE, _upgradeAdmin);

        version = VERSION0;
    }



    /**
     * @notice Called during contract upgrade.
     * @dev This function will be overridden in future versions of this contract.
     */
    function upgrade(bytes calldata /* data */) external virtual {
        // Revert in the following situations:
        // - The function is called on the existing version.
        // - This version of code is mistakenly deploy, for an upgrade from V2 to V3.
        //   That is, we mistakenly attempt to downgrade the contract.
        revert CanNotUpgradeFrom(version, VERSION0);
    }



    // TODO only validator controller
    // Staking account same on all chains
    // Node account different on all chains.
    function addValidator(address _nodeAccount, address _stakingAccount, bytes calldata _blsPublicKey) external {
        if (validatorSetByValidatorAccount[_nodeAccount].stakingAccount != address(0)) {
            revert ValidatorNodeAlreadyAdded(_nodeAccount);
        }
        if (validatorSetByStakingAccount[_stakingAccount] != address(0)) {
            revert StakerForOtherValidator(_stakingAccount);
        }

        ValidatorInfoBFT storage valInfo = validatorSetByValidatorAccount[_nodeAccount];
        valInfo.stakingAccount = _stakingAccount;
        valInfo.blsPublicKey = _blsPublicKey;
        valInfo.lastTimeBlockProducer = block.number;
        valInfo.index = validators.length;
        validators.push(_nodeAccount);
    }

    // TODO only validator controller.
    function removeValidator(address _stakingAccount) external {
        uint256 numValidators = validators.length;
        if (numValidators == 1) {
            revert MustHaveAtLeastOneValidator(_stakingAccount);
        }

        address nodeAccount = validatorSetByStakingAccount[_stakingAccount];
        if (nodeAccount == address(0)) {
            revert StakerNotConfigured(_stakingAccount);
        }

        validatorSetByStakingAccount[_stakingAccount] = address(0);
        ValidatorInfoBFT storage info = validatorSetByValidatorAccount[nodeAccount];
        info.stakingAccount = address(0);

        uint256 index = info.index;
        if (index != numValidators - 1) {
            validators[index] = validators[numValidators - 1];
        }
        validators.pop();
    }


   function payBlockReward() external {
        if (blockNumberBlockRewardPaidUpTo == block.number) {
            revert BlockRewardAlreadyPaid(block.number);
        }
        // Indicate the block reward has been paid. 
        // Setting this here also acts as re-entrancy protection.
        blockNumberBlockRewardPaidUpTo = block.number;

        // Determine the staker account associated with the validator node account.
        address staker = validatorSetByValidatorAccount[block.coinbase].stakingAccount;

        // Pay the block reward.
        // TODO use the formula
        // TODO handle multi-ERC 20 block rewards
        uint256 amount = 1000;
        pendingBlockRewards[staker] += amount;

        // Update when this validator produced its more recent block.
        validatorSetByValidatorAccount[block.coinbase].lastTimeBlockProducer = block.number;
    }

    // TODO handle multi-ERC 20 block rewards
    function withdrawBlockRewards() external {
        uint256 amount = pendingBlockRewards[msg.sender];
        // Zero before sending to prevent re-entrancy attacks.
        pendingBlockRewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }



    function getValidators() override external view returns (address[] memory) {
        return validators;
    }

    /**
     * @notice Check that msg.sender is authorised to perform the contract upgrade.
     */
    // solhint-disable no-empty-blocks
    function _authorizeUpgrade(
        address newImplementation
    ) internal override(UUPSUpgradeable) onlyRole(UPGRADE_ADMIN_ROLE) {
        // Nothing to do beyond upgrade authorisation check.
    }
    // solhint-enable no-empty-blocks

    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapValidatorSet;
}