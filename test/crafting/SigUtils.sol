// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

contract SigUtils {
    bytes32 internal _DOMAIN_SEPARATOR;

    bytes32 internal constant MULTICALL_TYPEHASH =
        keccak256("Multicall(bytes32 ref,address[] targets,bytes[] data,uint256 deadline)");

    constructor(string memory _name, string memory _version, address _verifyingContract) {
      _DOMAIN_SEPARATOR = keccak256(
          abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(_name)),
            keccak256(bytes(_version)),
            block.chainid,
            _verifyingContract
          )
      );
    }

    /**
     *
     * @dev Returns hash of array of bytes
     *
     * @param _data Array of bytes
     */
    function hashBytesArray(bytes[] memory _data) public pure returns (bytes32) {
        bytes32[] memory hashedBytesArr = new bytes32[](_data.length);
        for (uint256 i = 0; i < _data.length; i++) {
            hashedBytesArr[i] = keccak256(_data[i]);
        }
        return keccak256(abi.encodePacked(hashedBytesArr));
    }

    function getStructHash(
      bytes32 _reference,
      address[] calldata _targets,
      bytes[] calldata _data,
      uint256 _deadline
    ) internal pure returns (bytes32)
    {
      return keccak256(
        abi.encode(
          MULTICALL_TYPEHASH,
          _reference,
          keccak256(abi.encodePacked(_targets)),
          hashBytesArray(_data),
          _deadline
        )
      );
    }

    /**
     *
     * @dev Returns EIP712 message hash for given parameters
     *
     * @param _reference Reference
     * @param _targets List of addresses to call
     * @param _data List of call data
     * @param _deadline Expiration timestamp
     */
    function getTypedDataHash(
      bytes32 _reference,
        address[] calldata _targets,
        bytes[] calldata _data,
        uint256 _deadline
    ) public view returns (bytes32) {
      return keccak256(
        abi.encodePacked(
          "\x19\x01",
          _DOMAIN_SEPARATOR,
          getStructHash(_reference, _targets, _data, _deadline)
        )
      );
    }
}
