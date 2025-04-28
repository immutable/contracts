// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
* @notice Interface for the Wrapped IMX (wIMX) contract.
* @dev Based on the interface for the standard [Wrapped ETH contract](../root/IWETH.sol)
*/
interface IWIMX is IERC20 {
    /**
     * @notice Emitted when native ETH is deposited to the contract, and a corresponding amount of wETH are minted
     * @param account The address of the account that deposited the tokens.
     * @param value The amount of tokens that were deposited.
     */
    event Deposit(address indexed account, uint256 value);

    /**
     * @notice Emitted when wETH is withdrawn from the contract, and a corresponding amount of wETH are burnt.
     * @param account The address of the account that withdrew the tokens.
     * @param value The amount of tokens that were withdrawn.
     */
    event Withdrawal(address indexed account, uint256 value);

    /**
     * @notice Deposit native ETH to the contract and mint an equal amount of wrapped ETH to msg.sender.
     */
    function deposit() external payable;

    /**
     * @notice Withdraw given amount of native ETH to msg.sender after burning an equal amount of wrapped ETH.
     * @param value The amount to withdraw.
     */
    function withdraw(uint256 value) external;
}
