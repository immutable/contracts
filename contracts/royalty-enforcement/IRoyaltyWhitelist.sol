//SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;


/**
 * @dev Required interface of an RoyaltyWhitelist compliant contract
 */
interface IRoyaltyWhitelist {
    /// @dev Returns true if an address is whitelisted false otherwise
    function isAddressWhitelisted(address target) external view returns (bool);
}
