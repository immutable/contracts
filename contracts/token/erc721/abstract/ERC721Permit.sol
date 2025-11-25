// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC4494} from "./IERC4494.sol";
import {ERC721, ERC721Burnable, IERC165} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
// Errors
import {IImmutableERC721Errors} from "../../../errors/Errors.sol";

/**
 * @title ERC721Permit: An extension of the ERC721Burnable NFT standard that supports off-chain approval via permits.
 * @dev This contract implements ERC-4494 as well, allowing tokens to be approved via off-chain signed messages.
 */
abstract contract ERC721Permit is ERC721Burnable, IERC4494, EIP712, IImmutableERC721Errors {
    /**
     * @notice mapping used to keep track of nonces of each token ID for validating
     *  signatures
     */
    mapping(uint256 tokenId => uint256 nonce) private _nonces;

    /**
     * @dev the unique identifier for the permit struct to be EIP 712 compliant
     */
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Permit(",
                "address spender,"
                "uint256 tokenId,"
                "uint256 nonce,"
                "uint256 deadline"
                ")"
            )
        );

    constructor(string memory name, string memory symbol) ERC721(name, symbol) EIP712(name, "1") {}

    /**
     * @notice Function to approve by way of owner signature
     * @param spender the address to approve
     * @param tokenId the index of the NFT to approve the spender on
     * @param deadline a timestamp expiry for the permit
     * @param sig a traditional or EIP-2098 signature
     */
    function permit(address spender, uint256 tokenId, uint256 deadline, bytes memory sig) external override {
        _permit(spender, tokenId, deadline, sig);
    }

    /**
     * @notice Returns the current nonce of a given token ID.
     * @param tokenId The ID of the token for which to retrieve the nonce.
     * @return Current nonce of the given token.
     */
    function nonces(uint256 tokenId) external view returns (uint256) {
        return _nonces[tokenId];
    }

    /**
     * @notice Returns the domain separator used in the encoding of the signature for permits, as defined by EIP-712
     * @return the bytes32 domain separator
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Overrides supportsInterface from IERC165 and ERC721Hybrid to add support for IERC4494.
     * @param interfaceId The interface identifier, which is a 4-byte selector.
     * @return True if the contract implements `interfaceId` and the call doesn't revert, otherwise false.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return
            interfaceId == type(IERC4494).interfaceId || // 0x5604e225
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Overrides the _transfer method from ERC721Hybrid to increment the nonce after a successful transfer.
     * @param from The address from which the token is being transferred.
     * @param to The address to which the token is being transferred.
     * @param tokenId The ID of the token being transferred.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual override(ERC721) {
        _nonces[tokenId]++;
        super._transfer(from, to, tokenId);
    }

    function _permit(address spender, uint256 tokenId, uint256 deadline, bytes memory sig) internal virtual {
        // solhint-disable-next-line not-rely-on-time
        if (deadline < block.timestamp) {
            revert PermitExpired();
        }

        bytes32 digest = _buildPermitDigest(spender, tokenId, deadline);

        // smart contract signature validation
        if (_isValidERC1271Signature(ownerOf(tokenId), digest, sig)) {
            _approve(spender, tokenId);
            return;
        }

        address recoveredSigner = address(0);

        // EOA signature validation
        if (sig.length == 64) {
            // ERC2098 compact signature - extract r and vs directly
            bytes32 r;
            bytes32 vs;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                r := mload(add(sig, 32))
                vs := mload(add(sig, 64))
            }
            recoveredSigner = ECDSA.recover(digest, r, vs);
        } else if (sig.length == 65) {
            // typical EDCSA Sig
            recoveredSigner = ECDSA.recover(digest, sig);
        } else {
            revert InvalidSignature();
        }

        if (_isValidEOASignature(recoveredSigner, tokenId)) {
            _approve(spender, tokenId);
        } else {
            revert InvalidSignature();
        }
    }

    /**
     * @notice Builds the EIP-712 compliant digest for the permit.
     * @param spender The address which is approved to spend the token.
     * @param tokenId The ID of the token for which the permit is being generated.
     * @param deadline The deadline until which the permit is valid.
     * @return A bytes32 digest, EIP-712 compliant, that serves as a unique identifier for the permit.
     */
    function _buildPermitDigest(address spender, uint256 tokenId, uint256 deadline) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(_PERMIT_TYPEHASH, spender, tokenId, _nonces[tokenId], deadline)));
    }

    /**
     * @notice Checks if a given signature is valid according to EIP-1271.
     * @param recoveredSigner The address which purports to have signed the message.
     * @param tokenId The token id.
     * @return True if the signature is from an approved operator or owner, otherwise false.
     */
    function _isValidEOASignature(address recoveredSigner, uint256 tokenId) private view returns (bool) {
        return recoveredSigner != address(0) && _isApprovedOrOwner(recoveredSigner, tokenId);
    }

    /**
     * @notice Checks if a given signature is valid according to EIP-1271.
     * @param spender The address which purports to have signed the message.
     * @param digest The EIP-712 compliant digest that was signed.
     * @param sig The actual signature bytes.
     * @return True if the signature is valid according to EIP-1271, otherwise false.
     */
    function _isValidERC1271Signature(address spender, bytes32 digest, bytes memory sig) private view returns (bool) {
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory res) = spender.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, digest, sig)
        );

        if (success && res.length == 32) {
            bytes4 decodedRes = abi.decode(res, (bytes4));
            if (decodedRes == IERC1271.isValidSignature.selector) {
                return true;
            }
        }

        return false;
    }
}
