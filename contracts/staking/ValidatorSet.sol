// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";

/**
 * @dev This contract is upgradeable.
 */
contract ValidatorSet is AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    error CanNotUpgradeFrom(uint256 _newVersion, uint256 _currentVersion);
    error ValidatorNodeAlreadyAdded(address _nodeAccount);
    error StakerForOtherValidator(address _stakingAccount);
    error StakerNotConfigured(address _stakingAccount);
    error MustHaveAtLeastOneValidator(address _stakingAccount);
    error BlockRewardAlreadyPaid(uint256 _blockNumber);

    /**
     * @notice This structure is indexed per nodeAccount.
     * @dev For a single multi-chain validator, the nodeAccount and blsPublicKey
     *      are different on each chain, and the stakingAccount is the same
     *      across all chains.
     */
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

    // Code and storage layout version number.
    uint256 internal constant VERSION0 = 0;

    /// @notice Only accounts with UPGRADE_ADMIN_ROLE can upgrade the contract.
    bytes32 private constant UPGRADE_ADMIN_ROLE = bytes32("UPGRADE_ROLE");

    /// @notice Only accounts with VALIDATOR_ADMIN_ROLE can add and remove validators.
    bytes32 private constant VALIDATOR_ADMIN_ROLE = bytes32("VALIDATOR_ROLE");

    // Number of blocks per epoch.
    uint256 private constant BLOCKS_PER_EPOCH = 300;

    // @notice The version of the storage layout.
    // @dev This storage slot will be used during upgrades.
    uint256 public version;

    // Mapping node validator's node address => Validator Info.
    mapping(address nodeAddress => ValidatorInfo info) public validatorSetByValidatorAccount;

    // Mapping validator's staking account => validator's node address.
    mapping(address stakingAddress => address nodeAddress) public validatorSetByStakingAccount;

    address[] public validatorsCurrentEpoch;
    address[] public validatorsNextEpoch;
    uint256 public nextEpochStart;

    // The last block that block rewards were paid out on. Ensures block rewards are not paid
    // out twice on the same block.
    uint256 public blockNumberBlockRewardPaidUpTo;

    // Block rewards yet to be paid out.
    mapping(address stakingAddress => uint256 amount) public pendingBlockRewards;

    // Record of the previous RAN DAO values for each block.
    mapping(uint256 blockNumber => uint256 prevRanDao) public prevRanDao;

    /**
     * @notice Initialize the contract for use with a transparent proxy.
     * @param _roleAdmin is the account that can add and remove addresses that have
     *        RANDOM_ADMIN_ROLE privilege.
     * @param _upgradeAdmin is the account that has UPGRADE_ADMIN_ROLE privilege.
     */
    function initialize(address _roleAdmin, address _upgradeAdmin, address _validatorAdmin) public virtual initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(UPGRADE_ADMIN_ROLE, _upgradeAdmin);
        _grantRole(VALIDATOR_ADMIN_ROLE, _validatorAdmin);

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

    /**
     * @notice Add a validator it the validator set at the start of the next epoch.
     *
     * @param _nodeAccount Account for verifying P2P signatures for node identification and consensus.
     * @param _stakingAccount Used for staking and access control to fetch rewards.
     * @param _blsPublicKey Used for RAN DAO.
     */
    function addValidator(
        address _nodeAccount,
        address _stakingAccount,
        bytes calldata _blsPublicKey
    ) external onlyRole(VALIDATOR_ADMIN_ROLE) {
        if (validatorSetByValidatorAccount[_nodeAccount].stakingAccount != address(0)) {
            revert ValidatorNodeAlreadyAdded(_nodeAccount);
        }
        if (validatorSetByStakingAccount[_stakingAccount] != address(0)) {
            revert StakerForOtherValidator(_stakingAccount);
        }

        ValidatorInfo storage valInfo = validatorSetByValidatorAccount[_nodeAccount];
        valInfo.stakingAccount = _stakingAccount;
        valInfo.blsPublicKey = _blsPublicKey;
        valInfo.lastTimeBlockProducer = block.number;
        valInfo.index = validatorsNextEpoch.length;

        validatorSetByStakingAccount[_stakingAccount] = _nodeAccount;

        updateValidatorSetForEpoch();
        // Add the validator from the list for next epoch.
        validatorsNextEpoch.push(_nodeAccount);
    }

    /**
     * @notice Remove a validator from the validator set for the next epoch.
     * @param _stakingAccount The staking account for a validator.
     */
    function removeValidator(address _stakingAccount) external onlyRole(VALIDATOR_ADMIN_ROLE) {
        uint256 numValidators = validatorsNextEpoch.length;
        if (numValidators == 1) {
            revert MustHaveAtLeastOneValidator(_stakingAccount);
        }

        address nodeAccount = validatorSetByStakingAccount[_stakingAccount];
        if (nodeAccount == address(0)) {
            revert StakerNotConfigured(_stakingAccount);
        }

        validatorSetByStakingAccount[_stakingAccount] = address(0);
        ValidatorInfo storage info = validatorSetByValidatorAccount[nodeAccount];
        info.stakingAccount = address(0);

        updateValidatorSetForEpoch();
        // Remove the validator from the list for next epoch.
        uint256 index = info.index;
        if (index != numValidators - 1) {
            validatorsNextEpoch[index] = validatorsNextEpoch[numValidators - 1];
        }
        validatorsNextEpoch.pop();
    }

    /**
     * @notice Function to be called once per block to pay block rewards for this block.
     * @dev This function has some secondary purposes:
     *      - Records the last time a validator produced a block. This will be used in slashing.
     *      - Records the Prev RAN DAO value for the block. This is used by the on-chain random system.
     */
    function payBlockReward() external {
        if (blockNumberBlockRewardPaidUpTo == block.number) {
            revert BlockRewardAlreadyPaid(block.number);
        }
        // Indicate the block reward has been paid.
        // Setting this here also acts as re-entrancy protection.
        blockNumberBlockRewardPaidUpTo = block.number;

        // Determine the staker account associated with the validator node account.
        address staker = validatorSetByValidatorAccount[block.coinbase].stakingAccount;

        // Pay the block reward. For the moment, this is zero, and native IMX only.
        pendingBlockRewards[staker] += 0;

        // Update when this validator produced its most recent block. This information
        // could in future be used for slashing.
        validatorSetByValidatorAccount[block.coinbase].lastTimeBlockProducer = block.number;

        // Record the prevrandao for this block.
        prevRanDao[block.number] = block.prevrandao;
    }

    /**
     * @notice For the moment, block rewards are native IMX only.
     */
    function withdrawBlockRewards() external {
        uint256 amount = pendingBlockRewards[msg.sender];
        // Zero before sending to prevent re-entrancy attacks.
        pendingBlockRewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /**
     * @notice Get the node addresses of the validator set for the current epoch.
     * @return Validator set for current epoch.
     */
    function getValidators() external view returns (address[] memory) {
        // If no validators have been added or removed since the start of
        // nextEpochStart, then validatorsNextEpoch is the current validator set.
        if (block.number < nextEpochStart) {
            return validatorsCurrentEpoch;
        } else {
            return validatorsNextEpoch;
        }
    }

    /**
     * @notice Return the block number of the start of the next epoch.
     */
    function getStartNextEpoch() public view returns (uint256) {
        uint256 epoch = block.number / BLOCKS_PER_EPOCH;
        return (epoch + 1) * BLOCKS_PER_EPOCH;
    }

    /**
     * @notice When the validator set changes, first update the current validator set.
     */
    function updateValidatorSetForEpoch() private {
        if (block.number >= nextEpochStart) {
            delete validatorsCurrentEpoch;
            uint256 len = validatorsNextEpoch.length;
            for (uint256 i = 0; i < len; i++) {
                validatorsCurrentEpoch[i] = validatorsNextEpoch[i];
            }
            nextEpochStart = getStartNextEpoch();
        }
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
