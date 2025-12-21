// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "./MemeTokenBlacklist.sol";

contract MemeTokenTransferRestrictions is MemeTokenBlacklist {
    mapping(address => uint256) internal _lastTransferTimestamp; // to implement transfer delay
    uint256 public transferDelayTime;

    bool private _transferRestrictionsInitialized;

    function __MemeTokenTransferRestrictions_init() internal onlyInitializing {
        // Set default transfer delay
        transferDelayTime = 30 seconds; // 30 seconds delay between transfers
        _transferRestrictionsInitialized = true;
    }

    function initializeTransferRestrictions() public initializer {
        // 检查是否已初始化
        require(!_transferRestrictionsInitialized, "Transfer restrictions already initialized");
        // 初始化角色 授权TAX_MANAGER_ROLE
        __MemeTokenRoles_init();
        // __MemeTokenTax_init();
        __MemeTokenTransferRestrictions_init();
    }

    // Set transfer delay time in seconds
    function setTransferDelayTime(uint256 delayTime) external onlyRole(TAX_MANAGER_ROLE) {
        require(delayTime <= 300, "MemeToken: Transfer delay time cannot exceed 5 minutes");
        transferDelayTime = delayTime;
    }
}
