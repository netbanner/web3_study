// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "./MemeTokenTax.sol";

contract MemeTokenBlacklist is MemeTokenTax {
    mapping(address => bool) public blacklistedBots;

    bool private _blacklistInitialized;

     function __MemeTokenBlacklist_init() internal onlyInitializing {
        // No state variables to initialize in this contract
        _blacklistInitialized = true;
    }

    event Blacklisted(address indexed bot, bool value);
    
    function initializeBlacklist() public initializer {
        // 检查是否已初始化
        require(!_blacklistInitialized, "Blacklist already initialized");
        // 初始化角色 授权BLACKLIST_MANAGER_ROLE
        __MemeTokenRoles_init();
       // __MemeTokenTax_init();
        __MemeTokenBlacklist_init();
    }   

    // Blacklist or unblacklist a bot address
    function addToBlacklist(address bot, bool value) external onlyRole(BLACKLIST_MANAGER_ROLE) {
        require(bot != address(0), "Zero address");
        // Whitelisted addresses can never be blacklisted
        require(
            !value ||
                (!_isExcludedFromFees[bot] &&
                    bot != uniswapV2Pair &&
                    bot != address(uniswapV2Router)),
            "Cannot blacklist whitelisted address"
        );
        blacklistedBots[bot] = value;
        emit Blacklisted(bot,value);
    }

    // Check if an address is blacklisted
    function isBlacklisted(address bot) public view returns (bool) {
        return blacklistedBots[bot];
    }
}
