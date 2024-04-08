// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity =0.8.20;

import "forge-std/Test.sol";
import {GemGame} from "../../../contracts/games/gems/GemGame.sol";

contract GemGameTest is Test {
    event GemEarned(address indexed account, uint256 timestamp);

    GemGame gemGame;

    function setUp() public {
        gemGame = new GemGame();
    }

    function testEarnGem_EmitsGemEarnedEvent() public {
        vm.expectEmit(true, true, false, false);
        emit GemEarned(address(this), block.timestamp);
        gemGame.earnGem();
    }
}
