// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
import {IImmutableERC721} from "../../../contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {OperatorAllowlistUpgradeable} from "../../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {DeployOperatorAllowlist} from "../../utils/DeployAllowlistProxy.sol";


/**
 * Base contract for all ERC 721 tests.
 */
abstract contract ERC721BaseTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    string public constant BASE_URI = "https://baseURI.com/";
    string public constant CONTRACT_URI = "https://contractURI.com";
    string public constant NAME = "ERC721Preset";
    string public constant SYMBOL = "EP";


    IImmutableERC721 public erc721;

    OperatorAllowlistUpgradeable public allowlist;

    address public owner;
    address public feeReceiver;
    address public operatorAllowListAdmin;
    address public operatorAllowListUpgrader;
    address public operatorAllowListRegistrar;
    address public minter;

    string public name;
    string public symbol;
    string public baseURI;
    string public contractURI;
    uint96 public feeNumerator;

    address public user1;
    address public user2;
    address public user3;

    // Used in gas tests
    address public prefillUser1;



    function setUp() public virtual {
        owner = makeAddr("hubOwner");
        feeReceiver = makeAddr("feeReceiver");
        minter = makeAddr("minter");
        operatorAllowListAdmin = makeAddr("operatorAllowListAdmin");
        operatorAllowListUpgrader = makeAddr("operatorAllowListUpgrader");
        operatorAllowListRegistrar = makeAddr("operatorAllowListRegistrar");

        name = NAME;
        symbol = SYMBOL;
        baseURI = BASE_URI;
        contractURI = CONTRACT_URI;   
        feeNumerator = 200; // 2%     

        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        address proxyAddr = deployScript.run(operatorAllowListAdmin, operatorAllowListUpgrader, operatorAllowListRegistrar);
        allowlist = OperatorAllowlistUpgradeable(proxyAddr);

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");
        prefillUser1 = makeAddr("prefillUser1");
    }


    // Return the type of revert message of abi encoding if an NFT is attempted 
    // to be burned when it isn't owned.
    function notOwnedRevertError(uint256 _tokenIdToBeBurned) public pure virtual returns (bytes memory);

    function calcFee(uint256 _salePrice) public view returns(uint96) {
        return uint96(feeNumerator * _salePrice / 10000);
    }

    function mintSomeTokens() internal {
        vm.prank(minter);
        erc721.mint(user1, 1);
        vm.prank(minter);
        erc721.mint(user1, 2);
        vm.prank(minter);
        erc721.mint(user1, 3);
        vm.prank(minter);
        erc721.mint(user2, 5);
        vm.prank(minter);
        erc721.mint(user2, 6);
        assertEq(erc721.balanceOf(user1), 3);
        assertEq(erc721.balanceOf(user2), 2);
        assertEq(erc721.totalSupply(), 5);
    }
}
