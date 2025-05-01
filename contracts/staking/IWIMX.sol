// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @notice Interface for the Wrapped IMX (wIMX) contract.
 * @dev Based on the interface for the [Wrapped IMX contract](https://etherscan.io/token/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code)
 */
interface IWIMX is IERC20 {
    /**
     * @notice Emitted when native IMX is deposited to the contract, and a corresponding amount of wIMX are minted
     * @param account The address of the account that deposited the tokens.
     * @param value The amount of tokens that were deposited.
     */
    event Deposit(address indexed account, uint256 value);

    /**
     * @notice Emitted when wIMX is withdrawn from the contract, and a corresponding amount of wIMX are burnt.
     * @param account The address of the account that withdrew the tokens.
     * @param value The amount of tokens that were withdrawn.
     */
    event Withdrawal(address indexed account, uint256 value);

    /**
     * @notice Deposit native IMX to the contract and mint an equal amount of wrapped IMX to msg.sender.
     */
    function deposit() external payable;

    /**
     * @notice Withdraw given amount of native IMX to msg.sender after burning an equal amount of wrapped IMX.
     * @param value The amount to withdraw.
     */
    function withdraw(uint256 value) external;
}
