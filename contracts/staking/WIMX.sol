// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.19 <0.8.29;

import {IWIMX} from "./IWIMX.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @notice WIMX is a wrapped IMX contract that allows users to wrap their native IMX.
 * @dev This contract is adapted from the official Wrapped ETH contract.
 */
contract WIMX is IWIMX {
    string public name = "Wrapped IMX";
    string public symbol = "WIMX";
    uint8 public decimals = 18;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /**
     * @notice Fallback function on receiving native IMX.
     */
    receive() external payable {
        deposit();
    }

    /**
     * @notice Deposit native IMX in the function call and mint the equal amount of wrapped IMX to msg.sender.
     */
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Withdraw given amount of native IMX to msg.sender and burn the equal amount of wrapped IMX.
     * @param wad The amount to withdraw.
     */
    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad, "Wrapped IMX: Insufficient balance");
        balanceOf[msg.sender] -= wad;

        Address.sendValue(payable(msg.sender), wad);
        emit Withdrawal(msg.sender, wad);
    }

    /**
     * @notice Obtain the current total supply of wrapped IMX.
     * @return uint The amount of supplied wrapped IMX.
     */
    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Approve given spender the ability to spend a given amount of msg.sender's tokens.
     * @param guy Approved spender.
     * @param wad Amount of allowance.
     * @return bool Returns true if function call is successful.
     */
    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    /**
     * @notice Transfer given amount of tokens from msg.sender to given destination.
     * @param dst Destination of this transfer.
     * @param wad Amount of this transfer.
     * @return bool Returns true if function call is successful.
     */
    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    /**
     * @notice Transfer given amount of tokens from given source to given destination.
     * @param src Source of this transfer.
     * @param dst Destination of this transfer.
     * @param wad Amount of this transfer.
     * @return bool Returns true if function call is successful.
     */
    function transferFrom(address src, address dst, uint256 wad) public returns (bool) {
        require(balanceOf[src] >= wad, "Wrapped IMX: Insufficient balance");

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "Wrapped IMX: Insufficient allowance");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}
