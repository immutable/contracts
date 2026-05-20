// Copyright (c) Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache-2

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.17;

import {ITransferValidator} from "@limitbreak/creator-token-standards/src/interfaces/ITransferValidator.sol";

contract MockTransferValidator is ITransferValidator {
    bool private _shouldRevertApplyCollectionTransferPolicy = false;
    address private _revertApplyCollectionTransferPolicyCaller;
    address private _revertApplyCollectionTransferPolicyFrom;
    address private _revertApplyCollectionTransferPolicyTo;

    bool private _shouldRevertValidateTransfer = false;
    address private _revertValidateTransferCaller;
    address private _revertValidateTransferFrom;
    address private _revertValidateTransferTo;

    bool private _shouldRevertValidateTransferWithTokenId = false;
    address private _revertValidateTransferWithTokenIdCaller;
    address private _revertValidateTransferWithTokenIdFrom;
    address private _revertValidateTransferWithTokenIdTo;
    uint256 private _revertValidateTransferWithTokenIdTokenId;

    bool private _shouldRevertValidateTransferWithTokenIdAndAmount = false;
    address private _revertValidateTransferWithTokenIdAndAmountCaller;
    address private _revertValidateTransferWithTokenIdAndAmountFrom;
    address private _revertValidateTransferWithTokenIdAndAmountTo;
    uint256 private _revertValidateTransferWithTokenIdAndAmountTokenId;
    uint256 private _revertValidateTransferWithTokenIdAndAmountAmount;

    bool private _shouldRevertBeforeAuthorizedTransferWithOperatorAndTokenId = false;
    address private _revertBeforeAuthorizedTransferWithOperatorAndTokenIdOperator;
    address private _revertBeforeAuthorizedTransferWithOperatorAndTokenIdToken;
    uint256 private _revertBeforeAuthorizedTransferWithOperatorAndTokenIdTokenId;

    bool private _shouldRevertAfterAuthorizedTransferWithTokenId = false;
    address private _revertAfterAuthorizedTransferWithTokenIdToken;
    uint256 private _revertAfterAuthorizedTransferWithTokenIdTokenId;

    bool private _shouldRevertBeforeAuthorizedTransferWithOperator = false;
    address private _revertBeforeAuthorizedTransferWithOperatorOperator;
    address private _revertBeforeAuthorizedTransferWithOperatorToken;

    bool private _shouldRevertAfterAuthorizedTransfer = false;
    address private _revertAfterAuthorizedTransferToken;

    bool private _shouldRevertBeforeAuthorizedTransferWithTokenId = false;
    address private _revertBeforeAuthorizedTransferWithTokenIdToken;
    uint256 private _revertBeforeAuthorizedTransferWithTokenIdTokenId;

    bool private _shouldRevertBeforeAuthorizedTransferWithAmount = false;
    address private _revertBeforeAuthorizedTransferWithAmountToken;
    uint256 private _revertBeforeAuthorizedTransferWithAmountTokenId;
    uint256 private _revertBeforeAuthorizedTransferWithAmountAmount;

    bool private _shouldRevertAfterAuthorizedTransferWithAmount = false;
    address private _revertAfterAuthorizedTransferWithAmountToken;
    uint256 private _revertAfterAuthorizedTransferWithAmountTokenId;

    function revertApplyCollectionTransferPolicy(address caller, address from, address to) public {
        _shouldRevertApplyCollectionTransferPolicy = true;
        _revertApplyCollectionTransferPolicyCaller = caller;
        _revertApplyCollectionTransferPolicyFrom = from;
        _revertApplyCollectionTransferPolicyTo = to;
    }

    function revertValidateTransfer(address caller, address from, address to) public {
        _shouldRevertValidateTransfer = true;
        _revertValidateTransferCaller = caller;
        _revertValidateTransferFrom = from;
        _revertValidateTransferTo = to;
    }

    function revertValidateTransferWithTokenId(address caller, address from, address to, uint256 tokenId) public {
        _shouldRevertValidateTransferWithTokenId = true;
        _revertValidateTransferWithTokenIdCaller = caller;
        _revertValidateTransferWithTokenIdFrom = from;
        _revertValidateTransferWithTokenIdTo = to;
        _revertValidateTransferWithTokenIdTokenId = tokenId;
    }

    function revertValidateTransferWithTokenIdAndAmount(address caller, address from, address to, uint256 tokenId, uint256 amount) public {
        _shouldRevertValidateTransferWithTokenIdAndAmount = true;
        _revertValidateTransferWithTokenIdAndAmountCaller = caller;
        _revertValidateTransferWithTokenIdAndAmountFrom = from;
        _revertValidateTransferWithTokenIdAndAmountTo = to;
        _revertValidateTransferWithTokenIdAndAmountTokenId = tokenId;
        _revertValidateTransferWithTokenIdAndAmountAmount = amount;
    }

    function revertBeforeAuthorizedTransferWithOperatorAndTokenId(address operator, address token, uint256 tokenId) public {
        _shouldRevertBeforeAuthorizedTransferWithOperatorAndTokenId = true;
        _revertBeforeAuthorizedTransferWithOperatorAndTokenIdOperator = operator;
        _revertBeforeAuthorizedTransferWithOperatorAndTokenIdToken = token;
        _revertBeforeAuthorizedTransferWithOperatorAndTokenIdTokenId = tokenId;
    }

    function revertAfterAuthorizedTransferWithTokenId(address token, uint256 tokenId) public {
        _shouldRevertAfterAuthorizedTransferWithTokenId = true;
        _revertAfterAuthorizedTransferWithTokenIdToken = token;
        _revertAfterAuthorizedTransferWithTokenIdTokenId = tokenId;
    }

    function revertBeforeAuthorizedTransferWithOperator(address operator, address token) public {
        _shouldRevertBeforeAuthorizedTransferWithOperator = true;
        _revertBeforeAuthorizedTransferWithOperatorOperator = operator;
        _revertBeforeAuthorizedTransferWithOperatorToken = token;
    }

    function revertAfterAuthorizedTransfer(address token) public {
        _shouldRevertAfterAuthorizedTransfer = true;
        _revertAfterAuthorizedTransferToken = token;
    }

    function revertBeforeAuthorizedTransferWithTokenId(address token, uint256 tokenId) public {
        _shouldRevertBeforeAuthorizedTransferWithTokenId = true;
        _revertBeforeAuthorizedTransferWithTokenIdToken = token;
        _revertBeforeAuthorizedTransferWithTokenIdTokenId = tokenId;
    }

    function revertBeforeAuthorizedTransferWithAmount(address token, uint256 tokenId, uint256 amount) public {
        _shouldRevertBeforeAuthorizedTransferWithAmount = true;
        _revertBeforeAuthorizedTransferWithAmountToken = token;
        _revertBeforeAuthorizedTransferWithAmountTokenId = tokenId;
        _revertBeforeAuthorizedTransferWithAmountAmount = amount;
    }

    function revertAfterAuthorizedTransferWithAmount(address token, uint256 tokenId) public {
        _shouldRevertAfterAuthorizedTransferWithAmount = true;
        _revertAfterAuthorizedTransferWithAmountToken = token;
        _revertAfterAuthorizedTransferWithAmountTokenId = tokenId;
    }

    function applyCollectionTransferPolicy(address caller, address from, address to) external view override {
        if (
            _shouldRevertApplyCollectionTransferPolicy &&
            caller == _revertApplyCollectionTransferPolicyCaller &&
            from == _revertApplyCollectionTransferPolicyFrom &&
            to == _revertApplyCollectionTransferPolicyTo
        ) {
            revert MockTransferValidatorRevert("applyCollectionTransferPolicy(address caller, address from, address to)");
        }
    }

    function validateTransfer(address caller, address from, address to) external view override {
        if (
            _shouldRevertValidateTransfer &&
            caller == _revertValidateTransferCaller &&
            from == _revertValidateTransferFrom &&
            to == _revertValidateTransferTo
        ) {
            revert MockTransferValidatorRevert("validateTransfer(address caller, address from, address to)");
        }
    }

    function validateTransfer(address caller, address from, address to, uint256 tokenId) external view override {
        if (
            _shouldRevertValidateTransferWithTokenId &&
            caller == _revertValidateTransferWithTokenIdCaller &&
            from == _revertValidateTransferWithTokenIdFrom &&
            to == _revertValidateTransferWithTokenIdTo &&
            tokenId == _revertValidateTransferWithTokenIdTokenId
        ) {
            revert MockTransferValidatorRevert("validateTransfer(address caller, address from, address to, uint256 tokenId)");
        }
    }

    function validateTransfer(address caller, address from, address to, uint256 tokenId, uint256 amount) external view override {
        if (
            _shouldRevertValidateTransferWithTokenIdAndAmount &&
            caller == _revertValidateTransferWithTokenIdAndAmountCaller &&
            from == _revertValidateTransferWithTokenIdAndAmountFrom &&
            to == _revertValidateTransferWithTokenIdAndAmountTo &&
            tokenId == _revertValidateTransferWithTokenIdAndAmountTokenId &&
            amount == _revertValidateTransferWithTokenIdAndAmountAmount
        ) {
            revert MockTransferValidatorRevert("validateTransfer(address caller, address from, address to, uint256 tokenId, uint256 amount)");
        }
    }

    function beforeAuthorizedTransfer(address operator, address token, uint256 tokenId) external view override {
        if (
            _shouldRevertBeforeAuthorizedTransferWithOperatorAndTokenId &&
            operator == _revertBeforeAuthorizedTransferWithOperatorAndTokenIdOperator &&
            token == _revertBeforeAuthorizedTransferWithOperatorAndTokenIdToken &&
            tokenId == _revertBeforeAuthorizedTransferWithOperatorAndTokenIdTokenId
        ) {
            revert MockTransferValidatorRevert("beforeAuthorizedTransfer(address operator, address token, uint256 tokenId)");
        }
    }

    function afterAuthorizedTransfer(address token, uint256 tokenId) external view override {
        if (
            _shouldRevertAfterAuthorizedTransferWithTokenId &&
            token == _revertAfterAuthorizedTransferWithTokenIdToken &&
            tokenId == _revertAfterAuthorizedTransferWithTokenIdTokenId
        ) {
            revert MockTransferValidatorRevert("afterAuthorizedTransfer(address token, uint256 tokenId)");
        }
    }

    function beforeAuthorizedTransfer(address operator, address token) external view override {
        if (
            _shouldRevertBeforeAuthorizedTransferWithOperator &&
            operator == _revertBeforeAuthorizedTransferWithOperatorOperator &&
            token == _revertBeforeAuthorizedTransferWithOperatorToken
        ) {
            revert MockTransferValidatorRevert("beforeAuthorizedTransfer(address operator, address token)");
        }
    }

    function afterAuthorizedTransfer(address token) external view override {
        if (
            _shouldRevertAfterAuthorizedTransfer &&
            token == _revertAfterAuthorizedTransferToken
        ) {
            revert MockTransferValidatorRevert("afterAuthorizedTransfer(address token)");
        }
    }

    function beforeAuthorizedTransfer(address token, uint256 tokenId) external view override {
        if (
            _shouldRevertBeforeAuthorizedTransferWithTokenId &&
            token == _revertBeforeAuthorizedTransferWithTokenIdToken &&
            tokenId == _revertBeforeAuthorizedTransferWithTokenIdTokenId
        ) {
            revert MockTransferValidatorRevert("beforeAuthorizedTransfer(address token, uint256 tokenId)");
        }
    }

    function beforeAuthorizedTransferWithAmount(address token, uint256 tokenId, uint256 amount) external view override {
        if (
            _shouldRevertBeforeAuthorizedTransferWithAmount &&
            token == _revertBeforeAuthorizedTransferWithAmountToken &&
            tokenId == _revertBeforeAuthorizedTransferWithAmountTokenId &&
            amount == _revertBeforeAuthorizedTransferWithAmountAmount
        ) {
            revert MockTransferValidatorRevert("beforeAuthorizedTransferWithAmount(address token, uint256 tokenId, uint256 amount)");
        }
    }

    function afterAuthorizedTransferWithAmount(address token, uint256 tokenId) external view override {
        if (
            _shouldRevertAfterAuthorizedTransferWithAmount &&
            token == _revertAfterAuthorizedTransferWithAmountToken &&
            tokenId == _revertAfterAuthorizedTransferWithAmountTokenId
        ) {
            revert MockTransferValidatorRevert("afterAuthorizedTransferWithAmount(address token, uint256 tokenId)");
        }
    }
}

error MockTransferValidatorRevert(string functionDefinition);
