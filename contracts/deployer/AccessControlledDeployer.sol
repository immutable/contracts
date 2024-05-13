// Copyright Immutable Pty Ltd 2018 - 2024
// SPDX-License-Identifier: Apache 2.0
pragma solidity 0.8.19;

import {IDeployer} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IDeployer.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract AccessControlledDeployer is AccessControlEnumerable, Pausable {
    /// @notice Role identifier for those who can pause the deployer
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER");

    /// @notice Role identifier for those who can unpause the deployer
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER");

    /// @notice Role identifier for those who can deploy contracts
    bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER");

    /**
     * @notice Construct a new RBACDeployer contract
     * @param admin The address to grant the DEFAULT_ADMIN_ROLE
     * @param pauser The address to grant the PAUSER_ROLE
     * @param unpauser The address to grant the UNPAUSER_ROLE
     */
    constructor(address admin, address pauser, address unpauser) {
        require(admin != address(0), "admin is the zero address");
        require(pauser != address(0), "pauser is the zero address");
        require(unpauser != address(0), "unpauser is the zero address");

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(PAUSER_ROLE, pauser);
        _setupRole(UNPAUSER_ROLE, unpauser);
    }

    /**
     * @notice Deploys a contract using a deployment method defined by `deployer`
     * @param deployer The create2 or create3 deployer contract that will deploy the contract
     * @param bytecode The bytecode of the contract to be deployed
     * @param salt A salt to influence the contract address
     * @dev Only address with DEPLOYER_ROLE can call this function
     * @dev The function can only be called if the contract is not in a paused state
     * @return The address of the deployed contract
     */
    function deploy(IDeployer deployer, bytes memory bytecode, bytes32 salt)
        external
        payable
        whenNotPaused
        onlyRole(DEPLOYER_ROLE)
        returns (address)
    {
        require(address(deployer) != address(0), "deployer contract is the zero address");
        return deployer.deploy(bytecode, salt);
    }

    /**
     * @notice Deploys a contract using a deployment method defined by `deployer` and initializes it
     * @param deployer The create2 or create3 deployer contract that will deploy the contract
     * @param bytecode The bytecode of the contract to be deployed
     * @param salt A salt to influence the contract address
     * @param init Init data used to initialize the deployed contract
     * @dev Only address with DEPLOYER_ROLE can call this function
     * @dev The function can only be called if the contract is not in a paused state
     * @return The address of the deployed contract
     */
    function deployAndInit(IDeployer deployer, bytes memory bytecode, bytes32 salt, bytes calldata init)
        external
        payable
        whenNotPaused
        onlyRole(DEPLOYER_ROLE)
        returns (address)
    {
        require(address(deployer) != address(0), "deployer contract is the zero address");
        return deployer.deployAndInit{value: msg.value}(bytecode, salt, init);
    }

    /**
     * @notice Grants a list of addresses the DEPLOYER_ROLE
     * @param deployers list of addresses to grant the DEPLOYER_ROLE
     * @dev Only address with DEFAULT_ADMIN_ROLE can call this function
     * @dev The function emits `RoleGranted` event for each address granted the DEPLOYER_ROLE.
     *      This is not emitted if an address is already a deployer
     */
    function grantDeployerRole(address[] memory deployers) public {
        require(deployers.length > 0, "deployers list is empty");
        for (uint256 i = 0; i < deployers.length; i++) {
            require(deployers[i] != address(0), "deployer is the zero address");
            grantRole(DEPLOYER_ROLE, deployers[i]);
        }
    }

    /**
     * @notice Revokes the DEPLOYER_ROLE for a list of addresses
     * @param deployers list of addresses to revoke the DEPLOYER_ROLE from
     * @dev Only address with DEFAULT_ADMIN_ROLE can call this function
     * @dev The function emits `RoleRevoked` event for each address for which the DEPLOYER_ROLE was revoked
     *      This is not emitted if an address was not a deployer
     */
    function revokeDeployerRole(address[] memory deployers) public {
        require(deployers.length > 0, "deployers list is empty");
        for (uint256 i = 0; i < deployers.length; i++) {
            require(deployers[i] != address(0), "deployer is the zero address");
            revokeRole(DEPLOYER_ROLE, deployers[i]);
        }
    }

    /**
     * @notice Transfers the ownership of `ownableDeployer` from this contract to `newOwner`
     * @param ownableDeployer The create2 or create3 ownable deployer contract to change the owner of
     * @param newOwner The new owner of the deployer contract
     * @dev Only address with DEFAULT_ADMIN_ROLE can call this function
     * @dev This function requires that the current owner of `ownableDeployer` is this contract
     */
    function transferOwnershipOfDeployer(Ownable ownableDeployer, address newOwner)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(address(ownableDeployer) != address(0), "deployer contract is the zero address");
        require(newOwner != address(0), "new owner is the zero address");
        require(ownableDeployer.owner() == address(this), "deployer contract is not owned by this contract");
        ownableDeployer.transferOwnership(newOwner);
    }

    /**
     * @notice Pause the contract, preventing any new deployments
     * @dev Only PAUSER_ROLE can call this function
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the contract if it was paused, re-enabling new deployments
     * @dev Only UNPAUSER_ROLE can call this function
     */
    function unpause() external onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }
}
