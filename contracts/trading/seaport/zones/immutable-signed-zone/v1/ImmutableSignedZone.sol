// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2

// slither-disable-start missing-inheritance
// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {ZoneParameters, Schema, ReceivedItem} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {ZoneInterface} from "seaport/contracts/interfaces/ZoneInterface.sol";
import {SIP7Interface} from "./interfaces/SIP7Interface.sol";
import {SIP7EventsAndErrors} from "./interfaces/SIP7EventsAndErrors.sol";
import {SIP6EventsAndErrors} from "./interfaces/SIP6EventsAndErrors.sol";
import {SIP5Interface} from "./interfaces/SIP5Interface.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title  ImmutableSignedZone
 * @author Immutable
 * @notice ImmutableSignedZone is a zone implementation based on the
 *         SIP-7 standard https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-7.md
 *         Implementing substandard 3 and 4.
 *
 *         Inspiration and reference from the following contracts:
 *         https://github.com/ProjectOpenSea/seaport/blob/024dcc5cd70231ce6db27b4e12ea6fb736f69b06/contracts/zones/SignedZone.sol
 *         - We notably deviate from this contract by implementing substandard 3, and SIP-6.
 *         https://github.com/reservoirprotocol/seaport-oracle/blob/master/packages/contracts/src/zones/SignedZone.sol
 *         - We deviate from this contract by going with a no assembly code reference contract approach, and we do not have a substandard
 *           prefix as part of the context bytes of extraData.
 *         - We estimate that for a standard validateOrder call with 10 consideration items, this contract consumes 1.9% more gas than the above
 *           as a tradeoff for having no assembly code.
 */
