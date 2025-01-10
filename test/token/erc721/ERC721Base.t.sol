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
    address public royaltyReceiver;
    uint96 public feeNumerator;

    address public user1;
    address public user2;

    function setUp() public virtual {
        owner = makeAddr("hubOwner");
        feeReceiver = makeAddr("feeReceiver");
        minter = makeAddr("minter");
        operatorAllowListAdmin = makeAddr("operatorAllowListAdmin");
        operatorAllowListUpgrader = makeAddr("operatorAllowListUpgrader");
        operatorAllowListRegistrar = makeAddr("operatorAllowListRegistrar");

        name = "ERC721Preset";
        symbol = "EP";
        baseURI = "https://baseURI.com/";
        contractURI = "https://contractURI.com";        

        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        address proxyAddr = deployScript.run(operatorAllowListAdmin, operatorAllowListUpgrader, operatorAllowListRegistrar);
        allowlist = OperatorAllowlistUpgradeable(proxyAddr);

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }
}
