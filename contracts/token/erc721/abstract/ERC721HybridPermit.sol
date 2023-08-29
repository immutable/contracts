// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./IERC4494.sol";
import "./ERC721Hybrid.sol";

abstract contract ERC721HybridPermit is ERC721Hybrid, Ownable, IERC4494, EIP712 {

    mapping(uint256 => uint256) private _nonces;

    bytes32 private constant _PERMIT_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(",
                "address spender,"
                "uint256 tokenId,"
                "uint256 nonce,"
                "uint256 deadline"
            ")"
        )
    );

    constructor(string memory name, string memory symbol)
        ERC721Hybrid(name, symbol)
        EIP712(name, "1")
    {}

    /**
     * @notice [ERC-4494] Function to approve by way of owner signature
     * @param spender the address to approve
     * @param tokenId the index of the NFT to approve the spender on
     * @param deadline a timestamp expiry for the permit
     * @param sig a traditional or EIP-2098 signature
     */
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        bytes memory sig
    ) external {
        if (deadline < block.timestamp) {
            revert PermitExpired();
        }

        bytes32 digest = _buildPermitDigest(spender, tokenId, deadline);
        address recoveredSigner;

        if (sig.length == 64) {
            // ERC2098 Sig
            recoveredSigner = ECDSA.recover(
                digest,
                bytes32(BytesLib.slice(sig, 0, 32)),
                bytes32(BytesLib.slice(sig, 32, 64))
            );
        } else if (sig.length == 65) {
            // typical EDCSA Sig
            recoveredSigner = ECDSA.recover(digest, sig);
        } else {
            revert InvalidSignature();
        }

        bool isNotZerothAddr = recoveredSigner != address(0);

        if (!isNotZerothAddr) {
            revert SignerCannotBeZerothAddress();
        }

        bool isApprovedOperator = _isApprovedOrOwner(recoveredSigner, tokenId);

        if (!isApprovedOperator) {
            revert NotOwner(tokenId);
        }

        bool isValidEOASig = isApprovedOperator && isNotZerothAddr;

        if (!isValidEOASig) {
            if (!_isValidERC1271Signature(getApproved(tokenId), digest, sig) &&
                !_isValidERC1271Signature(ownerOf(tokenId), digest, sig)
            ) {
                revert InvalidSignature();
            }
        }

        _approve(spender, tokenId);
    }

    /**
     * @notice [ERC-4494] Returns the nonce of an NFT - useful for creating permits
     * @param tokenId the index of the NFT to get the nonce of
     * @return the uint256 representation of the nonce
     */
    function nonces(
        uint256 tokenId
    ) external view returns (uint256) {
        return _nonces[tokenId];
    }

    /**
     * @notice [ERC-4494] Returns the domain separator used in the encoding of the signature for permits, as defined by EIP-712
     * @return the bytes32 domain separator
     */
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _buildPermitDigest(
        address spender,
        uint256 tokenId,
        uint256 deadline
    ) internal view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(
                    _PERMIT_TYPEHASH,
                    spender,
                    tokenId,
                    _nonces[tokenId],
                    deadline
                )
            )
        );
    }

    function _isValidERC1271Signature(address spender, bytes32 digest, bytes memory sig) private view returns(bool) {
        (bool success, bytes memory res) = spender.staticcall(
            abi.encodeWithSelector(
                IERC1271.isValidSignature.selector, 
                digest, 
                sig
            )
        );

        if (success && res.length == 32) {
            bytes4 decodedRes = abi.decode(res, (bytes4));
            if (decodedRes == IERC1271.isValidSignature.selector) {
                return true;
            }
        }
        
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(IERC165, ERC721Hybrid)
      returns (bool)
    {
     return
      interfaceId == type(IERC4494).interfaceId || // 0x5604e225
      super.supportsInterface(interfaceId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Hybrid){
        _nonces[tokenId]++;
        super._transfer(from, to, tokenId);
    }

}