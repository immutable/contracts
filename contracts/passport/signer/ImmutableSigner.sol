// Copyright Immutable Pty Ltd 2023
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {SignatureValidator} from '../utils/SignatureValidator.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';

/**
 * @title ImmutableSigner
 *
 * @notice ERC-1271 Wallet implementation. Verifies signatures using a public
 * key in storage matching an offchain private key. The key can be upgraded by
 * the role SIGNER_ADMIN_ROLE, set during initialization.
 */
contract ImmutableSigner is SignatureValidator, AccessControl {
  // @dev A signer only valid until the validUntil unix timestmap
  struct ExpirableSigner {
    address signer;
    uint256 validUntil;
  }

  address public primarySigner;
  ExpirableSigner public rolloverSigner;

  bytes32 public constant SIGNER_ADMIN_ROLE = keccak256('SIGNER_ADMIN_ROLE');

  /*
   * @notice Emitted whenever the main authorized signer is updated.
   */
  event PrimarySignerUpdated(address indexed _previousSigner, address indexed _newSigner);
  /*
   * @notice Emitted whenever a temporary signer is enabled.
   */
  event RolloverSignerEnabled(address indexed _signer, uint256 _validUntil);


  constructor(address _rootAdmin, address _signerAdmin, address _signer) {
    _grantRole(DEFAULT_ADMIN_ROLE, _rootAdmin);
    _grantRole(SIGNER_ADMIN_ROLE, _signerAdmin);

    primarySigner = _signer;

    // We do not need a rollover signer initially as there's no rollover
    // happening, so validUntil must be in the past. Luckily that aligns with
    // its default initial value.
    //
    // rolloverSigner.validUntil = 0;
  }

  /*
   * @dev Grants SIGNER_ADMIN_ROLE to an user.
   * @param _signerAdmin Address that will be allowed to update the wallet signer.
   */
  function grantSignerRole(address _signerAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
    _grantRole(SIGNER_ADMIN_ROLE, _signerAdmin);
  }

  /*
   * @dev Updates the authorized public key address. Any old keys are expired effective immediately.
   * @param _newSigner The address of the new authorized signer.
   */
  function updateSigner(address _newSigner) public onlyRole(SIGNER_ADMIN_ROLE) {
    address previousSigner = primarySigner;
    primarySigner = _newSigner;

    // Make sure any rollover is immediately finished.
    rolloverSigner.validUntil = 0;

    emit PrimarySignerUpdated(previousSigner, _newSigner);
  }

  /*
   * @dev Updates the authorized public key address. Allows the previous public
   * key to remain valid for a specified rollover period.
   *
   * @param _newSigner The address of the new authorized signer.
   * @param _rolloverPeriod Period for which the previous key will still be valid.
   */
  function updateSignerWithRolloverPeriod(
    address _newSigner,
    uint256 _rolloverPeriod
  ) public onlyRole(SIGNER_ADMIN_ROLE) {
    address previousSigner = primarySigner;
    primarySigner = _newSigner;

    rolloverSigner.signer = previousSigner;
    rolloverSigner.validUntil = block.timestamp + _rolloverPeriod;

    emit PrimarySignerUpdated(previousSigner, _newSigner);
    emit RolloverSignerEnabled(rolloverSigner.signer, rolloverSigner.validUntil);
  }

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x1626ba7e
   * @param _hash       keccak256 hash that was signed
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x1626ba7e if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4) {
    if (recoverSigner(_hash, _signature) == primarySigner) {
      return ERC1271_MAGICVALUE_BYTES32;
    }

    if (block.timestamp <= rolloverSigner.validUntil) {
      if (recoverSigner(_hash, _signature) == rolloverSigner.signer) {
        return ERC1271_MAGICVALUE_BYTES32;
      }
    }

    return 0;
  }
}
