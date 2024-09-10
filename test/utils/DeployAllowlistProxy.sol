// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {OperatorAllowlistUpgradeable} from "../../contracts/allowlist/OperatorAllowlistUpgradeable.sol";

/// Deploys the OperatorAllowlistUpgradeable contract behind an ERC1967 Proxy and returns the address of the proxy
contract DeployOperatorAllowlist {
    function run(address admin, address upgradeAdmin, address registerarAdmin) external returns (address) {
        OperatorAllowlistUpgradeable impl = new OperatorAllowlistUpgradeable();

        bytes memory initData = abi.encodeWithSelector(
            OperatorAllowlistUpgradeable.initialize.selector, admin, upgradeAdmin, registerarAdmin
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), initData);

        return address(proxy);
    }
}
