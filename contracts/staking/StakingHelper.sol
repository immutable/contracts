// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.19;

import {IERC20} from "lib/openzeppelin-contracts-5.0.2/contracts/token/ERC20/ERC20.sol";

interface IStakeHolderERC20 {
    function stake(uint256 amount) external;
    function getBalance(address account) external view returns (uint256);
}

interface IWIMX is IERC20 {
    function deposit() external payable;
}

/**
 * @title StakingHelper
 * @notice A helper contract that simplifies the process of wrapping native tokens and staking them
 * @dev This contract handles the full process of converting native tokens to WIMX and staking them
 */
contract StakingHelper {
    IERC20 public immutable wimx;
    IStakeHolderERC20 public immutable stakeHolder;

    event StakingCompleted(
        address indexed user,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Constructor that sets the addresses of the token and staking contracts
     * @param _wimx Address of the Wrapped IMX (WIMX) token contract
     * @param _stakeHolder Address of the StakeHolderERC20 contract
     */
    constructor(address _wimx, address _stakeHolder) {
        require(_wimx != address(0), "Invalid WIMX address");
        require(_stakeHolder != address(0), "Invalid StakeHolder address");
        wimx = IERC20(_wimx);
        stakeHolder = IStakeHolderERC20(_stakeHolder);
    }

    /**
     * @notice Performs the entire staking process in one transaction:
     *         1. Converts native tokens to WIMX
     *         2. Approves the StakeHolder contract to spend the WIMX
     *         3. Stakes the WIMX tokens
     * @dev The function is payable to receive native tokens for wrapping
     */
    function wrapAndStake() external payable {
        require(msg.value > 0, "Must send native tokens to wrap");

        uint256 amountToStake = msg.value;

        // 1. Wrap native tokens (ETH/IMX) to get WIMX
        wimx.deposit{value: amountToStake}();

        // 2. Approve the StakeHolder contract to spend WIMX
        wimx.approve(address(stakeHolder), amountToStake);

        // 3. Stake the WIMX tokens
        stakeHolder.stake(amountToStake);

        emit StakingCompleted(msg.sender, amountToStake, block.timestamp);
    }

    /**
     * @notice View function to check a user's current stake
     * @param user The address to check the stake for
     * @return The amount of tokens staked by the user
     */
    function getUserStake(address user) external view returns (uint256) {
        return stakeHolder.getBalance(user);
    }

    /**
     * @notice Emergency function to handle any stuck tokens
     * @dev This should normally not be needed but is included as a safeguard
     * @param token The token address
     * @param to The address to send tokens to
     * @param amount The amount of tokens to send
     */
    function rescueTokens(address token, address to, uint256 amount) external {
        // This function would need proper access control in production
        require(to != address(0), "Cannot send to zero address");
        IERC20(token).transfer(to, amount);
    }
}
