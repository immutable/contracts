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

    /// @notice A seed could not be generate for a block because too long had elapsed between 
    /// requesting and a call to getRandomSeed or generateNextSeedOnChain.
    event TooLateToGenerateRandom(uint256 _blockNumber);

    /// @notice The off-chain random source has been updated.
    event OffchainRandomSourceSet(address _offchainRandomSource);

    /// @notice Changes the on chain source delay between requesting and fulfilling.
    event SetOnChainDelay(uint256 _onChainDelay);

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

    /// @notice The block number in which the last seed value was generated.
    uint256 public lastBlockRandomGenerated;

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

    /// @notice Previous output.
    bytes32 public prevRandomOutput;

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

        // Generate an initial "random" seed.
        // Use the chain id as an input into the random number generator to ensure
        // all random numbers are personalised to this chain.
        prevRandomOutput = keccak256(abi.encodePacked(block.chainid, blockhash(block.number - 1)));

        lastBlockRandomGenerated = block.number;

        randomSource = ONCHAIN;
        onChainDelay = 2; // 2 blocks.

        version = VERSION0;
    }

    /**
     * @notice Called during contract upgrade.
     * @dev This function will be overridden in future versions of this contract.
     */
    function upgrade() external virtual {
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
     */
    function setOnChainDelay(uint256 _onChainDelay) external onlyRole(RANDOM_ADMIN_ROLE) {
        onChainDelay = _onChainDelay;
        emit SetOnChainDelay(_onChainDelay);
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
            generateNextSeedOnChain();
            bytes32 output = randomOutput[_randomFulfilmentIndex];
            if (output == bytes32(0)) {
                if (_randomFulfilmentIndex < blockNumberMinus255OrZero()) {
                    revert GenerationFailedTryAgain(_randomFulfilmentIndex);
                }
                revert WaitForRandom(_randomFulfilmentIndex);
            }
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
    function generateNextSeedOnChain() public {
        bytes32 prev = prevRandomOutput;

        uint256 lenOutstandingRequests = queueLength();
        uint256 blockNumberMinus255 = blockNumberMinus255OrZero();
        for (uint256 i = 0; i < lenOutstandingRequests; i++) {
            uint256 blockNumber = peakNext();
            // If the block number is this block or a future block, then skip for now and 
            // do it later.
            if (blockNumber >= block.number) {
                break;
            }
            //  Consume the request.
            dequeue();

            if (blockNumber < blockNumberMinus255) {
                emit TooLateToGenerateRandom(blockNumber);
                continue;
            }

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
            uint256 entropy = uint256(blockhash(blockNumber));
            prev = keccak256(abi.encodePacked(prev, entropy));
            randomOutput[blockNumber] = prev;
        }
        prevRandomOutput = prev;
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
                    (_randomFulfilmentIndex < block.number && _randomFulfilmentIndex > blockNumberMinus255OrZero())) {
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

    /**
     * @notice Return block number - 255, but avoid underflow.
     * @dev This view call can only be called in the context of a transaction.
     */
    function blockNumberMinus255OrZero() private view returns (uint256) {
        if (block.number < 255) {
            return 0;
        }
        return block.number - 255;
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
