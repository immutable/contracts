// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.8.29;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract MockEIP1271Wallet is IERC1271 {
    address public immutable OWNER;

    constructor(address _owner) {
        // slither-disable-next-line missing-zero-check
        OWNER = _owner;
    }

    function isValidSignature(bytes32 hash, bytes memory signature) public view override returns (bytes4) {
        address recoveredAddress = ECDSA.recover(hash, signature);
        if (recoveredAddress == OWNER) {
            return this.isValidSignature.selector;
        } else {
            return 0;
        }
    }

    function onERC721Received(
        address /* operator */,
        address /* from */,
        uint256 /* tokenId */,
        bytes calldata /* data */
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}
