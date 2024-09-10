// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockFactory {
    bytes private constant MOCK_DISGUISED_EOA_BYTECODE =
        hex"608060405234801561001057600080fd5b5060405161021338038061021383398101604081905261002f91610054565b600080546001600160a01b0319166001600160a01b0392909216919091179055610084565b60006020828403121561006657600080fd5b81516001600160a01b038116811461007d57600080fd5b9392505050565b610180806100936000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c80639d76ea581461003b578063e58ef8a81461006a575b600080fd5b60005461004e906001600160a01b031681565b6040516001600160a01b03909116815260200160405180910390f35b61007d61007836600461010e565b61007f565b005b6000546040516323b872dd60e01b81526001600160a01b038581166004830152848116602483015260448201849052909116906323b872dd90606401600060405180830381600087803b1580156100d557600080fd5b505af11580156100e9573d6000803e3d6000fd5b50505050505050565b80356001600160a01b038116811461010957600080fd5b919050565b60008060006060848603121561012357600080fd5b61012c846100f2565b925061013a602085016100f2565b915060408401359050925092509256fea2646970667358221220cc26e879b9dbccdd8ff34bda1c5675a4b1a8497cba91bea35b6b744a41374a9a64736f6c63430008130033";

    function computeAddress(bytes32 salt, bytes32 codeHash) public view returns (address) {
        return Create2.computeAddress(salt, codeHash);
    }

    function deploy(bytes32 salt, bytes memory code) public {
        // slither-disable-next-line unused-return
        Create2.deploy(0, salt, code);
    }

    function deployMockEOAWithERC721Address(IERC721 tokenAddress, bytes32 salt) external returns (address) {
        bytes memory encodedParams = abi.encode(address(tokenAddress));
        bytes memory constructorBytecode = abi.encodePacked(bytes(MOCK_DISGUISED_EOA_BYTECODE), encodedParams);
        address mockDisguisedEOAAddress = Create2.deploy(0, salt, constructorBytecode);

        return mockDisguisedEOAAddress;
    }

    function computeMockDisguisedEOAAddress(IERC721 tokenAddress, bytes32 salt) external view returns (address) {
        bytes memory encodedParams = abi.encode(address(tokenAddress));
        bytes memory constructorBytecode = abi.encodePacked(bytes(MOCK_DISGUISED_EOA_BYTECODE), encodedParams);
        address computedAddress = Create2.computeAddress(salt, keccak256(constructorBytecode));

        return computedAddress;
    }
}
