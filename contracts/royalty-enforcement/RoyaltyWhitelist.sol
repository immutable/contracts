//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

// Access Control
import "@openzeppelin/contracts/access/AccessControl.sol";

// Introspection
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// Interfaces
import "./IRoyaltyWhitelist.sol";

/*
    RoyaltyWhitelist is an implementation of a whitelist registry, storing addresses and bytecode
    which are allowed to be approved operators and execute transfers of ERC721 tokens. The registry
    will be a deployed contract that ERC721 tokens may interface with and point to.
*/
contract RoyaltyWhitelist is ERC165, AccessControl, IRoyaltyWhitelist {
    ///     =====       Events       =====

    /// @dev Emitted when a target address is added or removed from the whitelist
    event AddressWhitelistChanged(address indexed target, bool status);

    /// @dev Emitted when a target bytecode is added or removed from the whitelist
    event BytecodeWhitelistChanged(bytes32 indexed target, bool status);

    ///     =====   State Variables  =====

    /// @dev Only REGISTRAR_ROLE can invoke white listing functionality.
    bytes32 public constant REGISTRAR_ROLE = bytes32("REGISTRAR_ROLE");

    /// @dev EOA codehash (see https://eips.ethereum.org/EIPS/eip-1052)
    bytes32 constant EOA_CODEHASH = keccak256("");

    /// @dev Mapping of whitelisted addresses
    mapping(address => bool) private addressWhitelist;

    /// @dev Mapping of whitelisted bytecodes
    mapping(bytes32 => bool) private bytecodeWhitelist;

    ///     =====   Constructor  =====

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` to the supplied `admin` address
     */
    constructor(address admin) {
        // Initialize state variables
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
    }

    ///     =====   View functions  =====

    /// @dev ERC-165 interface support
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IRoyaltyWhitelist).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @dev Returns whether true if an address is whitelisted, false otherwise
    function isAddressWhitelisted(
        address target
    ) external view override returns (bool) {
        if (addressWhitelist[target]) {
            return true;
        }

        // Retrieve bytecode at target address
        bytes32 codeHash;
        assembly {
            codeHash := extcodehash(target)
        }

        return bytecodeWhitelist[codeHash];
    }

    ///     =====  External functions  =====

    /// @dev Add a target address to whitelist
    function whitelistAddress(
        address target
    ) external onlyRole(REGISTRAR_ROLE) {
        require(target != address(0), "can't whitelist zero address");
        require(!addressWhitelist[target], "address already whitelisted");
        addressWhitelist[target] = true;
        emit AddressWhitelistChanged(target, true);
    }

    /// @dev Remove a target address from whitelist
    function unWhitelistAddress(
        address target
    ) external onlyRole(REGISTRAR_ROLE) {
        require(addressWhitelist[target], "address not whitelisted");
        delete addressWhitelist[target];
        emit AddressWhitelistChanged(target, false);
    }

    /// @dev Add a target bytecode to whitelist
    function whitelistBytecode(
        bytes32 target
    ) external onlyRole(REGISTRAR_ROLE) {
        require(target != EOA_CODEHASH, "can't whitelist EOA code hash");
        require(!bytecodeWhitelist[target], "bytecode already whitelisted");
        bytecodeWhitelist[target] = true;
        emit BytecodeWhitelistChanged(target, true);
    }

    /// @dev Remove a target bytecode from whitelist
    function unWhitelistBytecode(
        bytes32 target
    ) external onlyRole(REGISTRAR_ROLE) {
        require(bytecodeWhitelist[target], "target not whitelisted");
        delete bytecodeWhitelist[target];
        emit BytecodeWhitelistChanged(target, false);
    }

    /// @dev Allows admin grant `user` `REGISTRAR_ROLE` role
    function grantRegistrarRole(
        address user
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(REGISTRAR_ROLE, user);
    }
}
