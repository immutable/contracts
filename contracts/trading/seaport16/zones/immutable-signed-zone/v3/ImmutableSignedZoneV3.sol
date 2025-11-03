// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.20;

import {AccessControlEnumerable} from "openzeppelin-contracts-5.0.2/access/extensions/AccessControlEnumerable.sol";
import {ECDSA} from "openzeppelin-contracts-5.0.2/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "openzeppelin-contracts-5.0.2/utils/cryptography/MessageHashUtils.sol";
import {ERC165} from "openzeppelin-contracts-5.0.2/utils/introspection/ERC165.sol";
import {Math} from "openzeppelin-contracts-5.0.2/utils/math/Math.sol";
import {ZoneInterface} from "seaport-types-16/src/interfaces/ZoneInterface.sol";
import {ZoneParameters, Schema, ReceivedItem} from "seaport-types-16/src/lib/ConsiderationStructs.sol";
import {ZoneAccessControl} from "./ZoneAccessControl.sol";
import {SIP5Interface} from "./interfaces/SIP5Interface.sol";
import {SIP6Interface} from "./interfaces/SIP6Interface.sol";
import {SIP7Interface} from "./interfaces/SIP7Interface.sol";

/**
 * @title  ImmutableSignedZoneV3
 * @author Immutable
 * @notice ImmutableSignedZoneV3 is a zone implementation based on the
 *         SIP-7 standard https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md
 *         implementing substandards 1, 3, 4 and 6.
 *
 *         The contract is not upgradable. If the contract needs to be changed a new version
 *         should be deployed, and the old version should be removed from the Seaport contract
 *         zone allowlist.
 */
