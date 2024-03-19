// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import { IReceiver, Receipt } from "../IReceiver.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract StrictCurrencyReceiver is IReceiver {

    IERC721 public erc721;
    uint256 public purchasePrice;

    error OnlyNativeTokenPayments(address paymentToken);
    error OnlyExactPayments(uint256 paymentAmount);

    constructor(IERC721 _erc721, uint256 _purchasePrice) {
        erc721 = _erc721;
        purchasePrice = _purchasePrice;
    }

    function onPaymentProcessed(Receipt memory receipt) external {

        if (receipt.paidToken != address(0)) {
            revert OnlyNativeTokenPayments(receipt.paidToken);
        }

        if (receipt.paidAmount != purchasePrice) {
            revert OnlyExactPayments(receipt.paidAmount);
        }

        // erc721.mint(1, receipt.order.recipient);
    }

}
