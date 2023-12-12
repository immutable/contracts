// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import "./ModuleAuthUpgradable.sol";
import "./ImageHashKey.sol";
import "../../Wallet.sol";


abstract contract ModuleAuthDynamic is ModuleAuthUpgradable {
  bytes32 public immutable INIT_CODE_HASH;
  address public immutable FACTORY;

  constructor(address _factory, address _startupWalletImpl) {
    // Build init code hash of the deployed wallets using that module
    bytes32 initCodeHash = keccak256(abi.encodePacked(Wallet.creationCode, uint256(uint160(_startupWalletImpl))));

    INIT_CODE_HASH = initCodeHash;
    FACTORY = _factory;
  }

  /**
   * @notice Validates the signature image with the salt used to deploy the contract
   *         if there is no stored image hash. This will happen prior to the first meta 
   *         transaction. Subsequently, validate the 
   *         signature image with a valid image hash defined in the contract storage
   * @param _imageHash Hash image of signature
   * @return true if the signature image is valid, and true if the image hash needs to be updated
   */
  function _isValidImage(bytes32 _imageHash) internal view override returns (bool, bool) {
    bytes32 storedImageHash = ModuleStorage.readBytes32(ImageHashKey.IMAGE_HASH_KEY);
    if (storedImageHash == 0) {
      // No image hash stored. Check that the image hash was used as the salt when 
      // deploying the wallet proxy contract.
      bool authenticated = address(
        uint160(uint256(
          keccak256(
            abi.encodePacked(
              bytes1(0xff),
              FACTORY,
              _imageHash,
              INIT_CODE_HASH
            )
          )
        ))
      ) == address(this);
      // Indicate need to update = true. This will trigger a call to store the image hash
      return (authenticated, true);
    }

    // Image hash has been stored. 
    return ((_imageHash != bytes32(0) && _imageHash == storedImageHash), false);
  }
}



