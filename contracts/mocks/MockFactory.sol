pragma solidity ^0.8.0;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";

contract MockFactory {
    function computeAddress(bytes32 salt, bytes32 codeHash) public view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }

    function deploy(bytes32 salt, bytes memory code) public {
        Create2.deploy(0, salt, code);
    }
}
