// Copyright (c) Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {RandomSeedProvider} from "contracts/random/RandomSeedProvider.sol";

contract MockRandomSeedProviderV2 is RandomSeedProvider {
    uint256 internal constant VERSION2 = 2;

    function upgrade() external override(RandomSeedProvider) {
        if (version == VERSION0) {
            version = VERSION2;
        } else {
            revert CanNotUpgradeFrom(version, VERSION2);
        }
    }
}
