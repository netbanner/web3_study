// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "./MemeTokenLiquidity.sol";

contract MemeTokenUniswap is MemeTokenLiquidity {
    mapping(address => bool) public automatedMarketMakerPairs;

    bool private _uniswapInitialized;

    function __MemeTokenUniswap_init() internal onlyInitializing {
        // Mark the Uniswap V2 pair as an automated market maker pair
        automatedMarketMakerPairs[uniswapV2Pair] = true;
        _uniswapInitialized = true;
    }

    // 初始化Uniswap参数 测试
    function initializeUniswap(address _routerAddress, address marketingWalletAddress, address developmentWalletAddress) public initializer {
        // 检查是否已初始化
        require(!_uniswapInitialized, "Uniswap already initialized");
          // 初始化基础合约（设置 owner 等）
        __MemeTokenBase_init(_routerAddress, marketingWalletAddress, developmentWalletAddress);
        // 初始化角色 授权TAX_MANAGER_ROLE
        __MemeTokenRoles_init();
         __MemeTokenTax_init();
         __MemeTokenTransferRestrictions_init();
         __MemeTokenLiquidity_init();
        __MemeTokenUniswap_init();
    }

    // Add initial liquidity to Uniswap
    function addInitialLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount
    ) external onlyOwner {
        require(tokenAmount > 0 && ethAmount > 0, "Amounts must be greater than zero");
        require(address(this).balance >= ethAmount, "Not enough ETH in contract");
        require(balanceOf(msg.sender) >= tokenAmount, "Not enough tokens");
        
        // Transfer the tokens from the owner to the contract
        _update(msg.sender, address(this), tokenAmount);

        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Slippage tolerance set to 1%
        uint256 minTokenAmount = (tokenAmount * 99) / 100; // 99% of tokenAmount
        uint256 minETHAmount = (ethAmount * 99) / 100; // 99% of ethAmount
        
        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            minTokenAmount,
            minETHAmount,
            owner(),
            block.timestamp
        );

        emit LiquidityAdded(tokenAmount, ethAmount, block.timestamp);
    }

    // Set automated market maker pair
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

    // Update Uniswap V2 Router address
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "MemeToken: The router address is already set to the new address");
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address newPair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = newPair;
        automatedMarketMakerPairs[newPair] = true;
    }

    // Swap tokens for ETH
    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the Uniswap pair path of token -> WETH
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    // Add liquidity to Uniswap
    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 minTokenAmount,
        uint256 minETHAmount
    ) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            minTokenAmount,
            minETHAmount,
            owner(),
            block.timestamp
        );
    }

    // Distribute taxes to respective buckets
    function distributeTaxes(uint256 taxAmount, bool isSell) internal {
        uint256 liquidityShare;
        uint256 developmentShare;
        uint256 marketingShare;
        
        // Allocate tax amounts
        if (isSell) {
            liquidityShare = (taxAmount * 40) / 100; // 40% for liquidity
            developmentShare = (taxAmount * 30) / 100; // 30% for development
            marketingShare = (taxAmount * 30) / 100; // 30% for marketing
        } else {
            liquidityShare = (taxAmount * 30) / 100; // 30% for liquidity
            developmentShare = (taxAmount * 35) / 100; // 35% for development
            marketingShare = (taxAmount * 35) / 100; // 35% for marketing
        }
        
        tokensForLiquidity += liquidityShare;
        tokensForDevelopment += developmentShare;
        tokensForMarketing += marketingShare;
        
        super._update(address(this), developmentWallet, developmentShare);
        super._update(address(this), marketingWallet, marketingShare);
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        
        // Swap and liquify if conditions are met
        // Only trigger swap on sell transactions when not already in a swap
        if (canSwap && !inSwapAndLiquify && isSell && isSwapAndLiquifyEnabled) {
            swapAndLiquify();
        }
    }

    // Swap and liquify tokens
    function swapAndLiquify() private lockTheSwap {
        // Get the contract's current token balance
        uint256 contractTokenBalance = balanceOf(address(this));
        
        // Avoid swapping with zero tokens
        if (contractTokenBalance == 0) {
            return;
        }
    
        // Split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
    
        // Capture the contract's current ETH balance
        uint256 initialBalance = address(this).balance;
    
        // Swap tokens for ETH
        swapTokensForEth(half);
    
        // How much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;
        
        // Avoid adding liquidity with zero ETH
        if (newBalance == 0) {
            return;
        }
    
        uint256 minTokenAmount = (otherHalf * 99) / 100;
        uint256 minETHAmount = (newBalance * 99) / 100;
        
        // Add liquidity to Uniswap
        addLiquidity(otherHalf, newBalance, minTokenAmount, minETHAmount);
    
        emit LiquidityAdded(otherHalf, newBalance, block.timestamp);
    }
}