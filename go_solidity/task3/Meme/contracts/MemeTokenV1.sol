// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "./MemeTokenUniswap.sol";

contract MemeTokenV1 is MemeTokenUniswap {
    function initialize(
        address _routerAddress,
        address marketingWalletAddress,
        address developmentWalletAddress
    ) public initializer {
        // Initialize all parent contracts
        __MemeTokenBase_init(_routerAddress, marketingWalletAddress, developmentWalletAddress);
        __MemeTokenRoles_init();
        __MemeTokenTax_init();
        __MemeTokenBlacklist_init();
        __MemeTokenTransferRestrictions_init();
        __MemeTokenLiquidity_init();
        __MemeTokenUniswap_init();

        // Initialize exclusions
        // Exclude owner from fees
        _setExcludedFromFees(owner(), true);
        // Exclude contract address from fees
        _setExcludedFromFees(address(this), true);
        _setExcludedFromFees(uniswapV2Pair, true);
        _setExcludedFromFees(developmentWallet, true);
        _setExcludedFromFees(marketingWallet, true);

        // Exclude addresses from max transaction amount
        _setExcludedFromMaxTx(address(uniswapV2Router), true);
        _setExcludedFromMaxTx(owner(), true);
        _setExcludedFromMaxTx(address(this), true);
        _setExcludedFromMaxTx(address(uniswapV2Pair), true);

        // Exclude addresses from max wallet balance
        _setExcludedFromMaxWallet(owner(), true);
        _setExcludedFromMaxWallet(developmentWallet, true);
        _setExcludedFromMaxWallet(marketingWallet, true);
        _setExcludedFromMaxWallet(uniswapV2Pair, true);
        _setExcludedFromMaxWallet(address(uniswapV2Router), true);
        _setExcludedFromMaxWallet(address(this), true);
    }

    // Custom _update function to handle taxes and restrictions
    function _update(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // If sender is address(0), this is a mint operation - skip all restrictions
        if (sender == address(0)) {
            return super._update(sender, recipient, amount);
        }
        // If either sender or recipient is the contract itself, bypass fees
        if (sender == address(this) || recipient == address(this)) {
            return super._update(sender, recipient, amount);
        }
        
        // Check blacklist
        require(!blacklistedBots[sender] && !blacklistedBots[recipient], "MemeToken: Blacklisted address");
        
        // Check amount is positive
        require(amount > 0, "MemeToken: Transfer amount must be greater than zero");
        
        // If either sender or recipient is excluded from fees, bypass fees and restrictions
        if (isExcludedFromFees(sender) || isExcludedFromFees(recipient)) {
            super._update(sender, recipient, amount);
            return;
        }
        
        // Check max transaction amount
        require(
            amount <= MAX_TX_AMOUNT ||
                _isExcludedFromMaxTransaction[sender] ||
                _isExcludedFromMaxTransaction[recipient],
            "MemeToken: Transfer amount exceeds the max transaction amount"
        );
        
        // Check max wallet balance
        require(
            balanceOf(recipient) + amount <= MAX_WALLET_BALANCE ||
                _isExcludedFromMaxWallet[recipient],
            "MemeToken: Recipient balance exceeds the max wallet balance"
        );
        
        // Enforce transfer delay
        if (sender != owner() && recipient != owner()) {
            require(
                block.timestamp - _lastTransferTimestamp[sender] >= transferDelayTime,
                "MemeToken: Transfer delay enabled. Please wait before making another transfer."
            );
            _lastTransferTimestamp[sender] = block.timestamp;
        }
    
        // Calculate taxes
        uint256 taxAmount = 0;
        uint256 taxRate = 0;
        bool isSell = false;
        
        if (sender == uniswapV2Pair) {
            // Buy transaction
            taxRate = buyTax;
        } else if (recipient == uniswapV2Pair) {
            // Sell transaction
            taxRate = sellTax;
            isSell = true;
        } else {
            revert("MemeToken: Transfer not allowed outside pair");
        }
        
        taxAmount = (amount * taxRate) / TAX_DENOMINATOR;
        uint256 transferAmount = amount - taxAmount;
        
        // Transfer the tax amount to the contract and the remaining amount to the recipient
        if (taxAmount > 0) {
            // First transfer the tax amount to the contract
            super._update(sender, address(this), taxAmount);
            // Then transfer the remaining amount to the recipient
            super._update(sender, recipient, transferAmount);
            // Finally distribute the taxes
            distributeTaxes(taxAmount, isSell);
        } else {
            // If no tax, just transfer the amount to the recipient
            super._update(sender, recipient, transferAmount);
        }
    }

    // Get contract's ETH balance
    function getContractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Get contract's token balance
    function getContractTokenBalance() external view returns (uint256) {
        return balanceOf(address(this));
    }

    // Get Uniswap V2 pool information
    function getPoolInfo()
        external
        view
        returns (
            address pair,
            uint112 reserveToken,
            uint112 reserveETH,
            uint32 blockTimestampLast
        )
    {
        pair = uniswapV2Pair;
        (uint112 r0, uint112 r1, uint32 bt) = IUniswapV2Pair(pair).getReserves();

        // Determine if MEME is token0 or token1 in the pair
        if (address(this) < uniswapV2Router.WETH()) {
            reserveToken = r0;
            reserveETH = r1;
        } else {
            reserveToken = r1;
            reserveETH = r0;
        }
        blockTimestampLast = bt;
    }

    // Verify a transfer would be accepted
    function verifyTransfer(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint8 code, string memory reason) {
        if (blacklistedBots[from] || blacklistedBots[to]) {
            return (1, "Blacklisted");
        }

        if (!_isExcludedFromMaxTransaction[from] && !_isExcludedFromMaxTransaction[to] && amount > MAX_TX_AMOUNT) {
            return (2, "Max tx exceeded");
        }

        uint256 toBalance = balanceOf(to);
        if (!_isExcludedFromMaxWallet[to] && toBalance + amount > MAX_WALLET_BALANCE) {
            return (3, "Max wallet exceeded");
        } 

        if (from != owner() && to != owner()) {
            if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                uint256 last = _lastTransferTimestamp[from];
                if (block.timestamp - last < transferDelayTime) {
                    return (4, "Transfer delay");
                }
            }
        }

        bool isBuy = from == uniswapV2Pair;
        bool isSell = to == uniswapV2Pair;
        if (!isBuy && !isSell) {
            return (5, "Only buy/sell allowed");
        }

        return (0, "OK");
    }

    // Get current tax rates
    function getCurrentTaxRates() external view returns (uint256 buy, uint256 sell) {
        buy = buyTax;
        sell = sellTax;
    }

    // Calculate tax for a given amount
    function calcTax(uint256 amount, bool isBuy) external view returns (uint256 tax, uint256 _receive) {
        uint256 rate = isBuy ? buyTax : sellTax;
        tax = amount * rate / TAX_DENOMINATOR;
        _receive = amount - tax;
    }

    // Mint function with max supply check
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "MemeToken: Max supply exceeded");
        _mint(to, amount);
    }

    // To receive ETH from uniswapV2Router when swapping
    receive() external override payable {}
}