// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "./MemeTokenRoles.sol";

contract MemeTokenTax is MemeTokenRoles {
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public constant TAX_DENOMINATOR = 10000; // denominator for tax calculations

    uint256 public tokensForLiquidity;
    uint256 public tokensForDevelopment;
    uint256 public tokensForMarketing;

    bool private _taxInitialized;

    function __MemeTokenTax_init() internal onlyInitializing {
        // Set default tax rates
        buyTax = 300; // 3% buy tax
        sellTax = 500; // 5% sell tax
        _taxInitialized = true;
    }

     function initializeTax(
        address _routerAddress,
        address marketingWalletAddress,
        address developmentWalletAddress
    ) public initializer {
        // 检查是否已初始化
        require(!_taxInitialized, "Tax already initialized");
        
        // 正确传递参数给父合约初始化函数
        __MemeTokenBase_init(_routerAddress, marketingWalletAddress, developmentWalletAddress);
        __MemeTokenRoles_init();
        __MemeTokenTax_init();
    }


    // Exclude or include an account from fees
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    // Check if an account is excluded from fees
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    // Set buy tax percentage
    function setBuyTax(uint256 _buyTax) external onlyRole(TAX_MANAGER_ROLE) {
        require(_buyTax <= 1000, "MemeToken: Buy tax cannot exceed 10%");
        buyTax = _buyTax;
    }

    // Set sell tax percentage
    function setSellTax(uint256 _sellTax) external onlyRole(TAX_MANAGER_ROLE) {
        require(_sellTax <= 1000, "MemeToken: Sell tax cannot exceed 10%");
        sellTax = _sellTax;
    }

    function setTaxRates(uint256 _buyTax, uint256 _sellTax) external onlyRole(TAX_MANAGER_ROLE) {
        require(_buyTax <= 1000, "MemeToken: Buy tax cannot exceed 10%");
        require(_sellTax <= 1000, "MemeToken: Sell tax cannot exceed 10%");
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    // Set development wallet address
    function setDevelopmentWallet(address wallet) external onlyRole(TAX_MANAGER_ROLE) {
        developmentWallet = wallet;
    }

    // Set marketing wallet address
    function setMarketingWallet(address wallet) external onlyRole(TAX_MANAGER_ROLE) {
        marketingWallet = wallet;
    }
}
