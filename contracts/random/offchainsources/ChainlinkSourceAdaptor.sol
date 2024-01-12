// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "../IOffchainRandomSource.sol";

/**
 * @notice Fetch random numbers from the Chainlink Verifiable Random 
 * @notice Function (VRF).
 * @dev This contract is NOT upgradeable. If there is an issue with this code, deploy a new
 *      version of the code and have the random seed provider point to the new version.
 */
contract ChainlinkSourceAdaptor is VRFConsumerBaseV2, AccessControlEnumerable, IOffchainRandomSource {

    
    event UnexpectedRandomWordsLength(uint256 _length);


    bytes32 public constant CONFIG_ADMIN_ROLE = keccak256("CONFIG_ADMIN_ROLE");

    // Immutable zkEVM has instant finality, so a single block confirmation is fine.
    uint16 public constant MIN_CONFIRMATIONS = 1;
    // We only need one word, and can expand that word in this system of contracts.
    uint32 public constant NUM_WORDS = 1;

    VRFCoordinatorV2Interface private immutable vrfCoordinator;

    bytes32 public keyHash;
    uint64 public subId;
    uint32 public callbackGasLimit;

    mapping (uint256 => bytes32) private randomOutput;


    constructor(address _roleAdmin, address _configAdmin, address _vrfCoordinator, bytes32 _keyHash, 
        uint64 _subId, uint32 _callbackGasLimit) VRFConsumerBaseV2(_vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(CONFIG_ADMIN_ROLE, _configAdmin);
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);

        keyHash = _keyHash;
        subId = _subId;
        callbackGasLimit = _callbackGasLimit;
    }

    function configureRequests(bytes32 _keyHash, uint64 _subId, uint32 _callbackGasLimit) external onlyRole(CONFIG_ADMIN_ROLE) {
        keyHash = _keyHash;
        subId = _subId;
        callbackGasLimit = _callbackGasLimit;
    }

    function requestOffchainRandom() external returns(uint256 _requestId) {
        return vrfCoordinator.requestRandomWords(keyHash, subId, MIN_CONFIRMATIONS, callbackGasLimit, NUM_WORDS);
    }


// Call back
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal virtual override {
        // NOTE: This function call is not allowed to fail.
        // Only one word should be returned....
        if (_randomWords.length != 1) {
            emit UnexpectedRandomWordsLength(_randomWords.length);
        }

        randomOutput[_requestId] = bytes32(_randomWords[0]);
    }


    function getOffchainRandom(uint256 _fulfillmentIndex) external view returns(bytes32 _randomValue) {
        bytes32 rand = randomOutput[_fulfillmentIndex];
        if (rand == bytes32(0)) {
            revert WaitForRandom();
        }
        _randomValue = rand;
    }

    function isOffchainRandomReady(uint256 _fulfillmentIndex) external view returns(bool) {
        return randomOutput[_fulfillmentIndex] != bytes32(0);
    }

}