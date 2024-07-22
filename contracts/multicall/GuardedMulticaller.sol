// Copyright Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Signature Validation
import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

// Access Control
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

// Reentrancy Guard
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// EIP-712 Typed Structs
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

/**
 *
 * @title GuardedMulticaller contract
 * @author Immutable Game Studio
 * @notice This contract is used to batch calls to other contracts.
 * @dev This contract is not designed to be upgradeable. If an issue is found with this contract,
 *  a new version will be deployed. All approvals granted to this contract will be revoked before
 *  a new version is deployed. Approvals will be granted to the new contract.
 */
contract GuardedMulticaller is AccessControl, ReentrancyGuard, EIP712 {
    /// @dev Mapping of address to function selector to permitted status
    // solhint-disable-next-line named-parameters-mapping
    mapping(address => mapping(bytes4 => bool)) private permittedFunctionSelectors;

    /// @dev Mapping of reference to executed status
    // solhint-disable-next-line named-parameters-mapping
    mapping(bytes32 => bool) private replayProtection;

    /// @dev Only those with MULTICALL_SIGNER_ROLE can generate valid signatures for execute function.
    bytes32 public constant MULTICALL_SIGNER_ROLE = bytes32("MULTICALL_SIGNER_ROLE");

    /// @dev EIP712 typehash for execute function
    bytes32 internal constant MULTICALL_TYPEHASH =
        keccak256("Multicall(bytes32 ref,address[] targets,bytes[] data,uint256 deadline)");

    /// @dev Struct for function permit
    struct FunctionPermit {
        address target;
        bytes4 functionSelector;
        bool permitted;
    }

    /// @dev Event emitted when execute function is called
    event Multicalled(
        address indexed _multicallSigner,
        bytes32 indexed _reference,
        address[] _targets,
        bytes[] _data,
        uint256 _deadline
    );

    /// @dev Event emitted when a function permit is updated
    event FunctionPermitted(address indexed _target, bytes4 _functionSelector, bool _permitted);

    /// @dev Error thrown when reference is invalid
    error InvalidReference(bytes32 _reference);

    /// @dev Error thrown when reference has already been executed
    error ReusedReference(bytes32 _reference);

    /// @dev Error thrown when address array is empty
    error EmptyAddressArray();

    /// @dev Error thrown when address array is empty
    error EmptyFunctionPermitArray();

    /// @dev Error thrown when address array and data array have different lengths
    error AddressDataArrayLengthsMismatch(uint256 _addressLength, uint256 _dataLength);

    /// @dev Error thrown when deadline is expired
    error Expired(uint256 _deadline);

    /// @dev Error thrown when target address is not a contract
    error NonContractAddress(address _target);

    /// @dev Error thrown when signer is not authorized
    error UnauthorizedSigner(address _multicallSigner);

    /// @dev Error thrown when signature is invalid
    error UnauthorizedSignature(bytes _signature);

    /// @dev Error thrown when call reverts
    error FailedCall(address _target, bytes _data);

    /// @dev Error thrown when call data is invalid
    error InvalidCallData(address _target, bytes _data);

    /// @dev Error thrown when call data is unauthorized
    error UnauthorizedFunction(address _target, bytes _data);

    /**
     *
     * @notice Grants DEFAULT_ADMIN_ROLE to the contract creator
     * @param _owner Owner of the contract
     * @param _name Name of the contract
     * @param _version Version of the contract
     */
    // solhint-disable-next-line no-unused-vars
    constructor(address _owner, string memory _name, string memory _version) EIP712(_name, _version) {
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    /**
     * @notice Check if a function selector is permitted.
     *
     * @param _target Contract address
     * @param _functionSelector Function selector
     */
    function isFunctionPermitted(address _target, bytes4 _functionSelector) public view returns (bool) {
        return permittedFunctionSelectors[_target][_functionSelector];
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

    /**
     *
     * @notice Execute a list of calls. Returned data from calls are ignored.
     *  The signature must be generated by an address with EXECUTION_MULTICALL_SIGNER_ROLE
     *  The signature must be valid
     *  The signature must not be expired
     *  The reference must be unique
     *  The reference must not be executed before
     *  The list of calls must not be empty
     *  The list of calls is executed in order
     *
     * @param _multicallSigner Address of an approved signer
     * @param _reference Reference
     * @param _targets List of addresses to call
     * @param _data List of call data
     * @param _deadline Expiration timestamp
     * @param _signature Signature of the multicall signer
     */
    // slither-disable-start low-level-calls,cyclomatic-complexity
    // solhint-disable-next-line code-complexity
    function execute(
        address _multicallSigner,
        bytes32 _reference,
        address[] calldata _targets,
        bytes[] calldata _data,
        uint256 _deadline,
        bytes calldata _signature
    ) external nonReentrant {
        // solhint-disable-next-line not-rely-on-time
        if (_deadline < block.timestamp) {
            revert Expired(_deadline);
        }
        if (_reference == 0) {
            revert InvalidReference(_reference);
        }
        if (replayProtection[_reference]) {
            revert ReusedReference(_reference);
        }
        if (_targets.length == 0) {
            revert EmptyAddressArray();
        }
        if (_targets.length != _data.length) {
            revert AddressDataArrayLengthsMismatch(_targets.length, _data.length);
        }
        for (uint256 i = 0; i < _targets.length; i++) {
            if (_data[i].length < 4) {
                revert InvalidCallData(_targets[i], _data[i]);
            }
            bytes4 functionSelector = bytes4(_data[i][:4]);
            if (!permittedFunctionSelectors[_targets[i]][functionSelector]) {
                revert UnauthorizedFunction(_targets[i], _data[i]);
            }
            if (_targets[i].code.length == 0) {
                revert NonContractAddress(_targets[i]);
            }
        }
        if (!hasRole(MULTICALL_SIGNER_ROLE, _multicallSigner)) {
            revert UnauthorizedSigner(_multicallSigner);
        }

        // Signature validation
        if (
            !SignatureChecker.isValidSignatureNow(
                _multicallSigner,
                _hashTypedData(_reference, _targets, _data, _deadline),
                _signature
            )
        ) {
            revert UnauthorizedSignature(_signature);
        }

        replayProtection[_reference] = true;

        // Multicall
        for (uint256 i = 0; i < _targets.length; i++) {
            // slither-disable-next-line calls-inside-a-loop
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = _targets[i].call(_data[i]);
            if (!success) {
                if (returnData.length == 0) {
                    revert FailedCall(_targets[i], _data[i]);
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(returnData, 32), mload(returnData))
                }
            }
        }

        emit Multicalled(_multicallSigner, _reference, _targets, _data, _deadline);
    }
    // slither-disable-end low-level-calls,cyclomatic-complexity

    /**
     * @notice Update function permits for a list of function selectors on target contracts. Only DEFAULT_ADMIN_ROLE can call this function.
     *
     * @param _functionPermits List of function permits
     */
    function setFunctionPermits(FunctionPermit[] calldata _functionPermits) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_functionPermits.length == 0) {
            revert EmptyFunctionPermitArray();
        }
        for (uint256 i = 0; i < _functionPermits.length; i++) {
            if (_functionPermits[i].target.code.length == 0) {
                revert NonContractAddress(_functionPermits[i].target);
            }
            permittedFunctionSelectors[_functionPermits[i].target][
                _functionPermits[i].functionSelector
            ] = _functionPermits[i].permitted;
            emit FunctionPermitted(
                _functionPermits[i].target,
                _functionPermits[i].functionSelector,
                _functionPermits[i].permitted
            );
        }
    }

    /**
     * @notice Grants MULTICALL_SIGNER_ROLE to a user. Only DEFAULT_ADMIN_ROLE can call this function.
     *
     * @param _user User to grant MULTICALL_SIGNER_ROLE to
     */
    function grantMulticallSignerRole(address _user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MULTICALL_SIGNER_ROLE, _user);
    }

    /**
     * @notice Revokes MULTICALL_SIGNER_ROLE for a user. Only DEFAULT_ADMIN_ROLE can call this function.
     *
     * @param _user User to grant MULTICALL_SIGNER_ROLE to
     */
    function revokeMulticallSignerRole(address _user) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(MULTICALL_SIGNER_ROLE, _user);
    }

    /**
     * @notice Gets whether the reference has been executed before.
     *
     * @param _reference Reference to check
     */
    function hasBeenExecuted(bytes32 _reference) external view returns (bool) {
        return replayProtection[_reference];
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
    function _hashTypedData(
        bytes32 _reference,
        address[] calldata _targets,
        bytes[] calldata _data,
        uint256 _deadline
    ) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        MULTICALL_TYPEHASH,
                        _reference,
                        keccak256(abi.encodePacked(_targets)),
                        hashBytesArray(_data),
                        _deadline
                    )
                )
            );
    }
}