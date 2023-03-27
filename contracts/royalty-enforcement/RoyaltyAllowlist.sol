//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Access Control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Introspection
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Interfaces
import "./IRoyaltyAllowlist.sol";

// Interface to retrieve the implemention stored inside the Proxy contract
interface IProxy {
    // Returns the current implementation address used by the proxy contract
    function PROXY_getImplementation() external view returns (address);
}


/*
    RoyaltyAllowlist is an implementation of a Allowlist registry, storing addresses and bytecode
    which are allowed to be approved operators and execute transfers of interfacing token contracts (e.g. ERC721/ERC1155). The registry
    will be a deployed contract that tokens may interface with and point to.
*/
contract RoyaltyAllowlist is ERC165, AccessControl, IRoyaltyAllowlist {
    ///     =====       Events       =====

    /// @dev Emitted when a target address is added or removed from the Allowlist
    event AddressAllowlistChanged(address indexed target, bool added);

    /// @dev Emitted when a target smart contract wallet is added or removed from the Allowlist
    event WalletAllowlistChanged(bytes32 indexed targetBytes, address indexed targetAddress, bool added);

    ///     =====   State Variables  =====

    // /// @dev Bytecode hash of Minimal Proxy Contract (https://eips.ethereum.org/EIPS/eip-1167) 
    // bytes32 private constant minimalProxyCodeHash = hex"363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3";

    /// @dev Only REGISTRAR_ROLE can invoke white listing registration and removal
    bytes32 public constant REGISTRAR_ROLE = bytes32("REGISTRAR_ROLE");


    /// @dev Mapping of Allowlisted addresses
    mapping(address => bool) private addressAllowlist;

    /// @dev Mapping of Allowlisted bytecodes
    mapping(bytes32 => bool) private bytecodeAllowlist;
    

    ///     =====   Constructor  =====

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the supplied `admin` address
     */
    constructor(address admin) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    ///     =====   View functions  =====

    /// @dev ERC-165 interface support
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IRoyaltyAllowlist).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Returns true if an address is Allowlisted, false otherwise
    function isAllowlisted(
        address target
    ) external view override returns (bool) {
        if (addressAllowlist[target]) {
            return true;
        }

        // Check if caller is a Allowlisted smart contract wallet
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(target)
        }
        if (bytecodeAllowlist[codeHash]) {
            // If wallet proxy bytecode is approved, check addr of module
            address impl = IProxy(target).PROXY_getImplementation();

            return addressAllowlist[impl];
        } 

        return false;
    }

    ///     =====  External functions  =====

    /// @dev Add a target address to Allowlist
    function addAddressToAllowlist(
        address[] calldata addressTargets
    ) external onlyRole(REGISTRAR_ROLE) {
        for (uint256 i; i < addressTargets.length; i++) {
            addressAllowlist[addressTargets[i]] = true;
            emit AddressAllowlistChanged(addressTargets[i], true);
        }
    }

    /// @dev Remove a target address from Allowlist
    function removeAddressFromAllowlist(
        address[] calldata addressTargets
    ) external onlyRole(REGISTRAR_ROLE) {
        for (uint256 i; i < addressTargets.length; i++) {
            delete addressAllowlist[addressTargets[i]];
            emit AddressAllowlistChanged(addressTargets[i], false);
        }
    }

    /// @dev Add a smart contract wallet to the Allowlist
    function addWalletToAllowlist(
        address walletAddr
    ) external onlyRole(REGISTRAR_ROLE) {
        // get bytecode of minimal proxy
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(walletAddr)
        }
        bytecodeAllowlist[codeHash] = true;
        // get address of wallet module
        address impl = IProxy(walletAddr).PROXY_getImplementation();
        addressAllowlist[impl] = true;

        emit WalletAllowlistChanged(codeHash, walletAddr, true);
    }

    /// @dev Remove  a smart contract wallet from the Allowlist
    function removeWalletFromAllowlist(
        address walletAddr
    ) external onlyRole(REGISTRAR_ROLE) {
        // get bytecode of minimal proxy
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(walletAddr)
        }
        delete bytecodeAllowlist[codeHash];
        // get address of wallet module
        address impl = IProxy(walletAddr).PROXY_getImplementation();
        delete addressAllowlist[impl];

        emit WalletAllowlistChanged(codeHash, walletAddr, false);
    }

    /// @dev Allows admin to grant `user` `REGISTRAR_ROLE` role
    function grantRegistrarRole(
        address user
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(REGISTRAR_ROLE, user);
    }

    /// @dev Allows admin to revoke `REGISTRAR_ROLE` role from `user`
    function revokeRegistrarRole(
        address user
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(REGISTRAR_ROLE, user);
    }
}
