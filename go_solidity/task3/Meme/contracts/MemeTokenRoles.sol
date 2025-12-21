// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "./MemeTokenBase.sol";

contract MemeTokenRoles is MemeTokenBase {
    // Role definitions
    bytes32 public constant TAX_MANAGER_ROLE = keccak256("TAX_MANAGER_ROLE");
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
   // 初始化状态标志 
    bool private _rolesInitialized;

    function __MemeTokenRoles_init() internal onlyInitializing {
        // Grant all roles to the deployer initially
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(TAX_MANAGER_ROLE, msg.sender);
        _grantRole(BLACKLIST_MANAGER_ROLE, msg.sender);
        // 设置初始化标志为true
        _rolesInitialized = true;
    }
    function initializeRoles() public initializer {
        // 检查是否已初始化
        require(!_rolesInitialized, "Roles already initialized");
        __MemeTokenRoles_init();
    }
// Pause/Unpause functions
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // UUPS upgrade authorization
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
