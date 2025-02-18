// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

import {ImmutableERC721MintByIDV3} from "./ImmutableERC721MintByIDV3.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/proxy/utils/UUPSUpgradeable.sol";

contract ImmutableERC721MintByIDUpgradeableV3 is ImmutableERC721MintByIDV3, UUPSUpgradeable {
    // TODO put this into error interface
    /// @notice Error: Attempting to upgrade contract storage to version 0.
    error CanNotUpgradeToLowerOrSameVersion(uint256 _storageVersion);


    /// @notice Only UPGRADE_ROLE can upgrade the contract
    bytes32 public constant UPGRADE_ROLE = bytes32("UPGRADE_ROLE");

    /// @notice Version 1 version number
    uint256 private constant _VERSION1 = 1;

    /// @notice version number of the storage variable layout.
    uint256 public version;

    // Dummy constructor overrides constructor of base.
    constructor() ImmutableERC721MintByIDV3(
        address(1), // owner_
        "", // name_,
        "", // symbol_,
        "", // baseURI_,
        "", // contractURI_,
        address(1), // operatorAllowlist_,
        address(1), // royaltyReceiver_,
        uint96(0) // feeNumerator_
    )
    {}


    /**
     * @notice Initialises the upgradeable contract. Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     * @param owner_ The address to grant the `DEFAULT_ADMIN_ROLE` to
     * @param name_ The name of the collection
     * @param symbol_ The symbol of the collection
     * @param baseURI_ The base URI for the collection
     * @param contractURI_ The contract URI for the collection
     * @param operatorAllowlist_ The address of the operator allowlist
     * @param royaltyReceiver_ The address of the royalty receiver
     * @param feeNumerator_ The royalty fee numerator
     * @dev the royalty receiver and amount (this can not be changed once set)
     */
    function initialize(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address operatorAllowlist_,
        address royaltyReceiver_,
        uint96 feeNumerator_
    ) public virtual initializer {
        __ImmutableERC721Base_init(
            owner_,
            name_,
            symbol_,
            baseURI_,
            contractURI_,
            operatorAllowlist_,
            royaltyReceiver_,
            feeNumerator_
        );
        __UUPSUpgradeable_init();
        version = _VERSION1;

        _grantRole(UPGRADE_ROLE, owner_);
    }

    /**
     * @notice Function to be called when upgrading this contract.
     * @dev Call this function as part of upgradeToAndCall().
     *      This initial version of this function reverts. There is no situation
     *      in which it makes sense to upgrade to the V0 storage layout.
     *      Note that this function is permissionless. Future versions must
     *      compare the code version and the storage version and upgrade
     *      appropriately. As such, the code will revert if an attacker calls
     *      this function attempting a malicious upgrade.
     * @ param _data ABI encoded data to be used as part of the contract storage upgrade.
     */
    function upgradeStorage(bytes memory /* _data */) external virtual {
        revert CanNotUpgradeToLowerOrSameVersion(version);
    }

    // Override the _authorizeUpgrade function
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADE_ROLE) {}

    /// @notice storage gap for additional variables for upgrades
    // slither-disable-start unused-state
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __ImmutableERC721MintByID2Gap;
    // slither-disable-end unused-state
}
