// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IOffchainRandomSource} from "./IOffchainRandomSource.sol";

/**
 * @notice All Verifiable Random Function (VRF) source adaptors derive from this contract.
 * @dev This contract is NOT upgradeable. If there is an issue with this code, deploy a new
 *      version of the code and have the random seed provider point to the new version.
 */
abstract contract SourceAdaptorBase is AccessControlEnumerable, IOffchainRandomSource {
    error UnexpectedRandomWordsLength(uint256 _length);

    bytes32 internal constant CONFIG_ADMIN_ROLE = keccak256("CONFIG_ADMIN_ROLE");

    // Immutable zkEVM has instant finality, so a single block confirmation is fine.
    uint16 internal constant MIN_CONFIRMATIONS = 1;
    // We only need one word, and can expand that word in this system of contracts.
    uint32 internal constant NUM_WORDS = 1;

    // The values returned by the VRF.
    mapping(uint256 _fulfilmentId => bytes32 randomValue) private randomOutput;

    // VRF contract.
    address public vrfCoordinator;

    constructor(address _roleAdmin, address _configAdmin, address _vrfCoordinator) {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(CONFIG_ADMIN_ROLE, _configAdmin);
        vrfCoordinator = _vrfCoordinator;
    }

    /**
     * @notice Callback called when random words are returned by the VRF.
     * @dev Assumes external function that calls this checks that the random values are coming
     * @dev from the VRF.
     * @dev NOTE that Chainlink assumes that this function will not fail.
     * @param _requestId is the fulfilment index.
     * @param _randomWords are the random values from the VRF.
     */
    function _fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal {
        // NOTE: This function call is not allowed to fail. However, if one word is requested
        // and some other number of words has been returned, then maybe the source has been
        // compromised. Reverting the call is more likely to draw attention to the issue than
        // emitting an event.
        if (_randomWords.length != 1) {
            revert UnexpectedRandomWordsLength(_randomWords.length);
        }
        randomOutput[_requestId] = bytes32(_randomWords[0]);
    }

    /**
     * @inheritdoc IOffchainRandomSource
     */
    function getOffchainRandom(
        uint256 _fulfilmentIndex
    ) external view override(IOffchainRandomSource) returns (bytes32 _randomValue) {
        bytes32 rand = randomOutput[_fulfilmentIndex];
        if (rand == bytes32(0)) {
            revert WaitForRandom();
        }
        _randomValue = rand;
    }

    /**
     * @inheritdoc IOffchainRandomSource
     */
    function isOffchainRandomReady(
        uint256 _fulfilmentIndex
    ) external view override(IOffchainRandomSource) returns (bool) {
        return randomOutput[_fulfilmentIndex] != bytes32(0);
    }
}
