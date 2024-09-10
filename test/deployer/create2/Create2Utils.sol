// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.24;

import "forge-std/Test.sol";

contract Create2Utils is Test {
    function predictCreate2Address(bytes memory _bytecode, address _deployer, address _sender, bytes32 _salt)
        public
        pure
        returns (address)
    {
        bytes32 deploySalt = keccak256(abi.encode(_sender, _salt));
        return address(
            uint160(uint256(keccak256(abi.encodePacked(hex"ff", address(_deployer), deploySalt, keccak256(_bytecode)))))
        );
    }

    function createSaltFromKey(string memory key, address owner) public pure returns (bytes32) {
        return keccak256(abi.encode(address(owner), key));
    }
}
