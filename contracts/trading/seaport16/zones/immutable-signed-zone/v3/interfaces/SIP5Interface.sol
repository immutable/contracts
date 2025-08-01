// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable compiler-version
pragma solidity ^0.8.17;

import {Schema} from "seaport-types-16/src/lib/ConsiderationStructs.sol";
import {SIP5EventsAndErrors} from "./SIP5EventsAndErrors.sol";

/**
 * @dev SIP-5: Contract Metadata Interface for Seaport Contracts
 *      https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-5.md
 */
// This contract name re-use is OK because the SIP5Interface is an interface and not a deployable contract.
// slither-disable-next-line name-reused
interface SIP5Interface is SIP5EventsAndErrors {
    /**
     * @dev Returns Seaport metadata for this contract, returning the
     *      contract name and supported schemas.
     *
     * @return name    The contract name
     * @return schemas The supported SIPs
     */
    function getSeaportMetadata() external view returns (string memory name, Schema[] memory schemas);
}
