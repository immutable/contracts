// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {ITransferValidator} from "creator-token-standards/interfaces/ITransferValidator.sol";

contract MockTransferValidator is ITransferValidator {
    bool private _shouldRevertApplyCollectionTransferPolicy = false;
    bool private _shouldRevertValidateTransfer = false;
    bool private _shouldRevertValidateTransferWithTokenId = false;
    bool private _shouldRevertValidateTransferWithTokenIdAndAmount = false;
    bool private _shouldRevertBeforeAuthorizedTransferWithOperatorAndTokenId = false;
    bool private _shouldRevertAfterAuthorizedTransferWithTokenId = false;
    bool private _shouldRevertBeforeAuthorizedTransferWithOperator = false;
    bool private _shouldRevertAfterAuthorizedTransfer = false;
    bool private _shouldRevertBeforeAuthorizedTransferWithTokenId = false;
    bool private _shouldRevertBeforeAuthorizedTransferWithAmount = false;
    bool private _shouldRevertAfterAuthorizedTransferWithAmount = false;

    function revertApplyCollectionTransferPolicy() public {
        _shouldRevertApplyCollectionTransferPolicy = true;
    }

    function revertValidateTransfer() public {
        _shouldRevertValidateTransfer = true;
    }

    function revertValidateTransferWithTokenId() public {
        _shouldRevertValidateTransferWithTokenId = true;
    }

    function revertValidateTransferWithTokenIdAndAmount() public {
        _shouldRevertValidateTransferWithTokenIdAndAmount = true;
    }

    function revertBeforeAuthorizedTransferWithOperatorAndTokenId() public {
        _shouldRevertBeforeAuthorizedTransferWithOperatorAndTokenId = true;
    }

    function revertAfterAuthorizedTransferWithTokenId() public {
        _shouldRevertAfterAuthorizedTransferWithTokenId = true;
    }

    function revertBeforeAuthorizedTransferWithOperator() public {
        _shouldRevertBeforeAuthorizedTransferWithOperator = true;
    }

    function revertAfterAuthorizedTransfer() public {
        _shouldRevertAfterAuthorizedTransfer = true;
    }

    function revertBeforeAuthorizedTransferWithTokenId() public {
        _shouldRevertBeforeAuthorizedTransferWithTokenId = true;
    }

    function revertBeforeAuthorizedTransferWithAmount() public {
        _shouldRevertBeforeAuthorizedTransferWithAmount = true;
    }

    function revertAfterAuthorizedTransferWithAmount() public {
        _shouldRevertAfterAuthorizedTransferWithAmount = true;
    }

    function applyCollectionTransferPolicy(address /* caller */, address /* from */, address /* to */) external view override {
        if (_shouldRevertApplyCollectionTransferPolicy) {
            revert MockTransferValidatorRevert("applyCollectionTransferPolicy(address caller, address from, address to)");
        }
    }

    function validateTransfer(address /* caller */, address /* from */, address /* to */) external view override {
        if (_shouldRevertValidateTransfer) {
            revert MockTransferValidatorRevert("validateTransfer(address caller, address from, address to)");
        }
    }

    function validateTransfer(address /* caller */, address /* from */, address /* to */, uint256 /* tokenId */) external view override {
        if (_shouldRevertValidateTransferWithTokenId) {
            revert MockTransferValidatorRevert("validateTransfer(address caller, address from, address to, uint256 tokenId)");
        }
    }

    function validateTransfer(address /* caller */, address /* from */, address /* to */, uint256 /* tokenId */, uint256 /* amount */) external view override {
        if (_shouldRevertValidateTransferWithTokenIdAndAmount) {
            revert MockTransferValidatorRevert("validateTransfer(address caller, address from, address to, uint256 tokenId, uint256 amount)");
        }
    }

    function beforeAuthorizedTransfer(address /* operator */, address /* token */, uint256 /* tokenId */) external view override {
        if (_shouldRevertBeforeAuthorizedTransferWithOperatorAndTokenId) {
            revert MockTransferValidatorRevert("beforeAuthorizedTransfer(address operator, address token, uint256 tokenId)");
        }
    }

    function afterAuthorizedTransfer(address /* token */, uint256 /* tokenId */) external view override {
        if (_shouldRevertAfterAuthorizedTransferWithTokenId) {
            revert MockTransferValidatorRevert("afterAuthorizedTransfer(address token, uint256 tokenId)");
        }
    }

    function beforeAuthorizedTransfer(address /* operator */, address /* token */) external view override {
        if (_shouldRevertBeforeAuthorizedTransferWithOperator) {
            revert MockTransferValidatorRevert("beforeAuthorizedTransfer(address operator, address token)");
        }
    }

    function afterAuthorizedTransfer(address /* token */) external view override {
        if (_shouldRevertAfterAuthorizedTransfer) {
            revert MockTransferValidatorRevert("afterAuthorizedTransfer(address token)");
        }
    }

    function beforeAuthorizedTransfer(address /* token */, uint256 /* tokenId */) external view override {
        if (_shouldRevertBeforeAuthorizedTransferWithTokenId) {
            revert MockTransferValidatorRevert("beforeAuthorizedTransfer(address token, uint256 tokenId)");
        }
    }

    function beforeAuthorizedTransferWithAmount(address /* token */, uint256 /* tokenId */, uint256 /* amount */) external view override {
        if (_shouldRevertBeforeAuthorizedTransferWithAmount) {
            revert MockTransferValidatorRevert("beforeAuthorizedTransferWithAmount(address token, uint256 tokenId, uint256 amount)");
        }
    }

    function afterAuthorizedTransferWithAmount(address /* token */, uint256 /* tokenId */) external view override {
        if (_shouldRevertAfterAuthorizedTransferWithAmount) {
            revert MockTransferValidatorRevert("afterAuthorizedTransferWithAmount(address token, uint256 tokenId)");
        }
    }
}

error MockTransferValidatorRevert(string functionDefinition);
