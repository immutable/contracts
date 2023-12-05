//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./EIP712Upgradeable.sol";

// solhint-disable reason-string
contract EIP712MetaTransaction is EIP712Upgradeable {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes calldata functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external returns (bytes memory) {
        bytes4 destinationFunctionSig = _convertBytesToBytes4(functionSignature);

        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");

        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(_verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");

        unchecked {
            ++nonces[userAddress];
        }
        // Append userAddress at the end to extract it from calling context
        // slither-disable-next-line low-level-calls
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress)); // solhint-disable avoid-low-level-calls

        require(success, "Function call not successful");
        // slither-disable-next-line reentrancy-events
        emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);
        return returnData;
    }

    /**
     @dev Invalidates next "offset" number of nonces for the calling address
     */
    function invalidateNext(uint256 offset) external {
        nonces[msg.sender] += offset;
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function _msgSender() internal view virtual returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            // slither-disable-next-line assembly
            assembly {
                // solhint-disable no-inline-assembly
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function _verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) private view returns (bool) {
        address signer = ecrecover(_hashTypedDataV4(_hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function _hashMetaTransaction(MetaTransaction memory metaTx) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(META_TRANSACTION_TYPEHASH, metaTx.nonce, metaTx.from, keccak256(metaTx.functionSignature))
            );
    }

    function _convertBytesToBytes4(bytes memory inBytes) private pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }
        // slither-disable-next-line assembly
        assembly {
            // solhint-disable no-inline-assembly
            outBytes4 := mload(add(inBytes, 32))
        }
    }
}