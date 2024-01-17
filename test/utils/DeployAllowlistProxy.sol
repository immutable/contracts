// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";

contract DeployOperatorAllowlist {
    function run(address admin, address upgradeAdmin) external returns (address) {
        OperatorAllowlistUpgradeable impl = new OperatorAllowlistUpgradeable();

        bytes memory initData = abi.encodeWithSelector(
            OperatorAllowlistUpgradeable.initialize.selector,
            admin,
            upgradeAdmin
        );

        ERC1967Proxy proxy = new ERC1967Proxy(
            address(impl),
            initData
        );

        return address(proxy);
    }
}