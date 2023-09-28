// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IRootERC20Bridge {
    function mapToken(IERC20Metadata rootToken) external payable returns (address);
}

interface IRootERC20BridgeEvents {
    event TokenMapped(address rootToken, address childToken);
}

interface IRootERC20BridgeErrors {
    error ZeroAddress();
    error AlreadyMapped();
}
