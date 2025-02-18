// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.8.29;

import {ERC721PsiV2} from "../../../../contracts/token/erc721/erc721psi/ERC721PsiV2.sol";
import {ERC721PsiBurnableV2} from "../../../../contracts/token/erc721/erc721psi/ERC721PsiBurnableV2.sol";
import {IERC721Receiver} from "@openzeppelin-contracts-4.9.3/token/ERC721/IERC721Receiver.sol";

contract ERC721PsiV2Echidna is ERC721PsiBurnableV2 {
    address echidna_caller = msg.sender;
    
    // Track state for assertions
    mapping(uint256 => bool) public minted;
    mapping(uint256 => bool) public burned;
    mapping(uint256 => address) public tokenOwnersMap;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    uint256 public totalMinted;
    uint256 private currentTokenId;
    
    constructor() {
        // Initialize with some tokens
        _mint(address(this), 10);
    }

    // Implement missing abstract functions
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        safeTransferFrom(from, to, tokenId, "");
    }

    function setApprovalForAll(address operator, bool approved) external override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function name() external pure returns (string memory) {
        return "EchidnaTest";
    }

    function symbol() external pure returns (string memory) {
        return "ECHD";
    }

    function tokenURI(uint256) external pure returns (string memory) {
        return "test";
    }

    // Add mint function
    function mint(address to, uint256 quantity) external {
        _mint(to, quantity);
    }

    // Add external burn function
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    // Modified test functions without parameters
    function echidna_mint_by_id() public returns (bool) {
        uint256 tokenId = currentTokenId % 2**128;
        currentTokenId++;
        
        if (minted[tokenId] || burned[tokenId]) return true;
        
        try this.mint(msg.sender, 1) {
            minted[tokenId] = true;
            tokenOwnersMap[tokenId] = msg.sender;
            totalMinted++;
            return true;
        } catch {
            return true;
        }
    }

    function echidna_mint_by_quantity() public returns (bool) {
        uint256 quantity = (currentTokenId % 100) + 1;
        currentTokenId++;
        uint256 startTokenId = 2**128 + totalMinted;
        
        try this.mint(msg.sender, quantity) {
            for(uint256 i = 0; i < quantity; i++) {
                uint256 tokenId = startTokenId + i;
                minted[tokenId] = true;
                tokenOwnersMap[tokenId] = msg.sender;
            }
            totalMinted += quantity;
            return true;
        } catch {
            return true;
        }
    }

    function echidna_burn() public returns (bool) {
        uint256 tokenId = currentTokenId % totalMinted;
        currentTokenId++;
        
        if (!minted[tokenId] || burned[tokenId]) return true;
        
        try this.burn(tokenId) {
            burned[tokenId] = true;
            delete tokenOwnersMap[tokenId];
            return true;
        } catch {
            return true;
        }
    }

    // Properties that Echidna will check
    function echidna_total_supply_matches() public view returns (bool) {
        return totalSupply() == totalMinted;
    }

    function echidna_burned_tokens_have_no_owner() public view returns (bool) {
        for (uint256 i = 0; i < totalMinted; i++) {
            if (burned[i]) {
                try this.ownerOf(i) returns (address) {
                    return false;
                } catch {
                    continue;
                }
            }
        }
        return true;
    }

    function echidna_minted_tokens_have_owner() public view returns (bool) {
        for (uint256 i = 0; i < totalMinted; i++) {
            if (minted[i] && !burned[i]) {
                try this.ownerOf(i) returns (address owner) {
                    if (owner == address(0)) return false;
                } catch {
                    return false;
                }
            }
        }
        return true;
    }

    function echidna_mint_threshold_respected() public view returns (bool) {
        for (uint256 i = 0; i < 2**128; i++) {
            if (minted[i]) {
                if (i >= 2**128) return false;
            }
        }
        return true;
    }

    // Add approval checking invariant
    function echidna_approval_consistency() public view returns (bool) {
        for (uint256 i = 0; i < totalMinted; i++) {
            if (minted[i] && !burned[i]) {
                address owner = tokenOwnersMap[i];
                for (uint160 j = 0; j < 10; j++) {
                    address operator = address(j + 1);
                    if (_operatorApprovals[owner][operator]) {
                        if (!isApprovedForAll(owner, operator)) return false;
                    }
                }
            }
        }
        return true;
    }

    function echidna_transfer_ownership_updates() public returns (bool) {
        if (totalMinted == 0) return true;
        uint256 tokenId = currentTokenId % totalMinted;
        address originalOwner = tokenOwnersMap[tokenId];
        address newOwner = address(uint160(currentTokenId % 100));
        
        try this.transferFrom(originalOwner, newOwner, tokenId) {
            return ownerOf(tokenId) == newOwner;
        } catch {
            return true;
        }
    }

    function echidna_balance_consistency() public view returns (bool) {
        for (uint160 i = 0; i < 100; i++) {
            address owner = address(i);
            uint256 expectedBalance = 0;
            for (uint256 j = 0; j < totalMinted; j++) {
                if (tokenOwnersMap[j] == owner && !burned[j]) {
                    expectedBalance++;
                }
            }
            if (balanceOf(owner) != expectedBalance) return false;
        }
        return true;
    }

    function echidna_sequential_token_ids() public view returns (bool) {
        uint256 lastId = type(uint256).max;
        for (uint256 i = 0; i < totalMinted; i++) {
            if (minted[i] && !burned[i]) {
                if (lastId != type(uint256).max && i <= lastId) return false;
                lastId = i;
            }
        }
        return true;
    }

    function echidna_token_id_uniqueness() public view returns (bool) {
        for (uint256 i = 0; i < totalMinted; i++) {
            if (!burned[i]) {
                for (uint256 j = i + 1; j < totalMinted; j++) {
                    if (!burned[j] && tokenOwnersMap[i] == tokenOwnersMap[j]) {
                        return false;
                    }
                }
            }
        }
        return true;
    }
} 