contract ImmutableSignedZoneV3 is
    ERC165,
    ZoneAccessControl,
    ZoneInterface,
    SIP5Interface,
    SIP6Interface,
    SIP7Interface
{
    /// @dev The EIP-712 domain type hash.
    bytes32 private constant _EIP_712_DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );

    /// @dev The EIP-712 domain version value.
    bytes32 private constant _VERSION_HASH = keccak256(bytes("3.0"));

    /// @dev The EIP-712 signed order type hash.
    bytes32 private constant _SIGNED_ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "SignedOrder(",
                "address fulfiller,",
                "uint64 expiration,",
                "bytes32 orderHash,",
                "bytes context",
                ")"
            )
        );

    /// @dev The chain ID on which the contract was deployed.
    uint256 private immutable _CHAIN_ID = block.chainid;

    /// @dev The domain separator used for signing.
    bytes32 private immutable _DOMAIN_SEPARATOR;

    /// @dev The accepted SIP-6 version.
    uint8 private constant _ACCEPTED_SIP6_VERSION = 0;

    /// @dev The name for this zone returned in getSeaportMetadata().
    // solhint-disable-next-line var-name-mixedcase
    string private _ZONE_NAME;

    bytes32 private immutable _NAME_HASH;

    /// @dev The allowed signers.
    // solhint-disable-next-line named-parameters-mapping
    mapping(address => SignerInfo) private _signers;

    /// @dev The API endpoint where orders for this zone can be signed.
    string private _apiEndpoint;

    /// @dev The documentationURI.
    string private _documentationURI;

    /**
     * @notice Constructor to deploy the contract.
     *
     * @param zoneName         The name for the zone returned in getSeaportMetadata().
     * @param apiEndpoint      The API endpoint where orders for this zone can be signed.
     *                         Request and response payloads are defined in SIP-7.
     * @param documentationURI The documentation URI.
     * @param owner            The address of the owner of this contract. Specified in the
     *                         constructor to be CREATE2 / CREATE3 compatible.
     */
    constructor(
        string memory zoneName,
        string memory apiEndpoint,
        string memory documentationURI,
        address owner
    ) ZoneAccessControl(owner) {
        // Set the zone name.
        _ZONE_NAME = zoneName;

        // Set name hash.
        _NAME_HASH = keccak256(bytes(zoneName));

        // Set the API endpoint.
        _apiEndpoint = apiEndpoint;

        // Set the documentation URI.
        _documentationURI = documentationURI;

        // Derive and set the domain separator.
        _DOMAIN_SEPARATOR = _deriveDomainSeparator();

        // Emit an event to signal a SIP-5 contract has been deployed.
        emit SeaportCompatibleContractDeployed();
    }

    /**
     * @notice Add a new signer to the zone.
     *
     * @param signer The new signer address to add.
     */
    function addSigner(address signer) external override onlyRole(ZONE_MANAGER_ROLE) {
        // Do not allow the zero address to be added as a signer.
        if (signer == address(0)) {
            revert SignerCannotBeZeroAddress();
        }

        // Revert if the signer is already active.
        if (_signers[signer].active) {
            revert SignerAlreadyActive(signer);
        }

        // Revert if the signer was previously authorized.
        // Specified in SIP-7 to prevent compromised signer from being
        // cycled back into use.
        if (_signers[signer].previouslyActive) {
            revert SignerCannotBeReauthorized(signer);
        }

        // Set the signer info.
        _signers[signer] = SignerInfo(true, true);

        // Emit an event that the signer was added.
        emit SignerAdded(signer);
    }

    /**
     * @notice Remove an active signer from the zone.
     *
     * @param signer The signer address to remove.
     */
    function removeSigner(address signer) external override onlyRole(ZONE_MANAGER_ROLE) {
        // Revert if the signer is not active.
        if (!_signers[signer].active) {
            revert SignerNotActive(signer);
        }

        // Set the signer's active status to false.
        _signers[signer].active = false;

        // Emit an event that the signer was removed.
        emit SignerRemoved(signer);
    }

    /**
     * @notice Update the API endpoint returned by this zone.
     *
     * @param newApiEndpoint The new API endpoint.
     */
    function updateAPIEndpoint(string calldata newApiEndpoint) external override onlyRole(ZONE_MANAGER_ROLE) {
        _apiEndpoint = newApiEndpoint;
    }

    /**
     * @notice Update the documentation URI returned by this zone.
     *
     * @param newDocumentationURI The new documentation URI.
     */
    function updateDocumentationURI(string calldata newDocumentationURI) external override onlyRole(ZONE_MANAGER_ROLE) {
        _documentationURI = newDocumentationURI;
    }

    /**
     * @dev Returns Seaport metadata for this contract, returning the
     *      contract name and supported schemas.
     *
     * @return name    The contract name.
     * @return schemas The supported SIPs.
     */
    function getSeaportMetadata()
        external
        view
        override(SIP5Interface, ZoneInterface)
        returns (string memory name, Schema[] memory schemas)
    {
        name = _ZONE_NAME;

        // supported SIP (7)
        schemas = new Schema[](1);
        schemas[0].id = 7;
        schemas[0].metadata = abi.encode(
            _domainSeparator(),
            _apiEndpoint,
            _getSupportedSubstandards(),
            _documentationURI
        );
    }

    /**
     * @notice Returns signing information about the zone.
     *
     * @return domainSeparator  The domain separator used for signing.
     * @return apiEndpoint      The API endpoint to get signatures for orders.
     * @return substandards     The supported substandards.
     * @return documentationURI The documentation URI.
     */
    function sip7Information()
        external
        view
        override
        returns (
            bytes32 domainSeparator,
            string memory apiEndpoint,
            uint256[] memory substandards,
            string memory documentationURI
        )
    {
        domainSeparator = _domainSeparator();
        apiEndpoint = _apiEndpoint;

        substandards = _getSupportedSubstandards();

        documentationURI = _documentationURI;
    }

    /**
     * @notice Check if a given order including extraData is currently valid.
     *
     * @dev This function is called by Seaport whenever any extraData is
     *      provided by the caller, before tokens have been transferred.
     *
     * @param zoneParameters             The zone parameters containing data related to
     *                                   the fulfilment execution.
     * @return authorizedOrderMagicValue A magic value indicating if the order
     *                                   is currently valid.
     */
    function authorizeOrder(
        ZoneParameters calldata zoneParameters
    ) external override returns (bytes4 authorizedOrderMagicValue) {
        // Put the extraData and orderHash on the stack for cheaper access.
        bytes calldata extraData = zoneParameters.extraData;
        bytes32 orderHash = zoneParameters.orderHash;

        // Revert with an error if the extraData is empty.
        if (extraData.length == 0) {
            revert InvalidExtraData("extraData is empty", orderHash);
        }

        // We expect the extraData to conform with SIP-6 as well as SIP-7
        // Therefore all SIP-7 related data is offset by one byte
        // SIP-7 specifically requires SIP-6 as a prerequisite.

        // Revert with an error if the extraData does not have valid length.
        if (extraData.length < 93) {
            revert InvalidExtraData("extraData length must be at least 93 bytes", orderHash);
        }

        // Revert if SIP-6 version is not accepted (0).
        if (uint8(extraData[0]) != _ACCEPTED_SIP6_VERSION) {
            revert UnsupportedExtraDataVersion(uint8(extraData[0]));
        }

        // extraData bytes 1-21: expected fulfiller.
        // (zero address means not restricted).
        address expectedFulfiller = address(bytes20(extraData[1:21]));

        // extraData bytes 21-29: expiration timestamp.
        uint64 expiration = uint64(bytes8(extraData[21:29]));

        // extraData bytes 29-93: signature.
        // (strictly requires 64 byte compact sig, ERC2098).
        bytes calldata signature = extraData[29:93];

        // extraData bytes 93-end: context (optional, variable length).
        bytes calldata context = extraData[93:];

        // Revert if expired.
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > expiration) {
            // solhint-disable-next-line not-rely-on-time
            revert SignatureExpired(block.timestamp, expiration, orderHash);
        }

        // Put fulfiller on the stack for more efficient access.
        address actualFulfiller = zoneParameters.fulfiller;

        // Revert unless:
        // - expected fulfiller is 0 address (any fulfiller) OR
        // - expected fulfiller is the same as actual fulfiller.
        if (expectedFulfiller != address(0) && expectedFulfiller != actualFulfiller) {
            revert InvalidFulfiller(expectedFulfiller, actualFulfiller, orderHash);
        }

        // Validate supported substandards - before hook validation.
        _validateSubstandards(context, zoneParameters, true);

        // Derive the signedOrder hash.
        bytes32 signedOrderHash = _deriveSignedOrderHash(expectedFulfiller, expiration, orderHash, context);

        // Derive the EIP-712 digest using the domain separator and signedOrder
        // hash through openzepplin helper.
        bytes32 digest = MessageHashUtils.toTypedDataHash(_domainSeparator(), signedOrderHash);

        // Recover the signer address from the digest and signature.
        // Pass in R and VS from compact signature (ERC2098).
        address recoveredSigner = ECDSA.recover(digest, bytes32(signature[0:32]), bytes32(signature[32:64]));

        // Revert if the signer is not active.
        // This also reverts if the digest constructed on serverside is incorrect.
        if (!_signers[recoveredSigner].active) {
            revert SignerNotActive(recoveredSigner);
        }

        // Pre hook validation completes and passes with no reverts, return valid.
        authorizedOrderMagicValue = ZoneInterface.authorizeOrder.selector;
    }

    /**
     * @notice Validates a fulfilment execution.
     *
     * @dev This function is called by Seaport whenever any extraData is
     *      provided by the caller, after tokens have been transferred.
     *
     * @param zoneParameters        The zone parameters containing data related to
     *                              the fulfilment execution.
     * @return validOrderMagicValue A magic value indicating if the order is
     *                              currently valid.
     */
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external pure override returns (bytes4 validOrderMagicValue) {
        // Put the extraData and orderHash on the stack for cheaper access.
        bytes calldata extraData = zoneParameters.extraData;

        // extraData bytes 93-end: context (optional, variable length).
        bytes calldata context = extraData[93:];

        // Validate supported substandards - after hook validation.
        _validateSubstandards(context, zoneParameters, false);

        // Pre hook validation completes and passes with no reverts, return valid.
        validOrderMagicValue = ZoneInterface.validateOrder.selector;
    }

    /**
     * @notice ERC-165 interface support.
     *
     * @param interfaceId The interface ID to check for support.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC165, ZoneInterface, AccessControlEnumerable) returns (bool) {
        return
            interfaceId == type(ZoneInterface).interfaceId ||
            interfaceId == type(SIP5Interface).interfaceId ||
            interfaceId == type(SIP7Interface).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Internal view function to get the EIP-712 domain separator. If the
     *      chainId matches the chainId set on deployment, the cached domain
     *      separator will be returned; otherwise, it will be derived from
     *      scratch.
     *
     * @return The domain separator.
     */
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == _CHAIN_ID ? _DOMAIN_SEPARATOR : _deriveDomainSeparator();
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return domainSeparator The derived domain separator.
     */
    function _deriveDomainSeparator() internal view returns (bytes32 domainSeparator) {
        return keccak256(abi.encode(_EIP_712_DOMAIN_TYPEHASH, _NAME_HASH, _VERSION_HASH, block.chainid, address(this)));
    }

    /**
     * @dev Get the supported substandards of the contract.
     *
     * @return substandards Array of substandards supported.
     */
    function _getSupportedSubstandards() internal pure returns (uint256[] memory substandards) {
        // support substandards 1, 3, 4 and 6
        substandards = new uint256[](4);
        substandards[0] = 1;
        substandards[1] = 3;
        substandards[2] = 4;
        substandards[3] = 6;
    }

    /**
     * @dev Derive the signedOrder hash from the orderHash and expiration.
     *
     * @param fulfiller        The expected fulfiller address.
     * @param expiration       The signature expiration timestamp.
     * @param orderHash        The order hash.
     * @param context          The optional variable-length context.
     * @return signedOrderHash The signedOrder hash.
     */
    function _deriveSignedOrderHash(
        address fulfiller,
        uint64 expiration,
        bytes32 orderHash,
        bytes calldata context
    ) internal pure returns (bytes32 signedOrderHash) {
        // Derive the signed order hash.
        signedOrderHash = keccak256(
            abi.encode(_SIGNED_ORDER_TYPEHASH, fulfiller, expiration, orderHash, keccak256(context))
        );
    }

    /**
     * @dev Validate substandards 3, 4 and 6 based on context.
     *
     * @param context        Bytes payload of context.
     * @param zoneParameters The zone parameters.
     */
    function _validateSubstandards(bytes calldata context, ZoneParameters calldata zoneParameters, bool before) internal pure {
        uint256 startIndex = 0;
        uint256 contextLength = context.length;

        // The ImmutableSignedZoneV3 contract enforces at least
        // one of the supported substandards is present in the context.
        if (contextLength == 0) {
            revert InvalidExtraData("invalid context, no substandards present", zoneParameters.orderHash);
        }

        // Each _validateSubstandard* function returns the length of the substandard
        // segment (0 if the substandard was not matched).
        startIndex = _validateSubstandard1(context[startIndex:], zoneParameters, before) + startIndex;

        if (startIndex == contextLength) return;
        startIndex = _validateSubstandard3(context[startIndex:], zoneParameters, before) + startIndex;

        if (startIndex == contextLength) return;
        startIndex = _validateSubstandard4(context[startIndex:], zoneParameters, before) + startIndex;

        if (startIndex == contextLength) return;
        startIndex = _validateSubstandard6(context[startIndex:], zoneParameters, before) + startIndex;

        if (startIndex != contextLength) {
            revert InvalidExtraData("invalid context, unexpected context length", zoneParameters.orderHash);
        }
    }

    /**
     * @dev Validates substandard 1.
     *
     * @param context        Bytes payload of context, 0 indexed to start of substandard segment.
     * @param zoneParameters The zone parameters.
     * @return               Length of substandard segment.
     */
    function _validateSubstandard1(
        bytes calldata context,
        ZoneParameters calldata zoneParameters,
        bool before
    ) internal pure returns (uint256) {
        if (uint8(context[0]) != 1) {
            return 0;
        }

        if (context.length < 33) {
            revert InvalidExtraData("invalid substandard 1 data length", zoneParameters.orderHash);
        }

        // Only perform validation in before hook.
        if (before) {
            if (uint256(bytes32(context[1:33])) != zoneParameters.consideration[0].identifier) {
                revert Substandard1Violation(zoneParameters.orderHash, zoneParameters.consideration[0].identifier, uint256(bytes32(context[1:33])));
            }
        }

        return 33;
    }

    /**
     * @dev Validates substandard 3. This substandard is used to validate that the server's
     *      specified received items matches the actual received items. This substandard
     *      should be used when the server is able to accurately determine the received items
     *      for an exact fulfilment scenario. This substandard should NOT be used for fulfilments
     *      where the received items cannot be accurately known in advance, as is the case in
     *      best-efforts partial fulfilment scenarios.
     *
     * @param context        Bytes payload of context, 0 indexed to start of substandard segment.
     * @param zoneParameters The zone parameters.
     * @return               Length of substandard segment.
     */
    function _validateSubstandard3(
        bytes calldata context,
        ZoneParameters calldata zoneParameters,
        bool before
    ) internal pure returns (uint256) {
        if (uint8(context[0]) != 3) {
            return 0;
        }

        if (context.length < 33) {
            revert InvalidExtraData("invalid substandard 3 data length", zoneParameters.orderHash);
        }

        // Only perform validation in before hook.
        if (before) {
            if (_deriveReceivedItemsHash(zoneParameters.consideration, 1, 1) != bytes32(context[1:33])) {
                revert Substandard3Violation(zoneParameters.orderHash);
            }
        }

        return 33;
    }

    /**
     * @dev Validates substandard 4. This substandard is used to validate that the server's
     *      specified orders that must be bundled with the fulfilment are present. This is useful
     *      for scenarios where the fulfiller desires a bundled fulfilment to revert if part of
     *      bundle is not available for fulfilment.
     *
     * @param context        Bytes payload of context, 0 indexed to start of substandard segment.
     * @param zoneParameters The zone parameters.
     * @return               Length of substandard segment.
     */
    function _validateSubstandard4(
        bytes calldata context,
        ZoneParameters calldata zoneParameters,
        bool before
    ) internal pure returns (uint256) {
        if (uint8(context[0]) != 4) {
            return 0;
        }

        // substandard ID + array offset + array length.
        if (context.length < 65) {
            revert InvalidExtraData("invalid substandard 4 data length", zoneParameters.orderHash);
        }

        uint256 expectedOrderHashesSize = uint256(bytes32(context[33:65]));
        uint256 substandardIndexEnd = 64 + (expectedOrderHashesSize * 32);

        // Only perform validation in after hook. Note that zoneParameters.orderHashes is only fully
        // populated in the after hook (validateOrder call).
        if (!before) {
            bytes32[] memory expectedOrderHashes = abi.decode(context[1:substandardIndexEnd + 1], (bytes32[]));

            // revert if any order hashes in substandard data are not present in zoneParameters.orderHashes.
            if (!_bytes32ArrayIncludes(zoneParameters.orderHashes, expectedOrderHashes)) {
                revert Substandard4Violation(zoneParameters.orderHashes, expectedOrderHashes, zoneParameters.orderHash);
            }
        }

        return substandardIndexEnd + 1;
    }

    /**
     * @dev Validates substandard 6. This substandard a variation on substandard 3 to support
     *      that supports fulfilments where server cannot accurately determine expected received
     *      items in advance, as is the case in best-efforts partial fulfilment scenarios.
     *
     * @param context        Bytes payload of context, 0 indexed to start of substandard segment.
     * @param zoneParameters The zone parameters.
     * @return               Length of substandard segment.
     */
    function _validateSubstandard6(
        bytes calldata context,
        ZoneParameters calldata zoneParameters,
        bool before
    ) internal pure returns (uint256) {
        if (uint8(context[0]) != 6) {
            return 0;
        }

        if (context.length < 65) {
            revert InvalidExtraData("invalid substandard 6 data length", zoneParameters.orderHash);
        }

        // Only perform validation in before hook.
        if (before) {
            // The first 32 bytes are the original first offer item amount.
            uint256 originalFirstOfferItemAmount = uint256(bytes32(context[1:33]));
            // The next 32 bytes are the hash of the received items that were expected
            // derived based on an assumption of full fulfilment (i.e. numerator = denominator = 1).
            bytes32 expectedReceivedItemsHash = bytes32(context[33:65]);

            // To support partial fulfilment scenarios, we must scale the actual received item amounts
            // to match the expected received items hash based on full fulfilment (i.e. numerator = denominator = 1).
            //
            // actualAmount = originalAmount * numerator / denominator
            // originalAmount = actualAmount * denominator / numerator
            //
            // The numerator and denominator values are inferred from the actual and original (extracted
            // from context) amounts of the first offer item.
            if (
                _deriveReceivedItemsHash(
                    zoneParameters.consideration,
                    originalFirstOfferItemAmount,
                    zoneParameters.offer[0].amount
                ) != expectedReceivedItemsHash
            ) {
                revert Substandard6Violation(
                    zoneParameters.offer[0].amount,
                    originalFirstOfferItemAmount,
                    zoneParameters.orderHash
                );
            }
        }

        return 65;
    }

    /**
     * @dev Derive the received items hash based on received item array.
     *
     * @param receivedItems            Actual received item array.
     * @param scalingFactorNumerator   Scaling factor numerator.
     * @param scalingFactorDenominator Scaling factor denominator.
     * @return receivedItemsHash       Hash of received items.
     */
    function _deriveReceivedItemsHash(
        ReceivedItem[] calldata receivedItems,
        uint256 scalingFactorNumerator,
        uint256 scalingFactorDenominator
    ) internal pure returns (bytes32) {
        uint256 numberOfItems = receivedItems.length;
        bytes memory receivedItemsHash = new bytes(0); // Explicitly initialize to empty bytes

        for (uint256 i; i < numberOfItems; i++) {
            receivedItemsHash = abi.encodePacked(
                receivedItemsHash,
                receivedItems[i].itemType,
                receivedItems[i].token,
                receivedItems[i].identifier,
                Math.mulDiv(receivedItems[i].amount, scalingFactorNumerator, scalingFactorDenominator),
                receivedItems[i].recipient
            );
        }

        return keccak256(receivedItemsHash);
    }

    /**
     * @dev Helper function to check if every element of values exists in sourceArray
     *      optimised for performance checking arrays sized 0-15.
     *
     * @param sourceArray Source array.
     * @param values      Values array.
     * @return            True if all elements in values exist in sourceArray.
     */
    function _bytes32ArrayIncludes(
        bytes32[] calldata sourceArray,
        bytes32[] memory values
    ) internal pure returns (bool) {
        // cache the length in memory for loop optimisation
        uint256 sourceArraySize = sourceArray.length;
        uint256 valuesSize = values.length;

        // we can assume all items are unique
        // therefore if values is bigger than superset sourceArray, return false
        if (valuesSize > sourceArraySize) {
            return false;
        }

        // Iterate through each element and compare them
        for (uint256 i = 0; i < valuesSize; ) {
            bool found = false;
            bytes32 item = values[i];
            for (uint256 j = 0; j < sourceArraySize; ) {
                if (item == sourceArray[j]) {
                    // if item from values is in sourceArray, break
                    found = true;
                    break;
                }
                unchecked {
                    j++;
                }
            }
            if (!found) {
                // if any item from values is not found in sourceArray, return false
                return false;
            }
            unchecked {
                i++;
            }
        }

        // All elements from values exist in sourceArray
        return true;
    }
}
