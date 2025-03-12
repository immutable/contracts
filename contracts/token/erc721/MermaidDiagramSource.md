# ERC 721 Mermaid Diagram Source

This file contains source code to be used with mermaid.live's online diagramming tool.

## ImmutableERC721V2

Source code for `preset/ImmutableERC721V2.sol`.

```
classDiagram
    class IERC721 {
        <<Interface>>
    }

    class IERC721Metadata {
        <<Interface>>
    }

    class ERC721 {
        getApproved(uint256)
        name()
        setApprovalForAll(address, bool)
        symbol()
        tokenURI(uint256)
    }

    class EIP712 {
        eip712Domain()        
    }

    class ERC2981 {
        royaltyInfo(uint256, uint256)
    }

    class ERC721HybridV2 {
        approve(address, uint256)
        balanceOf(address)
        burn(uint256)
        burnBatch(uint256[])
        exists(uint256)
        getApproved(uint256)
        isApprovedForAll(address, address)
        ownerOf(uint256 tokenId)
        safeBurn(address, uint256)
        safeTransferFrom(address, address, uint256)
        safeTransferFrom(address, address, uint256, bytes)
        totalSupply()
        transferFrom(address, address, uint256)
    }

    class ERC721PSIV2 {
        mintBatchByQuantityThreshold()
        mintBatchByQuantityNextTokenId()
    }

    class ERC721PSIBurnableV2 {
    }

    class ERC721HybridPermitV2 {
        permit(address, uint256, uint256, uint8, bytes32, bytes32)
        nonces(uint256)
        DOMAIN_SEPARATOR()
    }

    class ImmutableERC721HybridBaseV2 {
        contractURI()
        baseURI()
        setApprovalForAll(address, bool)
        setBaseURI(string)
        setContractURI(string)
        setDefaultRoyaltyReceiver(address, uint96)
        setNFTRoyaltyReceiver(uint256, address, uint96)
        setNFTRoyaltyReceiverBatch(uint256[], address, uint96)
        supportsInterface(bytes4)
    }

    class ImmutableERC721V2 {
        mint(address, uint256)
        mintBatch(IDMint[])
        mintBatchByQuantity(Mint[])
        mintByQuantity(address, uint256)
        safeBurnBatch(IDBurn[])
        safeMint(address, uint256)
        safeMintBatch(IDMint[])
        safeMintBatchByQuantity(Mint[])
        safeMintByQuantity(address, uint256)
        safeTransferFromBatch(TransferRequest)
    }

    class OperatorAllowlistEnforced {
        operatorAllowlist()
    }

    class AccessControl {
        getRoleAdmin(bytes32)
        grantRole(bytes32, address)
        hasRole(bytes32, address)
        renounceRole(bytes32, address)
        revokeRole(bytes32, address)
        DEFAULT_ADMIN_ROLE()
    }


    class AccessControlEnumerable {
        getRoleMember(bytes32, uint256)
        getRoleMemberCount(bytes32)
    }


    class MintingAccessControl {
        getAdmins()
        grantMinterRole(address)
        revokeMinterRole(address)
        MINTER_ROLE()
    }

    IERC721 <|-- ERC721
    IERC721Metadata <|-- ERC721

    IERC721 <|-- ERC721PSIV2
    IERC721Metadata <|-- ERC721PSIV2

    ERC721PSIV2 <|-- ERC721PSIBurnableV2

    ERC721PSIBurnableV2 <|-- ERC721HybridV2
    ERC721 <|-- ERC721HybridV2
    IImmutableERC721Structs <|-- ERC721HybridV2
    IImmutableERC721Errors <|-- ERC721HybridV2

    ERC721HybridV2 <|-- ERC721HybridPermitV2
    IERC4494 <|-- ERC721HybridPermitV2
    EIP712 <|-- ERC721HybridPermitV2

    AccessControl <|-- AccessControlEnumerable

    AccessControlEnumerable  <|-- MintingAccessControl

    OperatorAllowlistEnforcementErrors <|-- OperatorAllowlistEnforced


    ERC721HybridPermitV2 <|-- ImmutableERC721HybridBaseV2
    MintingAccessControl  <|-- ImmutableERC721HybridBaseV2
    OperatorAllowlistEnforced  <|-- ImmutableERC721HybridBaseV2
    ERC2981  <|-- ImmutableERC721HybridBaseV2

    ImmutableERC721HybridBaseV2 <|-- ImmutableERC721V2
```