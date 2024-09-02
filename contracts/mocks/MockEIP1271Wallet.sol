// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

contract MockEIP1271Wallet is IERC1271 {
    address public immutable owner;

    constructor(address _owner) {
        // slither-disable-next-line missing-zero-check
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