contract ImmutableSignedZone is
    ERC165,
    SIP7EventsAndErrors,
    SIP6EventsAndErrors,
    ZoneInterface,
    SIP5Interface,
    SIP7Interface,
    Ownable
{
    /// @dev The EIP-712 digest parameters.
    bytes32 internal immutable _VERSION_HASH = keccak256(bytes("1.0"));
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH =
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

    bytes32 internal immutable _SIGNED_ORDER_TYPEHASH =
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

    bytes internal constant CONSIDERATION_BYTES =
        abi.encodePacked("Consideration(", "ReceivedItem[] consideration", ")");

    bytes internal constant RECEIVED_ITEM_BYTES =
        abi.encodePacked(
            "ReceivedItem(",
            "uint8 itemType,",
            "address token,",
            "uint256 identifier,",
            "uint256 amount,",
            "address recipient",
            ")"
        );

    bytes32 internal constant RECEIVED_ITEM_TYPEHASH = keccak256(RECEIVED_ITEM_BYTES);

    bytes32 internal constant CONSIDERATION_TYPEHASH =
        keccak256(abi.encodePacked(CONSIDERATION_BYTES, RECEIVED_ITEM_BYTES));

    uint256 internal immutable _CHAIN_ID = block.chainid;
    bytes32 internal immutable _DOMAIN_SEPARATOR;
    uint8 internal immutable _ACCEPTED_SIP6_VERSION = 0;

    /// @dev The name for this zone returned in getSeaportMetadata().
    // solhint-disable-next-line var-name-mixedcase
    string private _ZONE_NAME;

    // slither-disable-start immutable-states
    // solhint-disable-next-line var-name-mixedcase
    bytes32 internal _NAME_HASH;
    // slither-disable-end immutable-states

    /// @dev The allowed signers.
    // solhint-disable-next-line named-parameters-mapping
    mapping(address => SignerInfo) private _signers;

    /// @dev The API endpoint where orders for this zone can be signed.
    ///      Request and response payloads are defined in SIP-7.
    string private _sip7APIEndpoint;

    /// @dev The documentationURI;
    string private _documentationURI;

    /**
     * @notice Constructor to deploy the contract.
     *
     * @param zoneName    The name for the zone returned in
     *                    getSeaportMetadata().
     * @param apiEndpoint The API endpoint where orders for this zone can be
     *                    signed.
     *                    Request and response payloads are defined in SIP-7.
     * @param owner       The address of the owner of this contract. Specified in the
     *                    constructor to be CREATE2 / CREATE3 compatible.
     */
    constructor(string memory zoneName, string memory apiEndpoint, string memory documentationURI, address owner) {
        // Set the zone name.
        _ZONE_NAME = zoneName;
        // set name hash
        _NAME_HASH = keccak256(bytes(zoneName));

        // Set the API endpoint.
        _sip7APIEndpoint = apiEndpoint;
        _documentationURI = documentationURI;

        // Derive and set the domain separator.
        _DOMAIN_SEPARATOR = _deriveDomainSeparator();

        // Emit an event to signal a SIP-5 contract has been deployed.
        emit SeaportCompatibleContractDeployed();

        // Transfer ownership to the address specified in the constructor
        _transferOwnership(owner);
    }

    /**
     * @notice Add a new signer to the zone.
     *
     * @param signer The new signer address to add.
     */
    function addSigner(address signer) external override onlyOwner {
        // Do not allow the zero address to be added as a signer.
        if (signer == address(0)) {
            revert SignerCannotBeZeroAddress();
        }

        // Revert if the signer is already added.
        if (_signers[signer].active) {
            revert SignerAlreadyActive(signer);
        }

        // Revert if the signer was previously authorized.
        // Specified in SIP-7 to prevent compromised signer from being
        // Cycled back into use.
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
    function removeSigner(address signer) external override onlyOwner {
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
     * @notice Check if a given order including extraData is currently valid.
     *
     * @dev This function is called by Seaport whenever any extraData is
     *      provided by the caller.
     *
     * @return validOrderMagicValue A magic value indicating if the order is
     *                              currently valid.
     */
    function validateOrder(
        ZoneParameters calldata zoneParameters
    ) external view override returns (bytes4 validOrderMagicValue) {
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

        // Revert if SIP6 version is not accepted (0)
        if (uint8(extraData[0]) != _ACCEPTED_SIP6_VERSION) {
            revert UnsupportedExtraDataVersion(uint8(extraData[0]));
        }

        // extraData bytes 1-21: expected fulfiller
        // (zero address means not restricted)
        address expectedFulfiller = address(bytes20(extraData[1:21]));

        // extraData bytes 21-29: expiration timestamp (uint64)
        uint64 expiration = uint64(bytes8(extraData[21:29]));

        // extraData bytes 29-93: signature
        // (strictly requires 64 byte compact sig, ERC2098)
        bytes calldata signature = extraData[29:93];

        // extraData bytes 93-end: context (optional, variable length)
        bytes calldata context = extraData[93:];

        // Revert if expired.
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > expiration) {
            // solhint-disable-next-line not-rely-on-time
            revert SignatureExpired(block.timestamp, expiration, orderHash);
        }

        // Put fulfiller on the stack for more efficient access.
        address actualFulfiller = zoneParameters.fulfiller;

        // Revert unless
        // Expected fulfiller is 0 address (any fulfiller) or
        // Expected fulfiller is the same as actual fulfiller
        if (expectedFulfiller != address(0) && expectedFulfiller != actualFulfiller) {
            revert InvalidFulfiller(expectedFulfiller, actualFulfiller, orderHash);
        }

        // validate supported substandards (3,4)
        _validateSubstandards(context, _deriveConsiderationHash(zoneParameters.consideration), zoneParameters);

        // Derive the signedOrder hash
        bytes32 signedOrderHash = _deriveSignedOrderHash(expectedFulfiller, expiration, orderHash, context);

        // Derive the EIP-712 digest using the domain separator and signedOrder
        // hash through openzepplin helper
        bytes32 digest = ECDSA.toTypedDataHash(_domainSeparator(), signedOrderHash);

        // Recover the signer address from the digest and signature.
        // Pass in R and VS from compact signature (ERC2098)
        address recoveredSigner = ECDSA.recover(digest, bytes32(signature[0:32]), bytes32(signature[32:64]));

        // Revert if the signer is not active
        // !This also reverts if the digest constructed on serverside is incorrect
        if (!_signers[recoveredSigner].active) {
            revert SignerNotActive(recoveredSigner);
        }

        // All validation completes and passes with no reverts, return valid
        validOrderMagicValue = ZoneInterface.validateOrder.selector;
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
     * @dev Returns Seaport metadata for this contract, returning the
     *      contract name and supported schemas.
     *
     * @return name    The contract name
     * @return schemas The supported SIPs
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
            keccak256(abi.encode(_domainSeparator(), _sip7APIEndpoint, _getSupportedSubstandards(), _documentationURI))
        );
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
     * @notice Update the API endpoint returned by this zone.
     *
     * @param newApiEndpoint The new API endpoint.
     */
    function updateAPIEndpoint(string calldata newApiEndpoint) external override onlyOwner {
        // Update to the new API endpoint.
        _sip7APIEndpoint = newApiEndpoint;
    }

    /**
     * @notice Returns signing information about the zone.
     *
     * @return domainSeparator The domain separator used for signing.
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
        apiEndpoint = _sip7APIEndpoint;

        substandards = _getSupportedSubstandards();

        documentationURI = _documentationURI;
    }

    /**
     * @dev validate substandards 3 and 4 based on context
     *
     * @param context bytes payload of context
     */
    function _validateSubstandards(
        bytes calldata context,
        bytes32 actualConsiderationHash,
        ZoneParameters calldata zoneParameters
    ) internal pure {
        // substandard 3 - validate consideration hash actual match expected

        // first 32bytes of context must be exactly a keccak256 hash of consideration item array
        if (context.length < 32) {
            revert InvalidExtraData(
                "invalid context, expecting consideration hash followed by order hashes",
                zoneParameters.orderHash
            );
        }

        // revert if order hash in context and payload do not match
        bytes32 expectedConsiderationHash = bytes32(context[0:32]);
        if (expectedConsiderationHash != actualConsiderationHash) {
            revert SubstandardViolation(3, "invalid consideration hash", zoneParameters.orderHash);
        }

        // substandard 4 - validate order hashes actual match expected

        // byte 33 to end are orderHashes array for substandard 4
        bytes calldata orderHashesBytes = context[32:];
        // context must be a multiple of 32 bytes
        if (orderHashesBytes.length % 32 != 0) {
            revert InvalidExtraData(
                "invalid context, order hashes bytes not an array of bytes32 hashes",
                zoneParameters.orderHash
            );
        }

        // compute expected order hashes array based on context bytes
        bytes32[] memory expectedOrderHashes = new bytes32[](orderHashesBytes.length / 32);
        for (uint256 i = 0; i < orderHashesBytes.length / 32; i++) {
            expectedOrderHashes[i] = bytes32(orderHashesBytes[i * 32:i * 32 + 32]);
        }

        // revert if order hashes in context and payload do not match
        // every expected order hash need to exist in fulfilling order hashes
        if (!_everyElementExists(expectedOrderHashes, zoneParameters.orderHashes)) {
            revert SubstandardViolation(4, "invalid order hashes", zoneParameters.orderHash);
        }
    }

    /**
     * @dev get the supported substandards of the contract
     *
     * @return substandards array of substandards supported
     *
     */
    function _getSupportedSubstandards() internal pure returns (uint256[] memory substandards) {
        // support substandards 3 and 4
        substandards = new uint256[](2);
        substandards[0] = 3;
        substandards[1] = 4;
    }

    /**
     * @dev Derive the signedOrder hash from the orderHash and expiration.
     *
     * @param fulfiller  The expected fulfiller address.
     * @param expiration The signature expiration timestamp.
     * @param orderHash  The order hash.
     * @param context    The optional variable-length context.
     *
     * @return signedOrderHash The signedOrder hash.
     *
     */
    function _deriveSignedOrderHash(
        address fulfiller,
        uint64 expiration,
        bytes32 orderHash,
        bytes calldata context
    ) internal view returns (bytes32 signedOrderHash) {
        // Derive the signed order hash.
        signedOrderHash = keccak256(
            abi.encode(_SIGNED_ORDER_TYPEHASH, fulfiller, expiration, orderHash, keccak256(context))
        );
    }

    /**
     * @dev Derive the EIP712 consideration hash based on received item array
     * @param consideration expected consideration array
     */
    function _deriveConsiderationHash(ReceivedItem[] calldata consideration) internal pure returns (bytes32) {
        uint256 numberOfItems = consideration.length;
        bytes32[] memory considerationHashes = new bytes32[](numberOfItems);
        for (uint256 i; i < numberOfItems; i++) {
            considerationHashes[i] = keccak256(
                abi.encode(
                    RECEIVED_ITEM_TYPEHASH,
                    consideration[i].itemType,
                    consideration[i].token,
                    consideration[i].identifier,
                    consideration[i].amount,
                    consideration[i].recipient
                )
            );
        }
        return keccak256(abi.encode(CONSIDERATION_TYPEHASH, keccak256(abi.encodePacked(considerationHashes))));
    }

    /**
     * @dev helper function to check if every element of array1 exists in array2
     *  optimised for performance checking arrays sized 0-15
     *
     * @param array1 subset array
     * @param array2 superset array
     */
    function _everyElementExists(bytes32[] memory array1, bytes32[] calldata array2) internal pure returns (bool) {
        // cache the length in memory for loop optimisation
        uint256 array1Size = array1.length;
        uint256 array2Size = array2.length;

        // we can assume all items (order hashes) are unique
        // therefore if subset is bigger than superset, revert
        if (array1Size > array2Size) {
            return false;
        }

        // Iterate through each element and compare them
        for (uint256 i = 0; i < array1Size; ) {
            bool found = false;
            bytes32 item = array1[i];
            for (uint256 j = 0; j < array2Size; ) {
                if (item == array2[j]) {
                    // if item from array1 is in array2, break
                    found = true;
                    break;
                }
                unchecked {
                    j++;
                }
            }
            if (!found) {
                // if any item from array1 is not found in array2, return false
                return false;
            }
            unchecked {
                i++;
            }
        }

        // All elements from array1 exist in array2
        return true;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, ZoneInterface) returns (bool) {
        return interfaceId == type(ZoneInterface).interfaceId || super.supportsInterface(interfaceId);
    }
}
// slither-disable-end missing-inheritance
