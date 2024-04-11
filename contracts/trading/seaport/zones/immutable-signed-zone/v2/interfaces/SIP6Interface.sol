// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache-2

// solhint-disable compiler-version
pragma solidity ^0.8.17;

import {Schema} from "seaport-types/src/lib/ConsiderationStructs.sol";
import {SIP6EventsAndErrors} from "./SIP6EventsAndErrors.sol";

/**
 * @dev SIP-6: Multi-Zone ExtraData
 *      https://github.com/ProjectOpenSea/SIPs/blob/main/SIPS/sip-6.md
 */
interface SIP6Interface is SIP6EventsAndErrors {}
