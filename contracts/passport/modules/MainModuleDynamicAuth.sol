// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "./commons/ModuleAuthDynamic.sol";
import "./commons/ModuleReceivers.sol";
import "./commons/ModuleCalls.sol";
import "./commons/ModuleUpdate.sol";


/**
 * TODO Peter update docs
 * @notice Contains the core functionality arcadeum wallets will inherit with
 *         the added functionality that the main-module can be changed.
 * @dev If using a new main module, developpers must ensure that all inherited
 *      contracts by the mainmodule don't conflict and are accounted for to be
 *      supported by the supportsInterface method.
 */
contract MainModuleDynamicAuth is
  ModuleAuthDynamic,
  ModuleCalls,
  ModuleReceivers,
  ModuleUpdate
{

  // solhint-disable-next-line no-empty-blocks
  constructor(address _factory, address _startup) ModuleAuthDynamic (_factory, _startup) { }


  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @dev If using a new main module, developpers must ensure that all inherited
   *      contracts by the mainmodule don't conflict and are accounted for to be
   *      supported by the supportsInterface method.
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(
    bytes4 _interfaceID
  ) public override(
    ModuleAuthUpgradable,
    ModuleCalls,
    ModuleReceivers,
    ModuleUpdate
  ) pure returns (bool) {
    return super.supportsInterface(_interfaceID);
  }

  function version() external pure virtual returns (uint256) {
    return 1;
  }
}
