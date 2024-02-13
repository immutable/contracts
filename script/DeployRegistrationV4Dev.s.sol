pragma solidity ^0.8.20;

import {Registration} from "../contracts/bridge/x/v4/Registration.sol";
import {Script} from "forge-std/Script.sol";

contract DeployRegistrationV4Dev is Script {
    address public DEV_CONTRACT = 0x590C809bd5FF50DCb39e4320b60139B29B880174;
    uint256 private SEPOLIA_CHAIN_ID = 11155111;

    Registration public registration;

    function run() external returns (Registration) {
        require(block.chainid == SEPOLIA_CHAIN_ID, "wrong chain id, please use sepolia chain");

        vm.startBroadcast();
        registration = new Registration(payable(DEV_CONTRACT));
        vm.stopBroadcast();
        return registration;
    }
}
