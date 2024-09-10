// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.24;

import {SafeERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IPaymentSplitterErrors} from "../errors/PaymentSplitterErrors.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * Implementation is based on openzeppelin/PaymentSplitter smart contract
 */
contract PaymentSplitter is AccessControlEnumerable, IPaymentSplitterErrors, ReentrancyGuard {
    /// @notice Emitted when the payees list is updated
    event PayeeAdded(address account, uint256 shares);

    /// @notice Emitted when IMX is paid to the contract
    event PaymentReleased(address to, uint256 amount);

    /// @notice Emitted when ERC20 is paid to the contract
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);

    /// @notice Emitted when the contract receives IMX
    event PaymentReceived(address from, uint256 amount);

    /// @notice Role responsible for releasing funds
    bytes32 public constant RELEASE_FUNDS_ROLE = bytes32("RELEASE_FUNDS_ROLE");

    /// @notice Role responsible for registering tokens
    bytes32 public constant TOKEN_REGISTRAR_ROLE = bytes32("TOKEN_REGISTRAR_ROLE");

    /// @notice the totalshares held by payees
    uint256 private _totalShares;

    /// @notice the number of shares held by each payee
    mapping(address payee => uint256 numberOfShares) private _shares;

    /// @notice the address of the payees
    address payable[] private _payees;

    /// @notice the list of erc20s that are allowed to be released and interacted with
    IERC20[] private allowedERC20List;

    /**
     * @notice Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
     * the matching position in the `shares` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     * @param admin default admin responsible for adding/removing payees and managing roles
     * @param registrar default registrar responsible for registering tokens
     * @param fundsAdmin default admin responsible for releasing funds
     */
    constructor(address admin, address registrar, address fundsAdmin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(RELEASE_FUNDS_ROLE, fundsAdmin);
        _grantRole(TOKEN_REGISTRAR_ROLE, registrar);
    }

    /**
     * @notice Payable fallback method to receive IMX. The IMX received will be logged with {PaymentReceived} events.
     * this contract has no other payable method, all IMX receives will be tracked by the events emitted by this event
     * ERC20 receives will not be tracked by this contract but tranfers events will be emitted by the erc20 contracts themselves.
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @notice Grants the release funds role to an address. See {AccessControlEnumerable-grantRole}.
     * @param user The address of the funds role admin
     */
    function grantReleaseFundsRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(RELEASE_FUNDS_ROLE, user);
    }

    /**
     * @notice revokes the release funds role to an address. See {AccessControlEnumerable-revokeRole}.
     * @param user The address of the funds role admin
     */
    function revokeReleaseFundsRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(RELEASE_FUNDS_ROLE, user);
    }

    /**
     * @notice removes a token from the allowlist, does nothing is token is not in the list
     * only executable by the token registrar
     * @param token The address of the ERC20 token to be removed
     */
    function removeFromAllowlist(IERC20 token) external onlyRole(TOKEN_REGISTRAR_ROLE) {
        uint256 allowlistLength = allowedERC20List.length;
        // slither-disable-start costly-loop
        for (uint256 index; index < allowlistLength; index++) {
            if (allowedERC20List[index] == token) {
                allowedERC20List[index] = allowedERC20List[allowedERC20List.length - 1];
                allowedERC20List.pop();
                break;
            }
        }
        // slither-disable-end costly-loop
    }

    /**
     * @notice returns the list of allowed ERC20 tokens
     */
    function erc20Allowlist() external view returns (IERC20[] memory) {
        return allowedERC20List;
    }

    /**
     * @notice Getter for the total shares held by payees.
     */
    function totalShares() external view returns (uint256) {
        return _totalShares;
    }

    /**
     * @notice Getter for the amount of shares held by an account.
     * @param account The address of the payee.
     */
    function shares(address account) external view returns (uint256) {
        return _shares[account];
    }

    /**
     * @notice Getter for the address of the payee number `index`.
     * @param index The index of the payee.
     */
    function payee(uint256 index) external view returns (address) {
        return _payees[index];
    }

    /**
     * @notice Getter for the amount of payee's releasable IMX.
     * @param account The address of the payee.
     */
    function releasable(address account) external view returns (uint256) {
        return _pendingPayment(account, address(this).balance);
    }

    /**
     * @notice Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     * @param token The contract address of the ERC20 token.
     * @param account The address of the payee.
     */
    function releasable(IERC20 token, address account) external view returns (uint256) {
        return _pendingPayment(account, token.balanceOf(address(this)));
    }

    /**
     * @notice Triggers a transfer to all payees of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * Triggers a transfer to all payees of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function releaseAll() public virtual nonReentrant onlyRole(RELEASE_FUNDS_ROLE) {
        uint256 numPayees = _payees.length;
        uint256 startBalance = address(this).balance;
        // slither-disable-start calls-loop
        if (startBalance > 0) {
            for (uint256 payeeIndex = 0; payeeIndex < numPayees; payeeIndex++) {
                address payable account = _payees[payeeIndex];
                uint256 nativePaymentAmount = _pendingPayment(account, startBalance);
                Address.sendValue(account, nativePaymentAmount);
                emit PaymentReleased(account, nativePaymentAmount);
            }
        }

        for (uint256 tokenIndex = 0; tokenIndex < allowedERC20List.length; tokenIndex++) {
            IERC20 erc20 = allowedERC20List[tokenIndex];
            uint256 startBalanceERC20 = erc20.balanceOf(address(this));
            if (startBalanceERC20 > 0) {
                for (uint256 payeeIndex = 0; payeeIndex < numPayees; payeeIndex++) {
                    address account = _payees[payeeIndex];
                    uint256 erc20PaymentAmount = _pendingPayment(account, startBalanceERC20);
                    SafeERC20.safeTransfer(erc20, account, erc20PaymentAmount);
                    emit ERC20PaymentReleased(erc20, account, erc20PaymentAmount);
                }
            }
        }
        // slither-disable-end calls-loop
    }

    /**
     * @notice replaces the existing entry of payees and shares with the new payees and shares.
     * @param payees the address of new payees
     * @param shares_ the shares of new payees
     */
    function overridePayees(
        address payable[] memory payees,
        uint256[] memory shares_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (payees.length != shares_.length) {
            revert PaymentSplitterLengthMismatchSharesPayees();
        }

        if (payees.length == 0) {
            revert PaymentSplitterNoPayeesAdded();
        }

        uint256 numPayees = _payees.length;
        // slither-disable-start costly-loop
        for (uint256 i = 0; i < numPayees; i++) {
            delete _shares[_payees[i]];
        }
        // slither-disable-end costly-loop

        delete _payees;

        uint256 localTotalShares = 0;
        for (uint256 i = 0; i < payees.length; i++) {
            localTotalShares += shares_[i];
            _addPayee(payees[i], shares_[i]);
        }
        _totalShares = localTotalShares;
    }

    /**
     * @notice adds new tokens to the allowlist, does nothing is token is already in the list
     * only executable by the token registrar
     * @param tokens The addresses of the ERC20 token to be added
     */
    function addToAllowlist(IERC20[] memory tokens) public onlyRole(TOKEN_REGISTRAR_ROLE) {
        for (uint256 index; index < tokens.length; index++) {
            addToAllowlist(tokens[index]);
        }
    }

    /**
     * @notice adds a new token to the allowlist, does nothing is token is already in the list
     * @param token The address of the ERC20 token to be added
     */
    function addToAllowlist(IERC20 token) internal onlyRole(TOKEN_REGISTRAR_ROLE) {
        uint256 allowListLength = allowedERC20List.length;
        for (uint256 index; index < allowListLength; index++) {
            if (allowedERC20List[index] == token) {
                return;
            }
        }
        allowedERC20List.push(token);
    }

    /**
     * @notice internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(address account, uint256 currentBalance) private view returns (uint256) {
        return (currentBalance * _shares[account]) / _totalShares;
    }

    /**
     * @dev Add a new payee to the contract.
     * @param account The address of the payee to add.
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(address payable account, uint256 shares_) private {
        if (account == address(0)) {
            revert PaymentSplitterPayeeZerothAddress();
        }

        if (shares_ == 0) {
            revert PaymentSplitterPayeeZeroShares();
        }

        if (_shares[account] > 0) {
            revert PaymentSplitterSharesAlreadyExistForPayee();
        }

        _payees.push(account);
        _shares[account] = shares_;
        emit PayeeAdded(account, shares_);
    }
}
