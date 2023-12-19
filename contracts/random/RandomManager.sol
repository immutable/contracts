// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity ^0.8.19;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {IOffchainRandomSource} from "./IOffchainRandomSource.sol";



// TODO should be upgradeable
contract RandomManager is AccessControl {
    error InvalidSecurityLevel(uint256 _securityLevel);
    error WaitForRandom();


    mapping (uint256 => bytes32) private randomOutput;
    uint256 private nextRandomIndex;
    uint256 private lastBlockRandomGenerated;

    IOffchainRandomSource public offchainRandomSource;


    // TODO set-up access control
    constructor() {
        randomOutput[0] = keccak256(abi.encodePacked(block.chainid, block.number));
        nextRandomIndex = 1;
    }

    // TODO Access control
    function setOffchainRandomSource(address _offchainRandomSource) external {
        offchainRandomSource = IOffchainRandomSource(_offchainRandomSource);
    }


    /**
     * @notice Generate a random value. 
     */
    function generateNextRandom() public {
        // Previous random output.
        bytes32 prevRandomOutput = randomOutput[nextRandomIndex - 1];

        // Use the off chain random provider if it has been configured.
        IOffchainRandomSource offchainSourceCached = offchainRandomSource;
        if (address(offchainSourceCached) != address(0)) {
            bytes32 offchainRandom;
            uint256 index;
            (offchainRandom, index) = offchainSourceCached.getOffchainRandom();
            // No new random value is available at this point. Check back later.
            if (index != nextRandomIndex) {
                return;
            }
            randomOutput[nextRandomIndex++] = keccak256(abi.encodePacked(prevRandomOutput, offchainRandom));
        }
        else {
            // If the off chain random provider has NOT been configured, use on-chain sources. 
            // NOTE: Block proposers can influence these values. 

            // This values can only be updated once per block.
            if (lastBlockRandomGenerated == block.number) {
                return;
            }

            // Block hash will be different for each block. The block producer could manipulate
            // the block hash by selecting which set of transactions to include in a block or 
            // crafting a transaction that included a number that the block producer controlled.
            bytes32 blockHash = blockhash(block.number);
            // Timestamp will be different for each block. The block producer could manipulate
            // the timestamp by changing the time recorded as when the block was produced. The 
            // block will be deemed invalid if the value is too far from the expected block time.
            // slither-disable-next-line timestamp
            uint256 timestamp = block.timestamp;
            // PrevRanDAO (previously known as DIFFICULTY) is the output of the RanDAO function
            // used as a part of consensus. The value posted is the value revealed in the previous 
            // block, not in this block. In this way, all parties know the value prior to it being 
            // useable by applications.
            // This can be influenced by a block producer deciding to produce or not produce a block.
            // NOTE: Prior to the BFT fork (expected in the first half of 2024), this value will 
            // be a predictable value.
            uint256 prevRanDAO = block.prevrandao;

            // The new random value is a combination of 
            randomOutput[nextRandomIndex++] = keccak256(abi.encodePacked(prevRandomOutput, blockHash, timestamp, prevRanDAO));
        }
    }

    /**
     * @notice Request the index number to be used for generating a random value.
     * @dev Note that the same _randomFulfillmentIndex will be returned to multiple games and even within
     *      the one game. Games must personalise this value to their own game, the the particular game player,
     *      and to the game player's request.
     * @param _securityLevel The number of random number generations to wait. A higher value provides
     *      better security. For most applications, a value of 1 or 2 is ideal. If the random number
     *      is for a high value transaction, choose a high number, for instance 3 or 4. 
     *      The reasoning behind a low value providing less security is that when the security level 
     *      is set to one, the seed is derived from the next off-chain random value. However, this 
     *      value could relate to an off-chain random value being supplied by a transaction that is currently 
     *      in the transaction pool. Some game players may be able to see this value and hence guess the 
     *      outcome for the random generation. Having a higher value means that the game player has to commit
     *      before the off-chain random number is put into a transaction that is then put into the 
     *      transaction pool.
     * @return _randomFulfillmentIndex The index for the game contract to present to fetch the next random value.
     */
    function requestRandom(uint256 _securityLevel) external returns(uint256 _randomFulfillmentIndex) {
        if (_securityLevel == 0 || _securityLevel > 10) {
            revert InvalidSecurityLevel(_securityLevel);
        }
        // Generate a new value now using offchain values that might be cached in the blockchain already.
        // Do this to ensure nafarious actors can't read the cached values and use them to determine
        // the next random value.
        generateNextRandom();
        // Indicate that the next generated random value can be used.
        _randomFulfillmentIndex = nextRandomIndex + _securityLevel;
    }


    /**
     * @notice Fetches a random seed value that was requested using requestRandom.
     * @dev Note that the same _randomSeed will be returned to multiple games and even within
     *      the one game. Games must personalise this value to their own game, the the particular game player,
     *      and to the game player's request.
     * @return _randomSeed The value from with random values can be derived.
     */
    function getRandomSeed(uint256 _randomFulfillmentIndex) external returns (bytes32 _randomSeed) {
        generateNextRandom();
        if (_randomFulfillmentIndex < nextRandomIndex) {
            revert WaitForRandom();
        }
        return randomOutput[_randomFulfillmentIndex];


    }


    // TODO storage gap
}