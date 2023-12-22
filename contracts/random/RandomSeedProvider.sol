// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
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

    error UnknownMethodology();

    // The offchain random source has been updated.
    event OffchainRandomSourceSet(address _offchainRandomSource);

    // The RanDAO source has been enabled. Note that this source will only be used if
    // an offchain random source is not available.
    event RanDaoEnabled();

    enum GenerationMethodology {
        TRADITIONAL,
        RANDAO,
        OFFCHAIN
    }


    // Admin role that can enable RanDAO and offchain random sources.
    bytes32 public constant RANDOM_ADMIN_ROLE = keccak256("RANDOM_ADMIN_ROLE");

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


    // Off-chain random source that is used to generate random seeds.
    IOffchainRandomSource public offchainRandomSource;

    GenerationMethodology public methodology;


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

        methodology = GenerationMethodology.TRADITIONAL;
    }

    /**
     * @notice Change the offchain random source.
     * @dev Must have RANDOM_ROLE.
     * @param _offchainRandomSource Address of contract that is an offchain random source.
     */
    function setOffchainRandomSource(address _offchainRandomSource, uint256 _offchainRequestRateLimit) external onlyRole(RANDOM_ADMIN_ROLE) {
        offchainRandomSource = IOffchainRandomSource(_offchainRandomSource);
        offchainRequestRateLimit = _offchainRequestRateLimit;
        methodology = GenerationMethodology.OFFCHAIN;
        emit OffchainRandomSourceSet(_offchainRandomSource);
    }


    /**
     * @notice Enable the RanDAO source.
     * @dev If the off-chain source has not been configured, and the consensus 
     *      algorithm supports RanDAO, then let's use it.
     */
    function enableRanDao() external onlyRole(RANDOM_ADMIN_ROLE) {
        methodology = GenerationMethodology.RANDAO;
        emit RanDaoEnabled();
    }

    /**
     * @notice Generate a random value using on-chain methodologies. 
     */
    function generateNextRandom() public {
        bytes32 prevRandomOutput = randomOutput[nextRandomIndex - 1];
        bytes32 newRandomOutput;

        if (methodology == GenerationMethodology.TRADITIONAL) {
            // Random values for the TRADITIONAL methodology can only be generated once per block.
            if (lastBlockRandomGenerated == block.number) {
                return;
            }

            // Block hash will be different for each block and difficult for game players
            // to guess. The block producer could manipulate the block hash by crafting a 
            // transaction that included a number that the block producer controls. A
            // malicious block producer could produce many candidate blocks, in an attempt
            // to produce a specific value.
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
        else if (methodology == GenerationMethodology.RANDAO) {
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
        else if (methodology == GenerationMethodology.OFFCHAIN) {
            // Nothing to do here.
        }
        else {
            revert UnknownMethodology();
        }

        randomOutput[nextRandomIndex++] = newRandomOutput;
        lastBlockRandomGenerated = block.number;
    }

    /**
     * @notice Request the index number to track when a random number will be produced.
     * @dev Note that the same _randomFulfillmentIndex will be returned to multiple games and even within
     *      the one game. Games must personalise this value to their own game, the the particular game player,
     *      and to the game player's request.
     * @return _randomFulfillmentIndex The index for the game contract to present to fetch the next random value.
     */
    function requestRandomSeed() external returns(uint256 _randomFulfillmentIndex, GenerationMethodology _method) {
        if (methodology == GenerationMethodology.TRADITIONAL || methodology == GenerationMethodology.RANDAO) {
            // Generate a value for this block, just in case there are historical requests 
            // to be fulfilled in transactions later in this block.
            generateNextRandom();

            // Indicate that a value based on the next block will be fine.
            _randomFulfillmentIndex = nextRandomIndex + 1;
            _method = methodology;
        }
        else if (methodology == GenerationMethodology.OFFCHAIN) {
            // Limit how often offchain random numbers are requested. If 
            // offchainRequestRateLimit is 1, then a maximum of one request 
            // per block is generated. If it 2, then a maximum of one request
            // every two blocks is generated.
            uint256 offchainRequestRateLimitCached = offchainRequestRateLimit;
            uint256 blockNumberRateLimited = (block.number / offchainRequestRateLimitCached) * offchainRequestRateLimitCached;
            if (lastBlockOffchainRequest == blockNumberRateLimited) {
                _randomFulfillmentIndex = prevOffchainRandomRequest;
            }
            else {
                _randomFulfillmentIndex = offchainRandomSource.requestOffchainRandom();
                prevOffchainRandomRequest = _randomFulfillmentIndex;
                lastBlockOffchainRequest = block.number;
            }
            _method = GenerationMethodology.OFFCHAIN;
        }
        else {
            revert UnknownMethodology();
        }
    }


    /**
     * @notice Fetches a random seed value that was requested using requestRandom.
     * @dev Note that the same _randomSeed will be returned to multiple games and even within
     *      the one game. Games must personalise this value to their own game, the the particular game player,
     *      and to the game player's request.
     * @return _randomSeed The value from with random values can be derived.
     */
    function getRandomSeed(uint256 _randomFulfillmentIndex, GenerationMethodology _method) external returns (bytes32 _randomSeed) {
        if (_method == GenerationMethodology.TRADITIONAL || _method == GenerationMethodology.RANDAO) {
            generateNextRandom();
            if (_randomFulfillmentIndex < nextRandomIndex) {
                revert WaitForRandom();
            }
            return randomOutput[_randomFulfillmentIndex];
        }
        else if (_method == GenerationMethodology.OFFCHAIN) {
            return offchainRandomSource.getOffchainRandom(_randomFulfillmentIndex); 
        }
        else {
            revert UnknownMethodology();
        }
    }

    /**
     * @notice Check whether a random seed is ready.
     * @param _randomFulfillmentIndex Index when random seed will be ready.
     */
    function randomSeedIsReady(uint256 _randomFulfillmentIndex, GenerationMethodology _method) external view returns (bool) {
        if (_method == GenerationMethodology.TRADITIONAL || _method == GenerationMethodology.RANDAO) {
            if (lastBlockRandomGenerated == block.number) {
                return _randomFulfillmentIndex <= nextRandomIndex;
            }
            else {
                return _randomFulfillmentIndex <= nextRandomIndex+1;
            }
        }
        else if (_method == GenerationMethodology.OFFCHAIN) {
            return bytes32(0x00) != offchainRandomSource.getOffchainRandom(_randomFulfillmentIndex); 
        }
        else {
            revert UnknownMethodology();
        }
    }


    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomSeedProvider;
}