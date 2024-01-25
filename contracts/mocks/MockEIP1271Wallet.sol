// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract MockEIP1271Wallet is IERC1271 {
    address public immutable owner;

    constructor(address _owner) {
        owner = _owner;
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view override returns (bytes4) {
        address recoveredAddress = ECDSA.recover(hash, signature);
        if (recoveredAddress == owner) {
            return this.isValidSignature.selector;
        } else {
            return 0;
        }
    }
}
