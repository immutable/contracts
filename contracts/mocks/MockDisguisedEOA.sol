// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.8.29;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

// Used in CREATE2 vector
contract MockDisguisedEOA {
    IERC721 public immutable TOKEN_ADDRESS;

    constructor(IERC721 _tokenAddress) {
        TOKEN_ADDRESS = _tokenAddress;
    }

    /// @notice This code is only for testing purposes. Do not use similar
    /// @notice constructions in production code as they are open to attack.
    /// @dev For details see: https://github.com/crytic/slither/wiki/Detector-Documentation#arbitrary-from-in-transferfrom
    function executeTransfer(address from, address recipient, uint256 _tokenId) external {
        // slither-disable-next-line arbitrary-send-erc20
        TOKEN_ADDRESS.transferFrom(from, recipient, _tokenId);
    }
}
