// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import '@openzeppelin/contracts/access/AccessControl.sol';
import "./ILatestWalletImplLocator.sol";

/**
 * @title LatestWalletImplLocator
 * @notice Contract to return the address of the latest wallet implementation contract.
 */
contract LatestWalletImplLocator is ILatestWalletImplLocator, AccessControl {
    // Role to change the implementation contract address.
    bytes32 public constant IMPLCHANGER_ROLE = keccak256('IMPLCHANGER_ROLE');

    address public latestWalletImplementation;

    event ImplChanged(address indexed _whoBy, address indexed _newImpl);

    /**
     * @param _admin Role that can grant / revoke roles: DEFAULT_ADMIN and IMPLCHANGER.
     * @param _implChanger Initial address that can change the latest wallet implementation address.
     */
    constructor(address _admin, address _implChanger) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(IMPLCHANGER_ROLE, _implChanger);
    }


    /**
     * Change the address of the latest wallet implementation contract.
     * @param _newImpl Address of the main module to be used by the wallet.
     */
    function changeWalletImplementation(address _newImpl) external onlyRole(IMPLCHANGER_ROLE) {
        latestWalletImplementation = _newImpl;
        emit ImplChanged(msg.sender, _newImpl);
    }
}