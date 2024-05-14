// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {MockMarketplace} from "../../contracts/mocks/MockMarketplace.sol";

/// Deploys the OperatorAllowlistUpgradeable contract behind an ERC1967 Proxy and returns the address of the proxy
contract DeployMockMarketPlace {
    function run(address erc721Address) external returns (MockMarketplace) {
        MockMarketplace marketplace = new MockMarketplace(erc721Address);
        return marketplace;
    }
}
