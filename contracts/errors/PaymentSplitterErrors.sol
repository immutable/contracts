// Copyright Immutable Pty Ltd 2018 - 2024
//SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.20;

interface IPaymentSplitterErrors {
    /// @dev caller tried to add payees with shares of unequal length
    error PaymentSplitterLengthMismatchSharesPayees();

    /// @dev caller tried to add payees with length of 0
    error PaymentSplitterNoPayeesAdded();

    /// @dev caller tried to add payee with zeroth address
    error PaymentSplitterPayeeZerothAddress();

    /// @dev caller tried to add payee with 0 shares
    error PaymentSplitterPayeeZeroShares();

    /// @dev caller tried to add shares to account with existing shares
    error PaymentSplitterSharesAlreadyExistForPayee();
}
