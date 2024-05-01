// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {ImmutableERC721} from "contracts/token/erc721/preset/ImmutableERC721.sol";

contract ImmutableERC721ForkTest is Test {
    ImmutableERC721 public erc721;
    address chronoForgeERC721 = 0xa88D707ddF0878b6B1d6833F9954a5A9573481Ee;

    address public owner;
    string name;
    string symbol;
    uint256 baseURI;
    uint256 contractURI;
    address operatorAllowList;
    address royaltyReceiver;
    uint96 feeNumerator;

    uint256 zkEvmMainnetFork;

    function setUp() public virtual {
        zkEvmMainnetFork = vm.createFork("https://rpc.immutable.com");
        vm.selectFork(zkEvmMainnetFork);
        erc721 = ImmutableERC721(address(chronoForgeERC721));
    }

    function testSymbol() public {
        assertEq(erc721.symbol(), "CFRP", "symbol");
    }

    function testBalanceOf_0xA654b48E5a9e58A8626F81168FEBA1B3AB4AF4EF() view public {
        testBalanceOf(0xA654b48E5a9e58A8626F81168FEBA1B3AB4AF4EF);
    }


    function testBalanceOf(address _account) private view {
        uint256 balance = erc721.balanceOf(_account);
        console.log("Balance of %s is: %s", _account, balance);
    }

}
