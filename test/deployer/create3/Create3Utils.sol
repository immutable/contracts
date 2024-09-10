// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IDeployer} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeployer.sol";

contract Create3Utils is Test {
    function predictCreate3Address(IDeployer _deployer, address _sender, bytes32 _salt) public view returns (address) {
        return _deployer.deployedAddress("", _sender, _salt);
    }
}
