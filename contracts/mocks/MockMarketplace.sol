// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

contract MockMarketplace {
    error ZeroAddress();

    IERC721 public immutable tokenAddress;
    IERC2981 public immutable royaltyAddress;

    constructor(address _tokenAddress) {
        tokenAddress = IERC721(_tokenAddress);
        royaltyAddress = IERC2981(_tokenAddress);
    }

    function executeTransfer(address recipient, uint256 _tokenId) public {
        tokenAddress.transferFrom(msg.sender, recipient, _tokenId);
    }

    /// @notice This code is only for testing purposes. Do not use similar
    /// @notice constructions in production code as they are open to attack.
    /// @dev For details see: https://github.com/crytic/slither/wiki/Detector-Documentation#arbitrary-from-in-transferfrom
    function executeTransferFrom(address from, address to, uint256 _tokenId) public {
        // slither-disable-next-line arbitrary-send-erc20
        tokenAddress.transferFrom(from, to, _tokenId);
    }

    function executeApproveForAll(address operator, bool approved) public {
        tokenAddress.setApprovalForAll(operator, approved);
    }

    /// @notice This code is only for testing purposes. Do not use similar
    /// @notice constructions in production code as they are open to attack.
    /// @dev For details see: https://github.com/crytic/slither/wiki/Detector-Documentation#arbitrary-from-in-transferfrom
    function executeTransferRoyalties(address from, address recipient, uint256 _tokenId, uint256 price) public payable {
        if (from == address(0)) {
            revert ZeroAddress();
        }
        // solhint-disable-next-line custom-errors
        require(msg.value == price, "insufficient msg.value");
        (address receiver, uint256 royaltyAmount) = royaltyAddress.royaltyInfo(_tokenId, price);
        if (receiver == address(0)) {
            revert ZeroAddress();
        }
        uint256 sellerAmt = msg.value - royaltyAmount;
        payable(receiver).transfer(royaltyAmount);
        payable(from).transfer(sellerAmt);
        // slither-disable-next-line arbitrary-send-erc20
        tokenAddress.transferFrom(from, recipient, _tokenId);
    }
}
