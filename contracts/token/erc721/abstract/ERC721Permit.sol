// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./IERC4494.sol";
import "./ImmutableERC721Base.sol";

abstract contract ERC721Permit is ImmutableERC721Base, Ownable, IERC4494 {

    uint256 internal immutable _CHAIN_ID = block.chainid;
    bytes32 internal immutable _DOMAIN_SEPARATOR;
    bytes32 internal immutable _EIP_712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked(
            "EIP712Domain(",
            "string name,",
            "string version,",
            "uint256 chainId,",
            "address verifyingContract",
            ")"
        )
    );
    bytes32 internal _NAME_HASH;
    bytes32 internal immutable _VERSION_HASH = keccak256(bytes("1"));
    bytes32 public constant PERMIT_TYPEHASH = keccak256(
        abi.encodePacked(
            "Permit(",
            "address spender,"
            "uint256 tokenId,"
            "uint256 nonce,"
            "uint256 deadline"
            ")"
        )
    );

    mapping(uint256 => uint256) private _nonces;

    constructor(
        address owner,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address _royaltyAllowlist,
        address _receiver,
        uint96 _feeNumerator
    )
        ImmutableERC721Base(
            owner,
            name_,
            symbol_,
            baseURI_,
            contractURI_,
            _royaltyAllowlist,
            _receiver,
            _feeNumerator
        ) {
        _NAME_HASH = keccak256(bytes(name_));
        _DOMAIN_SEPARATOR = _deriveDomainSeparator();
    }

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
        console.log("NFT: permitting token", tokenId, "for", spender);
        if (deadline < block.timestamp) {
            revert PermitExpired();
        }

        bytes32 digest = _buildPermitDigest(spender, tokenId, deadline);
        address recoveredSigner;

        // Note: ERC-1271 should also be handled here
        if (sig.length == 64) {
            // ERC2098 signature
            recoveredSigner = ECDSA.recover(
                digest,
                bytes32(BytesLib.slice(sig, 0, 32)),
                bytes32(BytesLib.slice(sig, 32, 64))
            );
        } else if (sig.length == 65) {
            recoveredSigner = ECDSA.recover(digest, sig);
        } else {
            revert InvalidSignature();
        }

        if (recoveredSigner == address(0)) {
            revert SignerCannotBeZerothAddress();
        }

        if (recoveredSigner != ownerOf(tokenId)) {
            revert NotOwner(tokenId);
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
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            block.chainid == _CHAIN_ID
                ? _DOMAIN_SEPARATOR
                : _deriveDomainSeparator();
    }

    function _buildPermitDigest(
        address spender,
        uint256 tokenId,
        uint256 deadline
    ) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR(),
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    spender,
                    tokenId,
                    _nonces[tokenId],
                    deadline
                )
            )
        );
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        console.log("NFT: incrementing nonce before token", firstTokenId, "transfer");
        _nonces[firstTokenId]++;
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _deriveDomainSeparator() internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _EIP_712_DOMAIN_TYPEHASH,
                    _NAME_HASH,
                    _VERSION_HASH,
                    block.chainid,
                    address(this)
                )
            );
    }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(IERC165, ImmutableERC721Base)
    returns (bool)
  {
    return
      interfaceId == type(IERC4494).interfaceId || // 0x5604e225
      super.supportsInterface(interfaceId);
  }
}