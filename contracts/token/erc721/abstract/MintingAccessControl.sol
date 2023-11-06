//SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

abstract contract MintingAccessControl is AccessControlEnumerable {

    /// @dev Role to mint tokens
    bytes32 public constant MINTER_ROLE = bytes32("MINTER_ROLE");

    /// @dev Returns the addresses which have DEFAULT_ADMIN_ROLE
    function getAdmins() public view returns (address[] memory) {
        uint256 adminCount = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
        address[] memory admins = new address[](adminCount);
        for (uint256 i; i < adminCount; i++) {
            admins[i] = getRoleMember(DEFAULT_ADMIN_ROLE, i);
        }
        return admins;
    }

    /// @dev Allows admin grant `user` `MINTER` role
    function grantMinterRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, user);
    }

    /// @dev Allows admin to revoke `MINTER_ROLE` role from `user`
    function revokeMinterRole(address user) public onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MINTER_ROLE, user);
    }
}
