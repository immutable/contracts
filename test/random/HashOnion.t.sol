// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import {HashOnion} from "contracts/random/HashOnion.sol";

contract HashOnionTest is Test {

    HashOnion hashOnion;

    bytes32 c0;
    bytes32 c1;
    bytes32 c2;
    bytes32 c3;
    bytes32 c4;
    bytes32 s;

    function setUp() public virtual {
        s = bytes32(uint256(17));
        c4 = keccak256(abi.encodePacked(s));
        c3 = keccak256(abi.encodePacked(c4));
        c2 = keccak256(abi.encodePacked(c3));
        c1 = keccak256(abi.encodePacked(c2));
        c0 = keccak256(abi.encodePacked(c1));
        
        hashOnion = new HashOnion(c0);
    }

    function testSequence() public {
        assertEq(hashOnion.commitment(), c0, "c0");
        hashOnion.reveal(c1);
        assertEq(hashOnion.commitment(), c1, "c1");
        hashOnion.reveal(c2);
        assertEq(hashOnion.commitment(), c2, "c2");
        hashOnion.reveal(c3);
        assertEq(hashOnion.commitment(), c3, "c3");
        hashOnion.reveal(c4);
        assertEq(hashOnion.commitment(), c4, "c4");
        hashOnion.reveal(s);
        assertEq(hashOnion.commitment(), s, "s");
    }

    function testBadValue() public {
        hashOnion.reveal(c1);
        vm.expectRevert(abi.encodeWithSelector(HashOnion.IncorrectPreimage.selector, c3, c1));
        hashOnion.reveal(c3);
    }
}
