// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "./MemeTokenTransferRestrictions.sol";

contract MemeTokenLiquidity is MemeTokenTransferRestrictions {
    bool internal isSwapAndLiquifyEnabled;
    uint256 internal swapTokensAtAmount;
    bool internal inSwapAndLiquify;

    bool private _liquidityInitialized;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    function __MemeTokenLiquidity_init() internal onlyInitializing {
        // Set default liquidity parameters
        isSwapAndLiquifyEnabled = true;
        swapTokensAtAmount = 500_000 * 10 ** 18; // 500,000 tokens
        _liquidityInitialized = true;
    }

       // 初始化流动性参数 测试
    function initializeLiquidity(
        address _routerAddress,
        address marketingWalletAddress,
        address developmentWalletAddress
    ) public initializer {
        // 检查是否已初始化
        require(!_liquidityInitialized, "Liquidity already initialized");
        // 初始化基础合约（设置 owner 等）
        __MemeTokenBase_init(_routerAddress, marketingWalletAddress, developmentWalletAddress);
        // 初始化角色
        __MemeTokenRoles_init();
        // 初始化税费
        __MemeTokenTax_init();
        // 初始化流动性
        __MemeTokenLiquidity_init();
    }

    // Enable or disable swap and liquify
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        isSwapAndLiquifyEnabled = enabled;
    }

    // Set the token amount threshold for swapping
    function setSwapTokensAtAmount(uint256 amount) external onlyRole(TAX_MANAGER_ROLE) {
        require(amount >= 100_000 * 10 ** 18, "MemeToken: Swap tokens at amount must be at least 100,000 tokens");
        swapTokensAtAmount = amount;
    }

    // Get the swap tokens at amount threshold
    function getSwapTokensAtAmount() external view returns (uint256) {
        return swapTokensAtAmount;
    }

    // Withdraw ETH from the contract
    function withdrawETH(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "MemeToken: Insufficient ETH balance");
        Address.sendValue(payable(owner()), amount);
    }

    // Withdraw tokens from the contract
    function withdrawTokens(uint256 amount) external onlyOwner {
        require(amount <= balanceOf(address(this)), "MemeToken: Insufficient token balance");
        _update(address(this), owner(), amount);
    }
    // To receive ETH from uniswapV2Router when swapping or directly from users
    receive() external virtual payable {}
}
