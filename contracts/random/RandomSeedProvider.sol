// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {AccessControlEnumerableUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/access/AccessControlEnumerableUpgradeable.sol";
import {IOffchainRandomSource} from "./IOffchainRandomSource.sol";


/**
 * @notice Contract to provide random seed values to game contracts on the chain.
 * @dev    The expectation is that there will only be one RandomSeedProvider per chain.
 *         Game contracts will call this contract to obtain a seed value, from which 
 *         they will generate random values.
 *
 *         The contract is upgradeable. It is expected to be operated behind an 
 *         Open Zeppelin TransparentUpgradeProxy. 
 */
contract RandomSeedProvider is AccessControlEnumerableUpgradeable {
    // The random seed value is not yet available.
    error WaitForRandom();
    // An error occurred calling an off-chain random provider.
    error OffchainRandomSourceError(bytes _error);

    // The offchain random source has been updated.
    event OffchainRandomSourceSet(address _offchainRandomSource, uint256 _offchainRequestRateLimit);

    // Indicates that new random values will be generated using the RanDAO source.
    event RanDaoEnabled();

    // Indicates that new random values will be generated using the traditional on-chain source.
    event TraditionalEnabled();

    // Admin role that can enable RanDAO and offchain random sources.
    bytes32 public constant RANDOM_ADMIN_ROLE = keccak256("RANDOM_ADMIN_ROLE");

    // Indicates: Generate new random numbers using the traditional on-chain methodology.
    address public constant TRADITIONAL = address(0);
    // Indicates: Generate new random numbers using the RanDAO methodology.
    address public constant RANDAO = address(1);

    // When random seeds are requested, a request id is returned. The id
    // relates to a certain future random seed. This map holds all of the 
    // random seeds that have been produced.
    mapping (uint256 => bytes32) public randomOutput;

    // The index of the next seed value to be produced.
    uint256 public nextRandomIndex;

    // The block number in which the last seed value was generated.
    uint256 public lastBlockRandomGenerated;

    uint256 public offchainRequestRateLimit;
    uint256 public prevOffchainRandomRequest;
    uint256 public lastBlockOffchainRequest;

    // @notice The source of new random numbers. This could be the special values for 
    // @notice TRADITIONAL or RANDAO or the address of a Offchain Random Source contract.
    // @dev This value is return with the request ids. This allows off-chain random sources
    // @dev to be switched without stopping in-flight random values from being retrieved.
    address public randomSource;

    // TODO add functions to modify this.
    mapping (address => bool) public approvedForOffchainRandom;


    /**
     * @notice Initialize the contract for use with a transparent proxy.
     * @param _roleAdmin is the account that can add and remove addresses that have 
     *        RANDOM_ADMIN_ROLE privilege.
     * @param _randomAdmin is the account that has RANDOM_ADMIN_ROLE privilege.
     */
    function initialize(address _roleAdmin, address _randomAdmin) public virtual initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(RANDOM_ADMIN_ROLE, _randomAdmin);

        // Generate an initial "random" seed.
        // Use the chain id as an input into the random number generator to ensure
        // all random numbers are personalised to this chain.
        randomOutput[0] = keccak256(abi.encodePacked(block.chainid, block.number));
        nextRandomIndex = 1;
        lastBlockRandomGenerated = block.number;

        randomSource = TRADITIONAL;
    }

    /**
     * @notice Change the offchain random source.
     * @dev Must have RANDOM_ROLE.
     * @param _offchainRandomSource Address of contract that is an offchain random source.
     */
    function setOffchainRandomSource(address _offchainRandomSource, uint256 _offchainRequestRateLimit) external onlyRole(RANDOM_ADMIN_ROLE) {
        randomSource = _offchainRandomSource;
        offchainRequestRateLimit = _offchainRequestRateLimit;
        emit OffchainRandomSourceSet(_offchainRandomSource, _offchainRequestRateLimit);
    }


    /**
     * @notice Switch to the RanDAO source.
     */
    function enableRanDao() external onlyRole(RANDOM_ADMIN_ROLE) {
        randomSource = RANDAO;
        emit RanDaoEnabled();
    }

    /**
     * @notice Switch to the traditional on-chain random source.
     */
    function enableTraditional() external onlyRole(RANDOM_ADMIN_ROLE) {
        randomSource = TRADITIONAL;
        emit TraditionalEnabled();
    }


    /**
     * @notice Request the index number to track when a random number will be produced.
     * @dev Note that the same _randomFulfillmentIndex will be returned to multiple games and even within
     *      the one game. Games must personalise this value to their own game, the the particular game player,
     *      and to the game player's request.
     * @return _randomFulfillmentIndex The index for the game contract to present to fetch the next random value.
     */
    function requestRandomSeed() external returns(uint256 _randomFulfillmentIndex, address _randomSource) {
        if (randomSource == TRADITIONAL || randomSource == RANDAO || !approvedForOffchainRandom[msg.sender]) {
            // Generate a value for this block, just in case there are historical requests 
            // to be fulfilled in transactions later in this block.
            _generateNextRandom();

            // Indicate that a value based on the next block will be fine.
            _randomFulfillmentIndex = nextRandomIndex + 1;
        }
        else {
            // Limit how often offchain random numbers are requested. If offchainRequestRateLimit is 1, then a 
            // maximum of one request per block is generated. If it 2, then a maximum of one request every two 
            // blocks is generated.
            uint256 offchainRequestRateLimitCached = offchainRequestRateLimit;
            uint256 blockNumberRateLimited = (block.number / offchainRequestRateLimitCached) * offchainRequestRateLimitCached;
            if (lastBlockOffchainRequest == blockNumberRateLimited) {
                _randomFulfillmentIndex = prevOffchainRandomRequest;
            }
            else {
                _randomFulfillmentIndex = IOffchainRandomSource(randomSource).requestOffchainRandom();
                prevOffchainRandomRequest = _randomFulfillmentIndex;
                lastBlockOffchainRequest = block.number;
            }
        }
        _randomSource = randomSource;
    }


    /**
     * @notice Fetches a random seed value that was requested using requestRandom.
     * @dev Note that the same _randomSeed will be returned to multiple games and even within
     *      the one game. Games must personalise this value to their own game, the the particular game player,
     *      and to the game player's request.
     * @return _randomSeed The value from with random values can be derived.
     */
    function getRandomSeed(uint256 _randomFulfillmentIndex, address _randomSource) external returns (bytes32 _randomSeed) {
        if (_randomSource == TRADITIONAL || _randomSource == RANDAO) {
            _generateNextRandom();
            if (_randomFulfillmentIndex > nextRandomIndex) {
                revert WaitForRandom();
            }
            return randomOutput[_randomFulfillmentIndex];
        }
        else {
            // If random source is not the address of a valid contract this will likely revert
            // with no revert information returned.
            return IOffchainRandomSource(randomSource).getOffchainRandom(_randomFulfillmentIndex); 
        }
    }

    /**
     * @notice Check whether a random seed is ready.
     * @param _randomFulfillmentIndex Index when random seed will be ready.
     */
    function isRandomSeedReady(uint256 _randomFulfillmentIndex, address _randomSource) external view returns (bool) {
        if (_randomSource == TRADITIONAL || _randomSource == RANDAO) {
            if (lastBlockRandomGenerated == block.number) {
                return _randomFulfillmentIndex <= nextRandomIndex;
            }
            else {
                return _randomFulfillmentIndex <= nextRandomIndex+1;
            }
        }
        else {
            return IOffchainRandomSource(randomSource).isOffchainRandomReady(_randomFulfillmentIndex); 
        }
    }


    /**
     * @notice Generate a random value using on-chain methodologies. 
     */
    function _generateNextRandom() private {
        bytes32 prevRandomOutput = randomOutput[nextRandomIndex - 1];
        bytes32 newRandomOutput;

        if (randomSource == TRADITIONAL) {
            // Random values for the TRADITIONAL methodology can only be generated once per block.
            if (lastBlockRandomGenerated == block.number) {
                return;
            }

            // Block hash will be different for each block and ---- easy ---- difficult for game players
            // to guess. The block producer could manipulate the block hash by crafting a 
            // transaction that included a number that the block producer controls. A
            // malicious block producer could produce many candidate blocks, in an attempt
            // to produce a specific value.

            // TODO this will crash - can't get blockhash of this block.
            bytes32 blockHash = blockhash(block.number);

            // Timestamp when a block is produced in milli-seconds will be different for each
            // block. Game players could estimate the possible values for the timestamp.
            // The block producer could manipulate the timestamp by changing the time recorded 
            // as when the block was produced. The block will be deemed invalid if the value is 
            // too far from the expected block time.
            // slither-disable-next-line timestamp
            uint256 timestamp = block.timestamp;

            newRandomOutput = keccak256(abi.encodePacked(prevRandomOutput, blockHash, timestamp));
        }
        else if (randomSource == RANDAO) {
            // Random values for the RANDAO methodology can only be generated once per block.
            if (lastBlockRandomGenerated == block.number) {
                return;
            }

            // PrevRanDAO (previously known as DIFFICULTY) is the output of the RanDAO function
            // used as a part of consensus. The value posted is the value revealed in the previous 
            // block, not in this block. In this way, all parties know the value prior to it being 
            // useable by applications.
            //
            // The RanDAO value can be influenced by a block producer deciding to produce or 
            // not produce a block. This limits the block producer's influence to one of two 
            // values.
            //
            // Prior to the BFT fork (expected in the first half of 2024), this value will 
            // be a predictable value related to the block number. 
            uint256 prevRanDAO = block.prevrandao;

            newRandomOutput = keccak256(abi.encodePacked(prevRandomOutput, prevRanDAO));
        }
        else {
            // Nothing to do here.
        }

        randomOutput[nextRandomIndex++] = newRandomOutput;
        lastBlockRandomGenerated = block.number;
    }



    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomSeedProvider;
}