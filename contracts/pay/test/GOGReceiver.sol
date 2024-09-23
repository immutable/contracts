// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import { IReceiver, Receipt } from "../IReceiver.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IProcessor } from "../IProcessor.sol";

/*
GOG wishes to sell packs for fixed amount of USDC. 
GOG is happy to receive either USDC or GOG, where the GOG must be equal to USDC at the current exchange rate.
They might consider also accepting ETH and IMX in future. 
All other currencies must be swapped to USDC before payment is made.
*/

contract GOGReceiver is IReceiver, Ownable {

    IERC721 public erc721;
    address public pricingCurrency;
    uint256 public price;
    IProcessor public processor;

    error Placeholder();

    mapping(address currency => bool supported) public supportedCurrencies;

    constructor(IProcessor _processor, IERC721 _erc721, address _pricingCurrency, uint256 _price) {
        processor = _processor;
        erc721 = _erc721;
        pricingCurrency = _pricingCurrency;
        price = _price;
    }

    function setCurrencySupported(address currency, bool supported) external onlyOwner {
        supportedCurrencies[currency] = supported;
    }

    function onPaymentProcessed(Receipt memory receipt) external {

        uint256 quantity = _decodeQuantity(receipt.order.extraData);

        if (msg.sender != address(processor)) {
            revert Placeholder();
        }

        if (!supportedCurrencies[receipt.paidToken]) {
            revert Placeholder();
        }

        uint256 totalCost = quantity * price;

        if (receipt.paidToken == pricingCurrency) {
            // the user directly paid in USDC
            if (totalCost > receipt.paidAmount) {
                revert Placeholder();
            }
        } else {
            // the user paid in another supported currency
            uint256 quote = processor.getQuote(receipt.paidToken, pricingCurrency, totalCost);
            if (quote > receipt.paidAmount) {
                revert Placeholder();
            }
        }

        // erc721.mint(1, receipt.order.recipient);
    }

    function _decodeQuantity(bytes memory data) internal view returns (uint256) {
        uint256 quantity;
        assembly {
            // skip first 32 bytes (stores the length of the bytes array)
            quantity := mload(add(data, 32))
        }
        return quantity;
    }

}
