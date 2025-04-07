// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2
pragma solidity >=0.8.19 <0.8.29;

import "forge-std/Script.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ImmutableERC721MintByIDUpgradeableV3} from
    "../../contracts/token/erc721/preset/ImmutableERC721MintByIDUpgradeableV3.sol";
import {ImmutableERC721MintByIDBootstrapV3} from
    "../../contracts/token/erc721/preset/ImmutableERC721MintByIDBootstrapV3.sol";

contract DeployBootstrapERC721V3 is Script {
    function run() public {
        address owner = vm.envAddress("OWNER_ADDRESS");
        string memory name = vm.envString("NAME");
        string memory symbol = vm.envString("SYMBOL");
        string memory baseURI = vm.envString("BASEURI");
        string memory contractURI = vm.envString("CONTRACTURI");
        address operatorAllowlist = vm.envAddress("OAL");
        address royaltyReceiver = vm.envAddress("ROYALTY_ADDRESS");
        uint96 feeNumerator = uint96(vm.envUint("FEE"));

        bytes memory initData = abi.encodeWithSelector(
            ImmutableERC721MintByIDUpgradeableV3.initialize.selector,
            owner,
            name,
            symbol,
            baseURI,
            contractURI,
            operatorAllowlist,
            royaltyReceiver,
            feeNumerator
        );

        vm.broadcast();
        ImmutableERC721MintByIDBootstrapV3 bootstrap = new ImmutableERC721MintByIDBootstrapV3();
        vm.broadcast();
        ImmutableERC721MintByIDUpgradeableV3 impl = new ImmutableERC721MintByIDUpgradeableV3();

        vm.broadcast();
        ERC1967Proxy proxy = new ERC1967Proxy(address(bootstrap), initData);

        console.log("ERC721 V3 Implementation address: %x", address(impl));
        console.log("Bootstrap Implementation address: %x", address(bootstrap));
        console.log("Proxy address: %x", address(proxy));
    }
}
