// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {RandomSeedProviderRequestQueue} from "./RandomSeedProviderRequestQueue.sol";

import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";
import {IOffchainRandomSource} from "./offchainsources/IOffchainRandomSource.sol";

/**
 * @notice Contract to provide random seed values to game contracts on the chain.
 * @dev    The expectation is that there will only be one RandomSeedProvider per chain.
 *         Game contracts will call this contract to obtain a seed value, from which
 *         they will generate random values.
 *
 *         The contract is upgradeable. It is expected to be operated behind an
 *         Open Zeppelin ERC1967Proxy.
 */
contract RandomSeedProvider is AccessControlEnumerableUpgradeable, UUPSUpgradeable, RandomSeedProviderRequestQueue {
    /// @notice Indicate that the requested upgrade is not possible.
    error CanNotUpgradeFrom(uint256 _storageVersion, uint256 _codeVersion);

    /// @notice The random seed value is not yet available.
    error WaitForRandom(uint256 _fulfillmentId);

    /// @notice The generation process has failed. The caller will need to submit a new request.
    error GenerationFailedTryAgain(uint256 _fulfillmentId);

    //// @notice Prevent the on-chain delay from being set to values that will cause issues.
    error InvalidOnchainDelay(uint256 _proposedDelay);

    /// @notice A seed could not be generate for a block because too long had elapsed between 
    /// requesting and a call to getRandomSeed or generateNextSeedOnChain.
    event TooLateToGenerateRandom(uint256 _blockNumber);

    /// @notice The off-chain random source has been updated.
    event OffchainRandomSourceSet(address _offchainRandomSource);

    /// @notice Changes the on chain source delay between requesting and fulfilling.
    event OnChainDelaySet(uint256 _onChainDelay);

    /// @notice Indicates that a game contract that can consume off-chain random has been added.
    event OffchainRandomConsumerAdded(address _consumer);

    /// @notice Indicates that a game contract that can consume off-chain random has been removed.
    event OffchainRandomConsumerRemoved(address _consumer);

    /// @notice Status of a seed request
    enum SeedRequestStatus {
        // The seed is being produced.
        IN_PROGRESS,
        // The seed is ready to be fetched.
        READY,
        // The seed generation process has failed.
        FAILED
    }


    // Code and storage layout version number.
    uint256 internal constant VERSION0 = 0;

    /// @notice Admin role that can configure on chain delay and enable off-chain random sources.
    bytes32 private constant RANDOM_ADMIN_ROLE = keccak256("RANDOM_ADMIN_ROLE");

    /// @notice Only accounts with UPGRADE_ADMIN_ROLE can upgrade the contract.
    bytes32 private constant UPGRADE_ADMIN_ROLE = bytes32("UPGRADE_ROLE");

    /// @notice Indicates: Generate new random numbers using on-chain methodology.
    address private constant ONCHAIN = address(1);

    // @notice The version of the storage layout.
    // @dev This storage slot will be used during upgrades.
    uint256 public version;

    /// @notice All historical random output.
    /// @dev When random seeds are requested, a request id is returned. The id
    /// @dev relates to a certain future random seed. This map holds all of the
    /// @dev random seeds that have been produced.
    mapping(uint256 requestId => bytes32 randomValue) public randomOutput;

    /// @notice The block when the last off-chain random request occurred.
    /// @dev This is used to limit off-chain random requests to once per block.
    uint256 private lastBlockOffchainRequest;

    /// @notice The request id returned in the previous off-chain random request.
    /// @dev This is used to limit off-chain random requests to once per block.
    uint256 private prevOffchainRandomRequest;

    /// @notice The source of new random numbers. This could be the special value ONCHAIN
    /// @notice or the address of a Offchain Random Source contract.
    /// @dev This value is return with the request ids. This allows off-chain random sources
    /// @dev to be switched without stopping in-flight random values from being retrieved.
    address public randomSource;

    /// @notice Delay between requesting a random number and fulfilling it.
    uint256 public onChainDelay;

    /// @notice Indicates an address is allow listed for the off-chain random provider.
    /// @dev Having an allow list prevents spammers from requesting one random number per block,
    /// @dev thus incurring cost on Immutable for no benefit.
    mapping(address gameContract => bool approved) public approvedForOffchainRandom;


    /**
     * @notice Initialize the contract for use with a transparent proxy.
     * @param _roleAdmin is the account that can add and remove addresses that have
     *        RANDOM_ADMIN_ROLE privilege.
     * @param _randomAdmin is the account that has RANDOM_ADMIN_ROLE privilege.
     * @param _upgradeAdmin is the account that has UPGRADE_ADMIN_ROLE privilege.
     */
    function initialize(
        address _roleAdmin,
        address _randomAdmin,
        address _upgradeAdmin
    ) public virtual initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(RANDOM_ADMIN_ROLE, _randomAdmin);
        _grantRole(UPGRADE_ADMIN_ROLE, _upgradeAdmin);

        initializeRandomSeedProviderRequestQueue();

        randomSource = ONCHAIN;
        onChainDelay = 2; // 2 blocks.

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
     * @notice Change the off-chain random source.
     * @dev Only RANDOM_ADMIN_ROLE can do this.
     * @param _offchainRandomSource Address of contract that is an off-chain random source.
     */
    function setOffchainRandomSource(address _offchainRandomSource) external onlyRole(RANDOM_ADMIN_ROLE) {
        // slither-disable-next-line missing-zero-check
        randomSource = _offchainRandomSource;
        emit OffchainRandomSourceSet(_offchainRandomSource);
    }

    /**
     * @notice Call this to configure the number of blocks between requests and fulfillment.
     * @dev Only RANDOM_ADMIN_ROLE can do this.
     * @param _onChainDelay For the on-chain source, this is the number of blocks between the request
     *       and the block that the block hash is used for. If this is set to 2 blocks then:
     *       current block number + 0: The block the player requested the seed in.
     *       current block number + 2: This block's block hash is used as entropy.
     *       current block number + 3: The value can be generated based on the request.
     */
    function setOnChainDelay(uint256 _onChainDelay) external onlyRole(RANDOM_ADMIN_ROLE) {
        // A delay of 0 would be mean using the block hash for the block that the player requested
        // the random seed in. This would not be secure as the player could observe the 
        // transaction pool, see the previous block's block hash, and attempt to determine
        // a range of likely block hashes. They could then alter their transaction, in an 
        // attempt of generating a block hash that is favourable to them.
        // 30 x 2 second block time would mean a one minute delay between requests and 
        // fulfillment. This seems like a large maximum value.
        if (_onChainDelay == 0 || _onChainDelay > 30) {
            revert InvalidOnchainDelay(_onChainDelay);
        }
        onChainDelay = _onChainDelay;
        emit OnChainDelaySet(_onChainDelay);
    }

    /**
     * @notice Add a consumer that can use off-chain supplied random.
     * @dev Only RANDOM_ADMIN_ROLE can do this.
     * @param _consumer Game contract that inherits from RandomValues.sol that is authorised to use off-chain random.
     */
    function addOffchainRandomConsumer(address _consumer) external onlyRole(RANDOM_ADMIN_ROLE) {
        approvedForOffchainRandom[_consumer] = true;
        emit OffchainRandomConsumerAdded(_consumer);
    }

    /**
     * @notice Remove a consumer that can use off-chain supplied random.
     * @dev Only RANDOM_ADMIN_ROLE can do this.
     * @param _consumer Game contract that inherits from RandomValues.sol that is no longer authorised to use off-chain random.
     */
    function removeOffchainRandomConsumer(address _consumer) external onlyRole(RANDOM_ADMIN_ROLE) {
        approvedForOffchainRandom[_consumer] = false;
        emit OffchainRandomConsumerRemoved(_consumer);
    }

    /**
     * @notice Request the index number to track when a random number will be produced.
     * @dev Note that the same _randomFulfilmentIndex will be returned to multiple games and even within
     * @dev the one game. Games must personalise this value to their own game, the particular game player,
     * @dev and to the game player's request.
     * @return _randomFulfilmentIndex The index for the game contract to present to fetch the next random value.
     * @return _randomSource Indicates that an on-chain source was used, or is the address of an off-chain source.
     */
    // slither-disable-next-line reentrancy-benign, reentrancy-no-eth
    function requestRandomSeed() external returns (uint256 _randomFulfilmentIndex, address _randomSource) {
        if (randomSource == ONCHAIN || !approvedForOffchainRandom[msg.sender]) {
            _randomFulfilmentIndex = block.number + onChainDelay;
            enqueueIfUnique(_randomFulfilmentIndex);
            _randomSource = ONCHAIN;
        } else {
            // Limit how often off-chain random numbers are requested to a maximum of once per block.
            // slither-disable-next-line incorrect-equality
            if (lastBlockOffchainRequest == block.number) {
                _randomFulfilmentIndex = prevOffchainRandomRequest;
            } else {
                lastBlockOffchainRequest = block.number;
                _randomFulfilmentIndex = IOffchainRandomSource(randomSource).requestOffchainRandom();
                prevOffchainRandomRequest = _randomFulfilmentIndex;
            }
            _randomSource = randomSource;
        }
    }

    /**
     * @notice Fetches a random seed value that was requested using the requestRandomSeed function.
     * @dev Note that the same _randomSeed will be returned to multiple games and even within
     * @dev the one game. Games must personalise this value to their own game, the particular game player,
     * @dev and to the game player's request.
     * @param _randomFulfilmentIndex Index indicating which random seed to return.
     * @param _randomSource The source to use when retrieving the random seed.
     * @return _randomSeed The value from which random values can be derived.
     */
    function getRandomSeed(
        uint256 _randomFulfilmentIndex,
        address _randomSource
    ) external returns (bytes32 _randomSeed) {
        if (_randomSource == ONCHAIN) {
            if (_randomFulfilmentIndex >= block.number) {
                revert WaitForRandom(_randomFulfilmentIndex);
            }
            bytes32 output = randomOutput[_randomFulfilmentIndex];
            if (output != bytes32(0)) {
                return output;
            }
            output = generateSeedOnChain(_randomFulfilmentIndex);
            randomOutput[_randomFulfilmentIndex] = output;
            return output;
        } else {
            // If random source is not the address of a valid contract this will revert
            // with no revert information returned.
            return IOffchainRandomSource(_randomSource).getOffchainRandom(_randomFulfilmentIndex);
        }
    }

    /**
     * @notice Generate a set of random values using on-chain methodologies.
     * @dev Either this function or getRandomSeed need to be called within 255 blocks
     *      of requestRandomSeed being called.
     */
    function processOnChainGenerationQueue() public {
        (uint256[] memory blockNumbers, uint256 lenUsed) = dequeueHistoricBlockNumbers();
        for (uint256 i = 0; i < lenUsed; i++) {
            uint256 blockNumber = blockNumbers[i];
            if (blockNumber + 256 < block.number) {
                emit TooLateToGenerateRandom(blockNumber);
                continue;
            }

            randomOutput[blockNumber] = generateEntropy(blockNumber);
        }
    }


    /**
     * @notice Check whether a random seed is ready.
     * @param _randomFulfilmentIndex Index indicating which random seed to check the status of.
     * @param _randomSource The source to use when retrieving the status of the random seed.
     * @return bool indicates a random seed is ready to be fetched.
     */
    function isRandomSeedReady(uint256 _randomFulfilmentIndex, address _randomSource) external view returns (SeedRequestStatus) {
        if (_randomSource == ONCHAIN) {
            // slither-disable-next-line incorrect-equality
            if ((randomOutput[_randomFulfilmentIndex] != bytes32(0)) ||
                    (_randomFulfilmentIndex < block.number && _randomFulfilmentIndex + 256 > block.number)) {
                return SeedRequestStatus.READY;
            }
            // slither-disable-next-line incorrect-equality
            if (_randomFulfilmentIndex >= block.number) {
                return SeedRequestStatus.IN_PROGRESS;
            }
            return SeedRequestStatus.FAILED;
        } else {
            return IOffchainRandomSource(_randomSource).isOffchainRandomReady(_randomFulfilmentIndex) ? 
                SeedRequestStatus.READY : SeedRequestStatus.IN_PROGRESS;
        }
    }

    function onchainGenerationStatus() external view returns (uint256 _oldestBlockNumber, uint256 _queueDepth) {
        return (peakNext(), queueLength());
    }

    /**
     * @notice Generate a seed value for a specifc block number that was previously requested.
     * @param _blockNumber The block to generate the block hash for.
     * @return block hash at the block
     */
    function generateSeedOnChain(uint256 _blockNumber) private returns(bytes32) {
        if (_blockNumber + 256 < block.number) {
            // Too late to call blockhash.
            revert GenerationFailedTryAgain(_blockNumber);
        }
        dequeueBlockNumber(_blockNumber);
        return generateEntropy(_blockNumber);
    }


    /**
     * @notice Generate entropy using block hash.
     * @dev The block number must be one of the previous 256 blocks.
     * @param _blockNumber is the block to fetch the block hash for. 
     */
    function generateEntropy(uint256 _blockNumber) private view returns (bytes32) {
        // The block producer could manipulate the block hash by crafting a
        // transaction that included a number that the block producer controls. A
        // malicious block producer could produce many candidate blocks, in an attempt
        // to produce a specific value.
        // If the blockchain has no transactions in multiple sequential blocks, a 
        // deterministic block producer, and a stable block period, then a game player 
        // could predict a range of possible block hash values. They could obverve a block 
        // being produced and then, if advantageous to them, immeditately submit a 
        // transaction, hoping that the transaction will be gossiped to the block producer
        // in time for block inclusion. That is, they could request a random seed be
        // produced in one block, knowing that the block hash some blocks later will
        // be used as the entropy for the random seed generator. They could craft their
        // transaction, in the hope of crafting a specific seed, and resultant random 
        // number.
        // The mitigation for this attack is for a transaction to be put onto the 
        // blockchain regularly that reveals a new layer of a hash onion, thus 
        // inserting unchangeable random values onto the chain.
        return blockhash(_blockNumber);
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
    uint256[100] private __gapRandomSeedProvider;
}
