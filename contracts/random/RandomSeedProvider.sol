// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

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
contract RandomSeedProvider is AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    /// @notice Indicate that the requested upgrade is not possible.
    error CanNotUpgradeFrom(uint256 _storageVersion, uint256 _codeVersion);

    /// @notice The random seed value is not yet available.
    error WaitForRandom();

    /// @notice The off-chain random source has been updated.
    event OffchainRandomSourceSet(address _offchainRandomSource);

    /// @notice Indicates that new random values from the on-chain source will be generated
    /// @notice using the RanDAO source.
    event RanDaoEnabled();

    /// @notice Indicates that a game contract that can consume off-chain random has been added.
    event OffchainRandomConsumerAdded(address _consumer);

    /// @notice Indicates that a game contract that can consume off-chain random has been removed.
    event OffchainRandomConsumerRemoved(address _consumer);

    // Code and storage layout version number.
    uint256 internal constant VERSION0 = 0;

    /// @notice Admin role that can enable RanDAO and off-chain random sources.
    bytes32 public constant RANDOM_ADMIN_ROLE = keccak256("RANDOM_ADMIN_ROLE");

    /// @notice Only accounts with UPGRADE_ADMIN_ROLE can upgrade the contract.
    bytes32 public constant UPGRADE_ADMIN_ROLE = bytes32("UPGRADE_ROLE");

    /// @notice Indicates: Generate new random numbers using on-chain methodology.
    address public constant ONCHAIN = address(0);

    /// @notice All historical random output.
    /// @dev When random seeds are requested, a request id is returned. The id
    /// @dev relates to a certain future random seed. This map holds all of the
    /// @dev random seeds that have been produced.
    mapping(uint256 requestId => bytes32 randomValue) public randomOutput;

    /// @notice The index of the next seed value to be produced.
    uint256 public nextRandomIndex;

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

    /// @notice Indicates that this blockchain supports the PREVRANDAO opcode and that
    /// @notice PREVRANDAO should be used rather than block.hash for on-chain random values.
    bool public ranDaoAvailable;

    /// @notice Indicates an address is allow listed for the off-chain random provider.
    /// @dev Having an allow list prevents spammers from requesting one random number per block,
    /// @dev thus incurring cost on Immutable for no benefit.
    mapping(address gameContract => bool approved) public approvedForOffchainRandom;

    // @notice The version of the storage layout.
    // @dev This storage slot will be used during upgrades.
    uint256 public version;

    /**
     * @notice Initialize the contract for use with a transparent proxy.
     * @param _roleAdmin is the account that can add and remove addresses that have
     *        RANDOM_ADMIN_ROLE privilege.
     * @param _randomAdmin is the account that has RANDOM_ADMIN_ROLE privilege.
     * @param _upgradeAdmin is the account that has UPGRADE_ADMIN_ROLE privilege.
     * @param _ranDaoAvailable indicates if the chain supports the PRERANDAO opcode.
     */
    function initialize(
        address _roleAdmin,
        address _randomAdmin,
        address _upgradeAdmin,
        bool _ranDaoAvailable
    ) public virtual initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _roleAdmin);
        _grantRole(RANDOM_ADMIN_ROLE, _randomAdmin);
        _grantRole(UPGRADE_ADMIN_ROLE, _upgradeAdmin);

        // Generate an initial "random" seed.
        // Use the chain id as an input into the random number generator to ensure
        // all random numbers are personalised to this chain.
        randomOutput[0] = keccak256(abi.encodePacked(block.chainid, block.number));
        nextRandomIndex = 1;
        lastBlockRandomGenerated = block.number;

        randomSource = ONCHAIN;
        ranDaoAvailable = _ranDaoAvailable;
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
        randomSource = _offchainRandomSource;
        emit OffchainRandomSourceSet(_offchainRandomSource);
    }

    /**
     * @notice Call this when the blockchain supports the PREVRANDAO opcode.
     * @dev Only RANDOM_ADMIN_ROLE can do this.
     */
    function setRanDaoAvailable() external onlyRole(RANDOM_ADMIN_ROLE) {
        ranDaoAvailable = true;
        emit RanDaoEnabled();
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
     * @dev Note that the same _randomFulfillmentIndex will be returned to multiple games and even within
     * @dev the one game. Games must personalise this value to their own game, the particular game player,
     * @dev and to the game player's request.
     * @return _randomFulfillmentIndex The index for the game contract to present to fetch the next random value.
     * @return _randomSource Indicates that an on-chain source was used, or is the address of an off-chain source.
     */
    function requestRandomSeed() external returns (uint256 _randomFulfillmentIndex, address _randomSource) {
        if (randomSource == ONCHAIN || !approvedForOffchainRandom[msg.sender]) {
            // Generate a value for this block if one has not been generated yet. This
            // is required because there may have been calls to requestRandomSeed
            // in previous blocks that are waiting for a random number to be produced.
            _generateNextRandomOnChain();

            // Indicate that a value based on the next block will be fine.
            _randomFulfillmentIndex = nextRandomIndex;

            _randomSource = ONCHAIN;
        } else {
            // Limit how often off-chain random numbers are requested to a maximum of once per block.
            if (lastBlockOffchainRequest == block.number) {
                _randomFulfillmentIndex = prevOffchainRandomRequest;
            } else {
                _randomFulfillmentIndex = IOffchainRandomSource(randomSource).requestOffchainRandom();
                prevOffchainRandomRequest = _randomFulfillmentIndex;
                lastBlockOffchainRequest = block.number;
            }
            _randomSource = randomSource;
        }
    }

    /**
     * @notice Fetches a random seed value that was requested using the requestRandomSeed function.
     * @dev Note that the same _randomSeed will be returned to multiple games and even within
     * @dev the one game. Games must personalise this value to their own game, the particular game player,
     * @dev and to the game player's request.
     * @param _randomFulfillmentIndex Index indicating which random seed to return.
     * @return _randomSource The source to use when retrieving the random seed.
     * @return _randomSeed The value from which random values can be derived.
     */
    function getRandomSeed(
        uint256 _randomFulfillmentIndex,
        address _randomSource
    ) external returns (bytes32 _randomSeed) {
        if (_randomSource == ONCHAIN) {
            _generateNextRandomOnChain();
            if (_randomFulfillmentIndex >= nextRandomIndex) {
                revert WaitForRandom();
            }
            return randomOutput[_randomFulfillmentIndex];
        } else {
            // If random source is not the address of a valid contract this will revert
            // with no revert information returned.
            return IOffchainRandomSource(_randomSource).getOffchainRandom(_randomFulfillmentIndex);
        }
    }

    /**
     * @notice Check whether a random seed is ready.
     * @param _randomFulfillmentIndex Index indicating which random seed to check the status of.
     * @return _randomSource The source to use when retrieving the status of the random seed.
     */
    function isRandomSeedReady(uint256 _randomFulfillmentIndex, address _randomSource) external view returns (bool) {
        if (_randomSource == ONCHAIN) {
            if (lastBlockRandomGenerated == block.number) {
                return _randomFulfillmentIndex < nextRandomIndex;
            } else {
                return _randomFulfillmentIndex < nextRandomIndex + 1;
            }
        } else {
            return IOffchainRandomSource(_randomSource).isOffchainRandomReady(_randomFulfillmentIndex);
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

    /**
     * @notice Generate a random value using on-chain methodologies.
     */
    function _generateNextRandomOnChain() private {
        // Onchain random values can only be generated once per block.
        if (lastBlockRandomGenerated == block.number) {
            return;
        }

        uint256 entropy;
        if (ranDaoAvailable) {
            // PrevRanDAO (previously known as DIFFICULTY) is the output of the RanDAO function
            // used as a part of consensus. The value posted is the value revealed in the previous
            // block, not in this block. In this way, all parties know the value prior to it being
            // useable by applications.
            //
            // The RanDAO value can be influenced by a block producer deciding to produce or
            // not produce a block. This limits the block producer's influence to one of two
            // values.
            //
            // Prior to the BFT fork (expected in 2024), this value will be a predictable value
            // related to the block number.
            entropy = block.prevrandao;
        } else {
            // Block hash will be different for each block and difficult for game players
            // to guess. However, game players can observe blocks as they are produced.
            // The block producer could manipulate the block hash by crafting a
            // transaction that included a number that the block producer controls. A
            // malicious block producer could produce many candidate blocks, in an attempt
            // to produce a specific value.
            entropy = uint256(blockhash(block.number - 1));
        }

        bytes32 prevRandomOutput = randomOutput[nextRandomIndex - 1];
        bytes32 newRandomOutput = keccak256(abi.encodePacked(prevRandomOutput, entropy));
        randomOutput[nextRandomIndex++] = newRandomOutput;
        lastBlockRandomGenerated = block.number;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[100] private __gapRandomSeedProvider;
}
