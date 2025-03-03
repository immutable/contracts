// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0

pragma solidity >=0.8.19 <0.8.29;

import "forge-std/Test.sol";
import {ERC721BaseTest} from "../../../test/token/erc721/ERC721Base.t.sol";
import {IImmutableERC721} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {IImmutableERC721Structs} from "../../../contracts/token/erc721/interfaces/IImmutableERC721Structs.sol";


/**
 * Contract for all ERC 721 by quantity perfromance tests.
 */
abstract contract ERC721PerfTest is ERC721BaseTest {
    uint256 firstNftId = 0;
    uint256 lastNftId = 0;


    function setUp() public virtual override {
        setUpStart();
        setUpLastNft();
    }

    function setUpStart() public virtual {
        super.setUp();
    }

    /**
     * Allow this to be called separately as extending contracts might prefill 
     * the contract with lots of NFTs.
     */
    function setUpLastNft() public virtual {
        uint256 startId = mintLots(user1, 1000000000, 15000);
        lastNftId = startId + 14999;
        // uint256 startId = mintLots(user1, 1000000000, 1000);
        // lastNftId = startId + 999;
    }


    function testApprove1() public {
        uint256 gasStart = gasleft();
        vm.prank(prefillUser1);
        erc721.approve(user2, firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("approve gas (first)", gasStart - gasEnd);
    }
    function testApprove2() public {
        uint256 gasStart = gasleft();
        vm.prank(user1);
        erc721.approve(user2, lastNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("approve gas (last) ", gasStart - gasEnd);
    }

    function testBalanceOf1() public {
        uint256 gasStart = gasleft();
        erc721.balanceOf(user1);
        uint256 gasEnd = gasleft();
        emit log_named_uint("balanceOf user1", gasStart - gasEnd);
    }
    function testBalanceOf2() public {
        uint256 gasStart = gasleft();
        erc721.balanceOf(user2);
        uint256 gasEnd = gasleft();
        emit log_named_uint("balanceOf user2", gasStart - gasEnd);
    }
    function testBalanceOf3() public {
        uint256 gasStart = gasleft();
        erc721.balanceOf(prefillUser1);
        uint256 gasEnd = gasleft();
        emit log_named_uint("balanceOf prefi", gasStart - gasEnd);
    }

    function testBurn1() public {
        uint256 gasStart = gasleft();
        vm.prank(prefillUser1);
        erc721.burn(firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("burn (first)", gasStart - gasEnd);
    }
    function testBurn2() public {
        uint256 gasStart = gasleft();
        vm.prank(user1);
        erc721.burn(lastNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("burn (last) ", gasStart - gasEnd);
    }

    function testBurnWithApprove() public {
        vm.prank(prefillUser1);
        erc721.approve(user2, firstNftId);
        uint256 gasStart = gasleft();
        vm.prank(user2);
        erc721.burn(firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("burn (first)", gasStart - gasEnd);

        vm.prank(user1);
        erc721.approve(user2, lastNftId);
        gasStart = gasleft();
        vm.prank(user2);
        erc721.burn(lastNftId);
        gasEnd = gasleft();
        emit log_named_uint("burn (last) ", gasStart - gasEnd);
    }

    function testBurnBatch() public {
        uint256 first = mintLots(user3, 2000000000, 5000);

        uint256[] memory nfts = new uint256[](1500);
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = first + 100 + i;
        }

        uint256 gasStart = gasleft();
        vm.prank(user3);
        erc721.burnBatch(nfts);
        uint256 gasEnd = gasleft();
        emit log_named_uint("burnBatch (1500)", gasStart - gasEnd);
    }

    function testSafeBurnBatch() public {
        uint256 first = mintLots(user3, 2000000000, 5000);

        uint256[] memory nfts = new uint256[](1500);
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = first + 100 + i;
        }
        IImmutableERC721Structs.IDBurn memory burn = IImmutableERC721Structs.IDBurn(user3, nfts);
        IImmutableERC721Structs.IDBurn[] memory burns = new IImmutableERC721Structs.IDBurn[](1);
        burns[0] = burn;


        uint256 gasStart = gasleft();
        vm.prank(user3);
        erc721.safeBurnBatch(burns);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeBurnBatch (1500)", gasStart - gasEnd);
    }


    function testMint() public {
        uint256 nftId = 5000000001;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721.mint(user1, nftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("mint gas", gasStart - gasEnd);
    }

    function testSafeMint() public {
        uint256 nftId = 5000000001;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721.safeMint(user1, nftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeMint gas", gasStart - gasEnd);
    }

    function testMintBatch() public {
        uint256 gasUsed = _mintBatch(6000000000, 10);
        emit log_named_uint("mintBatch    10 NFTs gas", gasUsed);
        gasUsed = _mintBatch(6100000000, 100);
        emit log_named_uint("mintBatch   100 NFTs gas", gasUsed);
        gasUsed = _mintBatch(6200000000, 1000);
        emit log_named_uint("mintBatch  1000 NFTs gas", gasUsed);
        gasUsed = _mintBatch(6300000000, 5000);
        emit log_named_uint("mintBatch  5000 NFTs gas", gasUsed);
        gasUsed = _mintBatch(6400000000, 10000);
        emit log_named_uint("mintBatch 10000 NFTs gas", gasUsed);
    }
    function _mintBatch(uint256 _startId, uint256 _quantity) private returns(uint256) {
        uint256[] memory ids = new uint256[](_quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            ids[i] = i + _startId;
        }
        IImmutableERC721Structs.IDMint memory mint = IImmutableERC721Structs.IDMint(user1, ids);
        IImmutableERC721Structs.IDMint[] memory mints = new IImmutableERC721Structs.IDMint[](1);
        mints[0] = mint;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721.mintBatch(mints);
        uint256 gasEnd = gasleft();
        return gasStart - gasEnd;
    }

    function testSafeMintBatch() public {
        uint256 gasUsed = _safeMintBatch(6000000000, 10);
        emit log_named_uint("safeMintBatch    10 NFTs gas", gasUsed);
        gasUsed = _safeMintBatch(6100000000, 100);
        emit log_named_uint("safeMintBatch   100 NFTs gas", gasUsed);
        gasUsed = _safeMintBatch(6200000000, 1000);
        emit log_named_uint("safeMintBatch  1000 NFTs gas", gasUsed);
        gasUsed = _safeMintBatch(6300000000, 5000);
        emit log_named_uint("safeMintBatch  5000 NFTs gas", gasUsed);
        gasUsed = _safeMintBatch(6400000000, 10000);
        emit log_named_uint("safeMintBatch 10000 NFTs gas", gasUsed);
    }
    function _safeMintBatch(uint256 _startId, uint256 _quantity) private returns(uint256) {
        uint256[] memory ids = new uint256[](_quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            ids[i] = i + _startId;
        }
        IImmutableERC721Structs.IDMint memory mint = IImmutableERC721Structs.IDMint(user1, ids);
        IImmutableERC721Structs.IDMint[] memory mints = new IImmutableERC721Structs.IDMint[](1);
        mints[0] = mint;
        uint256 gasStart = gasleft();
        vm.prank(minter);
        erc721.safeMintBatch(mints);
        uint256 gasEnd = gasleft();
        return gasStart - gasEnd;
    }

    function testOwnerOf1() public {
        uint256 gasStart = gasleft();
        erc721.ownerOf(firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("ownerOf (first) gas", gasStart - gasEnd);
    }

    function testOwnerOf2() public {
        uint256 gasStart = gasleft();
        erc721.ownerOf(lastNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("ownerOf  (last) gas", gasStart - gasEnd);
    }

    function testTransferFrom1() public {
        // Add user to the allow list as the "is an EOA" check fails.
        address[] memory addrs = new address[](1);
        addrs[0] = prefillUser1;
        vm.prank(operatorAllowListRegistrar);
        allowlist.addAddressesToAllowlist(addrs);

        uint256 gasStart = gasleft();
        vm.prank(prefillUser1);
        erc721.transferFrom(prefillUser1, user1, firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("transferFrom (first) gas", gasStart - gasEnd);
    }

    function testTransferFrom2() public {
        // Add user to the allow list as the "is an EOA" check fails.
        address[] memory addrs = new address[](1);
        addrs[0] = user1;
        vm.prank(operatorAllowListRegistrar);
        allowlist.addAddressesToAllowlist(addrs);

        uint256 gasStart = gasleft();
        vm.prank(user1);
        erc721.transferFrom(user1, user2, lastNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("transferFrom  (last) gas", gasStart - gasEnd);
    }

    function testSafeTransferFrom1() public {
        // Add user to the allow list as the "is an EOA" check fails.
        address[] memory addrs = new address[](1);
        addrs[0] = prefillUser1;
        vm.prank(operatorAllowListRegistrar);
        allowlist.addAddressesToAllowlist(addrs);

        uint256 gasStart = gasleft();
        vm.prank(prefillUser1);
        erc721.safeTransferFrom(prefillUser1, user1, firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeTransferFrom (first) gas", gasStart - gasEnd);
    }

    function testSafeTransferFrom2() public {
        // Add user to the allow list as the "is an EOA" check fails.
        address[] memory addrs = new address[](1);
        addrs[0] = user1;
        vm.prank(operatorAllowListRegistrar);
        allowlist.addAddressesToAllowlist(addrs);

        uint256 gasStart = gasleft();
        vm.prank(user1);
        erc721.safeTransferFrom(user1, user2, lastNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeTransferFrom  (last) gas", gasStart - gasEnd);
    }

    function testSafeTransferFromBatch() public {
        // Add user to the allow list as the "is an EOA" check fails.
        address[] memory addrs = new address[](1);
        addrs[0] = prefillUser1;
        vm.prank(operatorAllowListRegistrar);
        allowlist.addAddressesToAllowlist(addrs);

        uint256 gasStart = gasleft();
        vm.prank(prefillUser1);
        erc721.safeTransferFrom(prefillUser1, user1, firstNftId);
        uint256 gasEnd = gasleft();
        emit log_named_uint("safeTransferFrom (first) gas", gasStart - gasEnd);
    }



    function testTotalSupply1() public {
        uint256 gasStart = gasleft();
        uint256 supply = erc721.totalSupply();
        uint256 gasEnd = gasleft();
        emit log_named_uint("totalSupply", supply);
        emit log_named_uint("totalSupply gas", gasStart - gasEnd);
    }

    function testTotalSupply2() public {
        uint256 startId = 100000000;
        for (uint256 i = 0; i < 10; i++) {
            uint256 actualStartId = mintLots(prefillUser1, startId, 1000);
            startId = actualStartId + 1000;
        }

        uint256 gasStart = gasleft();
        uint256 supply = erc721.totalSupply();
        uint256 gasEnd = gasleft();
        emit log_named_uint("totalSupply", supply);
        emit log_named_uint("totalSupply gas", gasStart - gasEnd);
    }

    function mintLots(address _recipient, uint256 _start, uint256 _quantity) public virtual returns (uint256) {
        uint256[] memory ids = new uint256[](_quantity);
        for (uint256 i = 0; i < _quantity; i++) {
            ids[i] = i + _start;
        }
        vm.recordLogs();
        IImmutableERC721Structs.IDMint memory mint = IImmutableERC721Structs.IDMint(_recipient, ids);
        IImmutableERC721Structs.IDMint[] memory mints = new IImmutableERC721Structs.IDMint[](1);
        mints[0] = mint;
        vm.prank(minter);
        erc721.mintBatch(mints);
        return findFirstNftId();
    }

    function findFirstNftId() internal returns (uint256) {
        bytes32 transferEventSig = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
        Vm.Log[] memory entries = vm.getRecordedLogs();
        // event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
        // In production, entries[0] is the Transfer event. However, there might be debug events 
        // being emitted during development.
        for (uint256 i = 0; i < entries.length; i++) {
            bytes32[] memory topics = entries[i].topics;
            if (topics[0] == transferEventSig) {
                return uint256(topics[3]);
            }
        }
        revert("No tranfer event found");
    }

    function prefillWithNfts() public virtual {
        uint256 startId = 10000;

        for (uint256 i = 0; i < 5; i++) {
            uint256 actualStartId = mintLots(prefillUser1, startId, 1000);
            startId = actualStartId + 1000;
        }
    }

}
