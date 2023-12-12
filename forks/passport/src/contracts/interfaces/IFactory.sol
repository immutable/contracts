// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

/**
 * @title IFactory
 * @notice Factory interface to interact with wallet factory
 */
interface IFactory {
  event WalletDeployed(address indexed wallet, address indexed mainModule, bytes32 salt);

  /**
   * @notice Returns a deterministic contract address given a salt
   * @param _mainModule Address of the main module to be used by the wallet
   * @param _salt Salt used to generate the address
   * @return _address The deterministic address
   */
  function getAddress(address _mainModule, bytes32 _salt) external view returns (address);

  /**
   * @notice Will deploy a new wallet instance using create2
   * @param _mainModule Address of the main module to be used by the wallet
   * @param _salt Salt used to generate the wallet, which is the imageHash
   *       of the wallet's configuration.
   * @dev It is recommended to not have more than 200 signers as opcode repricing
   *      could make transactions impossible to execute as all the signers must be
   *      passed for each transaction.
   */
  function deploy(address _mainModule, bytes32 _salt) external payable returns (address);
}
