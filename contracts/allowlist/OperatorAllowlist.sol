// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

// Access Control
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// Introspection
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Interfaces
import {IOperatorAllowlist} from "./IOperatorAllowlist.sol";

// Interface to retrieve the implemention stored inside the Proxy contract
interface IProxy {
    // Returns the current implementation address used by the proxy contract
    function PROXY_getImplementation() external view returns (address);
}

/*
    OperatorAllowlist is an implementation of a Allowlist registry, storing addresses and bytecode
    which are allowed to be approved operators and execute transfers of interfacing token contracts (e.g. ERC721/ERC1155).
    The registry will be a deployed contract that tokens may interface with and point to.
    OperatorAllowlist is not designed to be upgradeable or extended.
*/

contract OperatorAllowlist is ERC165, AccessControl, IOperatorAllowlist {
    ///     =====   State Variables  =====

    /// @notice Only REGISTRAR_ROLE can invoke white listing registration and removal
    bytes32 public constant REGISTRAR_ROLE = bytes32("REGISTRAR_ROLE");

    /// @notice Mapping of Allowlisted addresses
    mapping(address => bool) private addressAllowlist;

    /// @notice Mapping of Allowlisted implementation addresses
    mapping(address => bool) private addressImplementationAllowlist;

    /// @notice Mapping of Allowlisted bytecodes
    mapping(bytes32 => bool) private bytecodeAllowlist;

    ///     =====       Events       =====

    /// @notice Emitted when a target address is added or removed from the Allowlist
    event AddressAllowlistChanged(address indexed target, bool added);

    /// @notice Emitted when a target smart contract wallet is added or removed from the Allowlist
    event WalletAllowlistChanged(bytes32 indexed targetBytes, address indexed targetAddress, bool added);

    ///     =====   Constructor  =====

    /**
     * @notice Grants `DEFAULT_ADMIN_ROLE` to the supplied `admin` address
     * @param admin the address to grant `DEFAULT_ADMIN_ROLE` to
     */
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    ///     =====  External functions  =====

    /**
     * @notice Add a target address to Allowlist
     * @param addressTargets the addresses to be added to the allowlist
     */
    function addAddressToAllowlist(address[] calldata addressTargets) external onlyRole(REGISTRAR_ROLE) {
        for (uint256 i; i < addressTargets.length; i++) {
            addressAllowlist[addressTargets[i]] = true;
            emit AddressAllowlistChanged(addressTargets[i], true);
        }
    }

    /**
     * @notice Remove a target address from Allowlist
     * @param addressTargets the addresses to be removed from the allowlist
     */
    function removeAddressFromAllowlist(address[] calldata addressTargets) external onlyRole(REGISTRAR_ROLE) {
        for (uint256 i; i < addressTargets.length; i++) {
            delete addressAllowlist[addressTargets[i]];
            emit AddressAllowlistChanged(addressTargets[i], false);
        }
    }

    /**
     * @notice Add a smart contract wallet to the Allowlist.
     * This will allowlist the proxy and implementation contract pair.
     * First, the bytecode of the proxy is added to the bytecode allowlist.
     * Second, the implementation address stored in the proxy is stored in the
     * implementation address allowlist.
     * @param walletAddr the wallet address to be added to the allowlist
     */
    function addWalletToAllowlist(address walletAddr) external onlyRole(REGISTRAR_ROLE) {
        // get bytecode of wallet
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(walletAddr)
        }
        bytecodeAllowlist[codeHash] = true;
        // get address of wallet module
        address impl = IProxy(walletAddr).PROXY_getImplementation();
        addressImplementationAllowlist[impl] = true;

        emit WalletAllowlistChanged(codeHash, walletAddr, true);
    }

    /**
     * @notice Remove  a smart contract wallet from the Allowlist
     * This will remove the proxy bytecode hash and implementation contract address pair from the allowlist
     * @param walletAddr the wallet address to be removed from the allowlist
     */
    function removeWalletFromAllowlist(address walletAddr) external onlyRole(REGISTRAR_ROLE) {
        // get bytecode of wallet
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(walletAddr)
        }
        delete bytecodeAllowlist[codeHash];
        // get address of wallet module
        address impl = IProxy(walletAddr).PROXY_getImplementation();
        delete addressImplementationAllowlist[impl];

        emit WalletAllowlistChanged(codeHash, walletAddr, false);
    }

    /**
     * @notice Allows admin to grant `user` `REGISTRAR_ROLE` role
     * @param user the address that `REGISTRAR_ROLE` will be granted to
     */
    function grantRegistrarRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(REGISTRAR_ROLE, user);
    }

    /**
     * @notice Allows admin to revoke `REGISTRAR_ROLE` role from `user`
     * @param user the address that `REGISTRAR_ROLE` will be revoked from
     */
    function revokeRegistrarRole(address user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(REGISTRAR_ROLE, user);
    }

    ///     =====   View functions  =====

    /**
     * @notice Returns true if an address is Allowlisted, false otherwise
     * @param target the address that will be checked for presence in the allowlist
     */
    function isAllowlisted(address target) external view override returns (bool) {
        if (addressAllowlist[target]) {
            return true;
        }

        // Check if caller is a Allowlisted smart contract wallet
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(target)
        }
        if (bytecodeAllowlist[codeHash]) {
            // If wallet proxy bytecode is approved, check addr of implementation contract
            address impl = IProxy(target).PROXY_getImplementation();

            return addressImplementationAllowlist[impl];
        }

        return false;
    }

    /**
     * @notice ERC-165 interface support
     * @param interfaceId The interface identifier, which is a 4-byte selector.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, AccessControl) returns (bool) {
        return interfaceId == type(IOperatorAllowlist).interfaceId || super.supportsInterface(interfaceId);
    }
}
