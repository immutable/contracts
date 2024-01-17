// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "../IOffchainRandomSource.sol";

/**
 * @notice All Verifiable Random Function (VRF) source adaptors derive from this contract.
 * @dev This contract is NOT upgradeable. If there is an issue with this code, deploy a new
 *      version of the code and have the random seed provider point to the new version.
 */
abstract contract SourceAdaptorBase is AccessControlEnumerable, IOffchainRandomSource {
    
    event UnexpectedRandomWordsLength(uint256 _length);


    bytes32 public constant CONFIG_ADMIN_ROLE = keccak256("CONFIG_ADMIN_ROLE");

    // Immutable zkEVM has instant finality, so a single block confirmation is fine.
    uint16 public constant MIN_CONFIRMATIONS = 1;
    // We only need one word, and can expand that word in this system of contracts.
    uint32 public constant NUM_WORDS = 1;

    // The values returned by the VRF.
    mapping (uint256 => bytes32) private randomOutput;

    // VRF contract.
    address public vrfCoordinator;


    constructor(address _roleAdmin, address _configAdmin, address _vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(CONFIG_ADMIN_ROLE, _configAdmin);
        vrfCoordinator = _vrfCoordinator;
    }



// Call back
    function _fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal {
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