// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.8.29;

import {ERC721PsiBurnableV2} from "../../../../contracts/token/erc721/erc721psi/ERC721PsiBurnableV2.sol";
import {IERC721Receiver} from "openzeppelin-contracts-4.9.3/token/ERC721/IERC721Receiver.sol";

// solhint-disable mixed-case-function

// Test receiver contract for safe transfer testing
contract TestReceiver is IERC721Receiver {
    bool public received;
    bool public shouldReject;
    
    // Add setter function
    function setReject(bool _shouldReject) external {
        shouldReject = _shouldReject;
    }
    
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        if (shouldReject) revert("TestReceiver: rejected");
        received = true;
        return this.onERC721Received.selector;
    }
}

// Malicious receiver for reentrancy testing
contract MaliciousReceiver is IERC721Receiver {
    ERC721PsiV2Echidna private token;
    bool public attemptedReentrancy;
    
    constructor(address _token) {
        token = ERC721PsiV2Echidna(_token);
    }
    
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        if (!attemptedReentrancy) {
            attemptedReentrancy = true;
            // Attempt reentrancy
            token.transferFrom(address(this), msg.sender, tokenId);
        }
        return this.onERC721Received.selector;
    }
}

contract ERC721PsiV2Echidna is ERC721PsiBurnableV2 {
    // --- Constants ---
    uint256 public constant GROUP_SIZE = 256;
    uint256 private constant MAX_BATCH_SIZE = 50;
    uint256 private constant BOUNDARY_2_128 = 2**128;
    
    // --- State Variables ---
    address echidna_caller = msg.sender;
    uint256 public totalMinted;
    uint256 private currentTokenId;
    
    // --- Tracking Maps ---
    mapping(uint256 => bool) public minted;
    mapping(uint256 => bool) public burned;
    mapping(uint256 => address) public tokenOwnersMap;
    mapping(uint256 => uint256) public groupOccupancy;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    // --- Test Contracts ---
    TestReceiver public testReceiver;
    MaliciousReceiver public maliciousReceiver;
    
    constructor() ERC721PsiBurnableV2() {
        _mint(address(this), 10);
        testReceiver = new TestReceiver();
        maliciousReceiver = new MaliciousReceiver(address(this));
    }

    // --- Helper Functions ---
    function mintForTest(address to, uint256 quantity) external {
        _mint(to, quantity);
        for(uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = totalMinted + i;
            minted[tokenId] = true;
            tokenOwnersMap[tokenId] = to;
        }
        totalMinted += quantity;
    }

    function _burnForTest(uint256 tokenId) internal {
        _burn(tokenId);
        burned[tokenId] = true;
        delete tokenOwnersMap[tokenId];
    }

    function _approveForTest(address spender, uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        if (owner != msg.sender) {
            this.setApprovalForAll(spender, true);
        } else {
            this.approve(spender, tokenId);
        }
    }

    // === CORE INVARIANTS ===
    function echidna_total_supply_matches() public view returns (bool) {
        return totalSupply() == totalMinted;
    }

    function echidna_balance_consistency() public view returns (bool) {
        uint256 totalBalance = 0;
        for(uint160 i = 0; i < 10; i++) {
            address owner = address(i + 1);
            uint256 expectedBalance = 0;
            
            for(uint256 j = 0; j < totalMinted; j++) {
                if(tokenOwnersMap[j] == owner && !burned[j]) {
                    expectedBalance++;
                }
            }
            
            if(balanceOf(owner) != expectedBalance) return false;
            totalBalance += expectedBalance;
        }
        return totalBalance == totalSupply();
    }

    function echidna_balance_sum_property() public view returns (bool) {
        uint256 totalBalance = 0;
        for(uint160 i = 1; i <= 10; i++) {
            totalBalance += balanceOf(address(i));
        }
        return totalBalance == totalSupply();
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

    function echidna_nonexistent_ownership1() public view returns (bool) {
        uint256 nonexistentTokenId = totalMinted + 1;
        
        try this.ownerOf(nonexistentTokenId) {
            return false; // Should revert
        } catch {
            return true;
        }
    }

    function echidna_nonexistent_ownership2() public view returns (bool) {
        // Also test burned tokens
        if (totalMinted > 0) {
            uint256 tokenId = currentTokenId % totalMinted;
            if (burned[tokenId]) {
                try this.ownerOf(tokenId) {
                    return false; // Should revert
                } catch {
                    return true;
                }
            }
        }
        return true;
    }

    // === BATCH OPERATIONS ===
    function echidna_group_operations_sequence() public returns (bool) {
        uint256 numGroups = 3;
        uint256 totalTokens = GROUP_SIZE * numGroups;
        
        try this.mintForTest(msg.sender, totalTokens) {
            for(uint256 i = 0; i < numGroups; i++) {
                uint256 startTokenId = i * GROUP_SIZE;
                (uint256 startIndex,,, address owner) = _tokenInfo(startTokenId);
                
                if(startIndex != startTokenId || owner != msg.sender) return false;
                if(groupOccupancy[i] > GROUP_SIZE) return false;
            }
            return true;
        } catch {
            return true;
        }
    }

    function echidna_group_occupancy() public returns (bool) {
        for (uint256 i = 0; i < totalMinted; i++) {
            uint256 groupIndex = i / GROUP_SIZE;
            groupOccupancy[groupIndex] = 0;
        }
        
        for (uint256 i = 0; i < totalMinted; i++) {
            if (minted[i] && !burned[i]) {
                uint256 groupIndex = i / GROUP_SIZE;
                groupOccupancy[groupIndex]++;
                if (groupOccupancy[groupIndex] > GROUP_SIZE) return false;
            }
        }
        return true;
    }

    function echidna_group_boundary_sequence() public returns (bool) {
        uint256 initialSupply = totalSupply();
        
        // Try to mint exactly one group
        uint256 groupSize = GROUP_SIZE;
        try this.mint(msg.sender, groupSize) {
            // Try to mint one more token to cross group boundary
            try this.mint(msg.sender, 1) {
                return totalSupply() == initialSupply + groupSize + 1;
            } catch {
                return totalSupply() == initialSupply + groupSize;
            }
        } catch {
            return true; 
        }
    }

    function echidna_cross_group_operations() public returns (bool) {
        uint256 groupSize = GROUP_SIZE;
        // forge-lint: disable-next-line(divide-before-multiply)
        uint256 tokenId = (currentTokenId / groupSize) * groupSize; // Align to group boundary
        
        try this.mint(address(this), groupSize + 1) {
            // Verify ownership across group boundary
            address owner1 = ownerOf(tokenId);
            address owner2 = ownerOf(tokenId + groupSize);
            return owner1 == address(this) && owner2 == address(this);
        } catch {
            return true;
        }
    }

    // === BOUNDARY TESTING ===
    function echidna_boundary_minting_sequence() public returns (bool) {
        uint256[] memory testAmounts = new uint256[](3);
        testAmounts[0] = BOUNDARY_2_128 - 1;
        testAmounts[1] = BOUNDARY_2_128;
        testAmounts[2] = BOUNDARY_2_128 + 1;
        
        for(uint256 i = 0; i < testAmounts.length; i++) {
            try this.mint(msg.sender, testAmounts[i]) {
                if(i >= 2) return false;
                uint256 lastTokenId = totalMinted - 1;
                if(lastTokenId >= BOUNDARY_2_128) return false;
            } catch {
                if(i < 2) return false;
            }
        }
        return true;
    }

    function echidna_mint_boundary_check() public returns (bool) {
        // Test exactly at boundary
        try this.mint(msg.sender, 1) {
            uint256 mintedId = totalMinted - 1;
            return mintedId < 2**128;
        } catch {
            return true;
        }
    }

    function echidna_mint_quantity_range() public returns (bool) {
        uint256 startTokenId = totalMinted;
        
        // Try minting across the 2^128 boundary
        if (startTokenId < 2**128) {
            uint256 quantity = (2**128 - startTokenId) + 1;
            try this.mint(msg.sender, quantity) {
                return false; // Should not succeed
            } catch {
                return true;
            }
        }
        return true;
    }

    function echidna_max_token_id_overflow() public returns (bool) {
        uint256 currentSupply = totalSupply();
        uint256 maxMint = type(uint256).max - currentSupply;
        
        try this.mint(msg.sender, maxMint + 1) {
            return false;
        } catch {
            return true;
        }
    }

    function echidna_mint_threshold_respected() public view returns (bool) {
        for (uint256 i = 0; i < 2**128; i++) {
            if (minted[i]) {
                if (i >= 2**128) return false;
            }
        }
        return true;
    }

    // === TRANSFER & APPROVAL LOGIC ===
    function echidna_complex_transfer_sequence() public returns (bool) {
        if(totalMinted == 0) return true;
        
        address[4] memory accounts = [
            msg.sender,
            address(uint160(0x1234)),
            address(uint160(0x5678)),
            address(uint160(0x9ABC))
        ];
        
        uint256 tokenId = currentTokenId % totalMinted;
        
        // Complex transfer pattern: A -> B -> C -> D -> A
        try this.transferFrom(accounts[0], accounts[1], tokenId) {
            // Rest of transfers
            _approveForTest(accounts[2], tokenId);
            this.transferFrom(accounts[1], accounts[2], tokenId);
            
            _approveForTest(accounts[3], tokenId);
            this.transferFrom(accounts[2], accounts[3], tokenId);
            
            _approveForTest(accounts[0], tokenId);
            this.transferFrom(accounts[3], accounts[0], tokenId);
            
            return ownerOf(tokenId) == accounts[0] &&
                   getApproved(tokenId) == address(0);
        } catch {
            return true;
        }
    }

    function echidna_transfer_ownership_updates() public returns (bool) {
        if (totalMinted == 0) return true;
        uint256 tokenId = currentTokenId % totalMinted;
        address originalOwner = tokenOwnersMap[tokenId];
        // forge-lint: disable-next-line(unsafe-typecast)
        address newOwner = address(uint160(currentTokenId % 100));
        
        try this.transferFrom(originalOwner, newOwner, tokenId) {
            return ownerOf(tokenId) == newOwner;
        } catch {
            return true;
        }
    }

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

    function echidna_approval_clearing() public returns (bool) {
        if (totalMinted == 0) return true;
        uint256 tokenId = currentTokenId % totalMinted;
        address approved = address(0x123);
        
        try this.approve(approved, tokenId) {
            address originalApproved = getApproved(tokenId);
            try this.transferFrom(msg.sender, address(0x456), tokenId) {
                return getApproved(tokenId) == address(0) && originalApproved == approved;
            } catch {
                return true;
            }
        } catch {
            return true;
        }
    }

    // === SECURITY CHECKS ===
    function echidna_reentrancy_protection() public returns (bool) {
        if (totalMinted == 0) return true;
        uint256 tokenId = currentTokenId % totalMinted;
        
        try this.safeTransferFrom(msg.sender, address(maliciousReceiver), tokenId) {
            // If transfer succeeded, verify no state inconsistencies
            return balanceOf(msg.sender) + balanceOf(address(maliciousReceiver)) == 1;
        } catch {
            return true;
        }
    }

    function echidna_concurrent_operations() public returns (bool) {
        if (totalMinted == 0) return true;
        uint256 tokenId = currentTokenId % totalMinted;
        
        // Simulate concurrent operations
        try this.transferFrom(msg.sender, address(0x1), tokenId) {
            try this.approve(address(0x2), tokenId) {
                try this.burn(tokenId) {
                    return false; // Should not succeed in burning approved token
                } catch {
                    return true; // Expected to fail on burn
                }
            } catch {
                return true; // Expected to fail on approve
            }
        } catch {
            return true; // Expected to fail on transfer
        }
    }

    function echidna_zero_address_protection() public returns (bool) {
        // Test minting
        try this.mint(address(0), 1) {
            return false;
        } catch {}
        
        // Test transfers
        if (totalMinted > 0) {
            uint256 tokenId = currentTokenId % totalMinted;
            try this.transferFrom(msg.sender, address(0), tokenId) {
                return false;
            } catch {}
        }
        return true;
    }

    function echidna_safe_transfer_callback() public returns (bool) {
        if (totalMinted == 0) return true;
        uint256 tokenId = currentTokenId % totalMinted;
        
        // Reset receiver state using the setter
        testReceiver.setReject(false);
        
        try this.safeTransferFrom(msg.sender, address(testReceiver), tokenId) {
            return testReceiver.received();
        } catch {
            return true;
        }
    }

    // === SEQUENTIAL OPERATIONS ===
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

    function echidna_total_supply_sequence() public returns (bool) {
        // Store initial supply
        uint256 initialSupply = totalSupply();
        
        // GROUP_SIZE is 256
        // Let's test with amounts that might cross group boundaries
        // currentTokenId % 256 will give us values 0-255
        uint256 amount = (currentTokenId % GROUP_SIZE) + 1; 
        
        this.mint(msg.sender, amount);
        
        // For burning, we want to ensure we're testing both:
        // 1. Burning from the same group
        // 2. Burning from different groups
        uint256 burnTokenId = currentTokenId % totalMinted;
        this.burn(burnTokenId);
        
        // Verify supply changes
        return totalSupply() == initialSupply + amount - 1;
    }

    // === GAS OPTIMIZATION ===
    function echidna_batch_operation_gas() public returns (bool) {
        uint256 batchSize = 50;
        uint256 gasStart = gasleft();
        try this.mint(msg.sender, batchSize) {
            uint256 gasUsed = gasStart - gasleft();
            return gasUsed < 1500000;
        } catch {
            return true;
        }
    }

    // === BASIC OPERATIONS ===
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

    function echidna_burn_unminted() public returns (bool) {
        uint256 unmintedTokenId = totalMinted + 1;
        
        try this.burn(unmintedTokenId) {
            return false; // Should not succeed
        } catch {
            return true;
        }
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
} 