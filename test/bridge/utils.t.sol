// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {ERC20PresetMinterPauser} from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {MockAxelarGateway} from "../../contracts/bridge/test/MockAxelarGateway.sol";
import {MockAxelarGasService} from "../../contracts/bridge/test/MockAxelarGasService.sol";
import {RootERC20Bridge} from "../../contracts/bridge/RootERC20Bridge.sol";
import {RootAxelarBridgeAdaptor} from "../../contracts/bridge/RootAxelarBridgeAdaptor.sol";

contract Utils is Test {
    function integrationSetup(address childBridge, address childBridgeAdaptor, string memory childBridgeName)
        public
        returns (
            ERC20PresetMinterPauser token,
            RootERC20Bridge rootBridge,
            RootAxelarBridgeAdaptor axelarAdaptor,
            MockAxelarGateway mockAxelarGateway,
            MockAxelarGasService axelarGasService
        )
    {
        token = new ERC20PresetMinterPauser("Test", "TST");
        token.mint(address(this), 1000000 ether);

        rootBridge = new RootERC20Bridge();
        mockAxelarGateway = new MockAxelarGateway();
        axelarGasService = new MockAxelarGasService();

        axelarAdaptor = new RootAxelarBridgeAdaptor(
            address(rootBridge),
            childBridgeAdaptor,
            childBridgeName,
            address(mockAxelarGateway),
            address(axelarGasService)
        );

        rootBridge.initialize(address(axelarAdaptor), childBridge, address(token));
    }
}
