// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract MemeToken is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // 1. 角色定义
    bytes32 public constant TAX_MANAGER_ROLE = keccak256("TAX_MANAGER_ROLE");
    bytes32 public constant BLACKLIST_MANAGER_ROLE =
        keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens with 18 decimals
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10 ** 18; // 100 million tokens with 18 decimals
    uint256 public constant MAX_TX_AMOUNT = 10_000_000 * 10 ** 18; //every tx max 10 million tokens with 18 decimals
    uint256 public constant MAX_WALLET_BALANCE = 20_000_000 * 10 ** 18; //every wallet max 20 million tokens with 18 decimals

    uint256 public buyTax = 300; // 3% buy tax
    uint256 public sellTax = 500; // 5% sell tax
    uint256 public constant TAX_DENOMINATOR = 10000; // denominator for tax calculations

    uint256 public tokensForLiquidity;
    uint256 public tokensForDevelopment;
    uint256 public tokensForMarketing;

    address public developmentWallet;
    address public marketingWallet;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private isSwapAndLiquifyEnabled = true;
    uint256 private swapTokensAtAmount = 500_000 * 10 ** 18; // 500,000 tokens
    bool private inSwapAndLiquify;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTransaction;
    mapping(address => bool) private _isExcludedFromMaxWallet;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) public blacklistedBots;
    mapping(address => uint256) private _lastTransferTimestamp; // to implement transfer delay
    uint256 public transferDelayTime = 30 seconds; // 30 seconds delay between transfers

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event LiquidityAdded(
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 timestamp
    );

    function initialize(
        address _routerAddress,
        address marketingWalletAddress,
        address developmentWalletArress
    ) public initializer {
        __ERC20_init("MemeToken", "MEME");
        __Ownable_init(msg.sender);
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(TAX_MANAGER_ROLE, msg.sender);
        _grantRole(BLACKLIST_MANAGER_ROLE, msg.sender);
        // Mint the initial supply to the deployer
        _mint(msg.sender, INITIAL_SUPPLY);

        developmentWallet = developmentWalletArress;
        marketingWallet = marketingWalletAddress;
        uniswapV2Router = IUniswapV2Router02(_routerAddress); // Uniswap V2 Router
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        // Mark the Uniswap V2 pair as an automated market maker pair
        automatedMarketMakerPairs[uniswapV2Pair] = true;

        // Initialize exclusions below whilte list
        // Exclude owner from fees
        _isExcludedFromFees[owner()] = true;
        // Exclude contract address from fees
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[uniswapV2Pair] = true;
        _isExcludedFromFees[developmentWallet] = true;
        _isExcludedFromFees[marketingWallet] = true;

        // Exclude Uniswap V2 Router from max transaction amount
        _isExcludedFromMaxTransaction[address(uniswapV2Router)] = true;
        // Exclude owner from max transaction amount
        _isExcludedFromMaxTransaction[owner()] = true;
        // Exclude contract address from max transaction amount
        _isExcludedFromMaxTransaction[address(this)] = true;
        _isExcludedFromMaxTransaction[address(uniswapV2Pair)] = true;

        // Exclude owner from max wallet balance
        _isExcludedFromMaxWallet[owner()] = true;
        _isExcludedFromMaxWallet[developmentWallet] = true;
        _isExcludedFromMaxWallet[marketingWallet] = true;
        _isExcludedFromMaxWallet[uniswapV2Pair] = true;
        _isExcludedFromMaxWallet[address(uniswapV2Router)] = true;
        // Exclude contract address from max wallet balance

        _isExcludedFromMaxWallet[address(this)] = true;
        // Approve the maximum token allowance to the Uniswap V2 Router
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /**
     * @dev  the _mint function to enforce the maximum supply limit.
     * @param to  the address to mint tokens to
     * @param amount the amount of tokens to mint
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(
            totalSupply() + amount <= MAX_SUPPLY,
            "MemeToken: Max supply exceeded"
        );
        _mint(to, amount);
    }

    function addInitialLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount
    ) external onlyOwner {
        require(
            tokenAmount > 0 && ethAmount > 0,
            "Amounts must be greater than zero"
        );
        require(
            address(this).balance >= ethAmount,
            "Not enough ETH in contract"
        );
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

    // Exclude or include an account from fees
    function excludeFromFees(
        address account,
        bool excluded
    ) external onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    // Check if an account is excluded from fees
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    // Set automated market maker pair
    function setAutomatedMarketMakerPair(
        address pair,
        bool value
    ) external onlyOwner {
        automatedMarketMakerPairs[pair] = value;
    }

    // Blacklist or unblacklist a bot address
    function setBlacklistedBot(
        address bot,
        bool value
    ) external onlyRole(BLACKLIST_MANAGER_ROLE) {
        require(bot != address(0), "Zero address");
        // 白名单地址永远拉不黑
        require(
            !value ||
                (!_isExcludedFromFees[bot] &&
                    bot != uniswapV2Pair &&
                    bot != address(uniswapV2Router)),
            "Cannot blacklist whitelisted address"
        );
        blacklistedBots[bot] = value;
    }

    // Check if an address is blacklisted
    function isBlacklistedBot(address bot) public view returns (bool) {
        return blacklistedBots[bot];
    }

    // Set buy tax percentage
    function setBuyTax(uint256 _buyTax) external onlyRole(TAX_MANAGER_ROLE) {
        require(_buyTax <= 1000, "MemeToken: Buy tax cannot exceed 10%");
        buyTax = _buyTax;
    }

    // Set sell tax percentage
    function setSellTax(uint256 _sellTax) external onlyRole(TAX_MANAGER_ROLE) {
        require(_sellTax <= 1000, "MemeToken: Sell tax cannot exceed    10%");
        sellTax = _sellTax;
    }

    // Set transfer delay time in seconds
    function setTransferDelayTime(
        uint256 delayTime
    ) external onlyRole(TAX_MANAGER_ROLE) {
        require(
            delayTime <= 300,
            "MemeToken: Transfer delay time cannot exceed 5 minutes"
        );
        transferDelayTime = delayTime;
    }

    // Set development wallet address
    function setDevelopmentWallet(
        address wallet
    ) external onlyRole(TAX_MANAGER_ROLE) {
        developmentWallet = wallet;
    }

    // Set marketing wallet address
    function setMarketingWallet(
        address wallet
    ) external onlyRole(TAX_MANAGER_ROLE) {
        marketingWallet = wallet;
    }

    // Enable or disable swap and liquify
    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        isSwapAndLiquifyEnabled = enabled;
    }

    // Set the token amount threshold for swapping
    function setSwapTokensAtAmount(
        uint256 amount
    ) external onlyRole(TAX_MANAGER_ROLE) {
        require(
            amount >= 100_000 * 10 ** 18,
            "MemeToken: Swap tokens at amount must be at least 100,000 tokens"
        );
        swapTokensAtAmount = amount;
    }

    // Get contract's ETH balance
    function getContractETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Get contract's token balance
    function getContractTokenBalance() external view returns (uint256) {
        return balanceOf(address(this));
    }

    function withdrawETH(uint256 amount) external onlyOwner {
        require(
            amount <= address(this).balance,
            "MemeToken: Insufficient ETH balance"
        );
        Address.sendValue(payable(owner()), amount);
    }

    function withdrawTokens(uint256 amount) external onlyOwner {
        require(
            amount <= balanceOf(address(this)),
            "MemeToken: Insufficient token balance"
        );
        _update(address(this), owner(), amount);
    }

    // Update Uniswap V2 Router address
    function updateUniswapV2Router(address newAddress) external onlyOwner {
        require(
            newAddress != address(uniswapV2Router),
            "MemeToken: The router address is already set to the new address"
        );
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address newPair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = newPair;
        automatedMarketMakerPairs[newPair] = true;
    }

    //统一维护白名单映射
    function _setExcludedFromFees(address _a, bool _b) private {
        _isExcludedFromFees[_a] = _b;
    }

    function _setExcludedFromMaxTx(address _a, bool _b) private {
        _isExcludedFromMaxTransaction[_a] = _b;
    }

    function _setExcludedFromMaxWallet(address _a, bool _b) private {
        _isExcludedFromMaxWallet[_a] = _b;
    }

    function _update(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // If either sender or recipient is the contract itself, bypass fees
        if (sender == address(this) || recipient == address(this)) {
            return super._update(sender, recipient, amount);
        }
        require(
            !blacklistedBots[sender] && !blacklistedBots[recipient],
            "MemeToken: Blacklisted address"
        );
        require(
            amount > 0,
            "MemeToken: Transfer amount must be greater than zero"
        );
        require(
            amount <= MAX_TX_AMOUNT ||
                _isExcludedFromMaxTransaction[sender] ||
                _isExcludedFromMaxTransaction[recipient],
            "MemeToken: Transfer amount exceeds the max transaction amount"
        );
        require(
            balanceOf(recipient) + amount <= MAX_WALLET_BALANCE ||
                _isExcludedFromMaxWallet[recipient],
            "MemeToken: Recipient balance exceeds the max wallet balance"
        );
        // Transfer delay enforcement
        if (sender != owner() && recipient != owner()) {
            if (
                !_isExcludedFromFees[sender] && !_isExcludedFromFees[recipient]
            ) {
                require(
                    block.timestamp - _lastTransferTimestamp[sender] >=
                        transferDelayTime,
                    "MemeToken: Transfer delay enabled. Please wait before making another transfer."
                );
                _lastTransferTimestamp[sender] = block.timestamp;
            }
        }

        // If either sender or recipient is excluded from fees, bypass fees
        if (isExcludedFromFees(sender) || isExcludedFromFees(recipient)) {
            super._update(sender, recipient, amount);
            return;
        }

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
        if (taxAmount > 0) {
            distributeTaxes(taxAmount, isSell);
        }
        super._update(sender, recipient, transferAmount);
    }

    // Distribute taxes to respective buckets
    function distributeTaxes(uint256 taxAmount, bool isSell) private {
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
        // Swap and liquify if conditions are sent
        // 触发 swap 的条件：只在卖交易且合约缓存币足够且不在重入锁中
        // Only trigger swap on sell transactions when not already in a swap
        if (canSwap && !inSwapAndLiquify && isSell && isSwapAndLiquifyEnabled) {
            swapAndLiquify(contractTokenBalance);
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // Split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // Capture the contract's current ETH balance.
        uint256 initialBalance = address(this).balance;

        // Swap tokens for ETH
        swapTokensForEth(half);

        // How much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;
        // Avoid adding liquidity with zero ETH
        if (newBalance == 0) {
            return;
        }

        uint256 minToken = (otherHalf * 99) / 100;
        uint256 minETH = (newBalance * 99) / 100;
        // Add liquidity to Uniswap
        addLiquidity(otherHalf, newBalance, minToken, minETH);

        emit LiquidityAdded(otherHalf, newBalance, block.timestamp);
    }

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

    /**
     *   获取 Uniswap V2 池的信息
     * @return pair           池地址
     * @return reserveToken   池内 MEME 数量（当前 reserve0/1 中对应 MEME 的那一项）
     * @return reserveETH     池内 ETH 数量
     * @return blockTimestampLast  最近一次同步区块时间戳
     */
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
        (uint112 r0, uint112 r1, uint32 bt) = IUniswapV2Pair(pair)
            .getReserves();

        // MEME 是 pair 的 token0 还是 token1？比地址大小
        if (address(this) < uniswapV2Router.WETH()) {
            reserveToken = r0;
            reserveETH = r1;
        } else {
            reserveToken = r1;
            reserveETH = r0;
        }
        blockTimestampLast = bt;
    }

    /**
     *  验证某笔转账是否会被合约接受
     * @param from   发起方
     * @param to     接收方
     * @param amount 数量（wei）
     * @return code  0=通过  1=黑名单  2=超单笔限额  3=超钱包限额  4=冷却中  5=非买卖
     * @return reason 可读原因
     */
    function verifyTransfer( address from,address to,uint256 amount
    ) external view returns (uint8 code, string memory reason) {
        if (blacklistedBots[from] || blacklistedBots[to]){
                return (1, "Blacklisted");
        }

        if (!_isExcludedFromMaxTransaction[from] &&!_isExcludedFromMaxTransaction[to] &&amount > MAX_TX_AMOUNT
        ) {
            return (2, "Max tx exceeded");
        }

        uint256 toBalance = balanceOf(to);
        if (!_isExcludedFromMaxWallet[to] && toBalance + amount > MAX_WALLET_BALANCE
        ){
            return (3, "Max wallet exceeded");
        } 

        if (from != owner() && to != owner()) {
            if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                uint256 last = _lastTransferTimestamp[from];
                if (block.timestamp - last < transferDelayTime){
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

    /**
     * 返回当前买/卖税率（单位：0.01 %）
     * @return buy  买税
     * @return sell 卖税
     */
    function getCurrentTaxRates() external view returns (uint256 buy, uint256 sell) {
        buy  = buyTax;
        sell = sellTax;
    }

/**
 *  计算指定金额的买卖税费及用户实际可收代币数量
 * @param amount 交易数量（wei）
 * @param isBuy  true=买  false=卖
 * @return tax      被征收的税费（wei）
 * @return receive_  用户实际可收到代币（wei）
 */
function calcTax(uint256 amount, bool isBuy) external view returns (uint256 tax, uint256 receive_)
{
    uint256 rate = isBuy ? buyTax : sellTax;
    tax     = amount * rate / TAX_DENOMINATOR;
    receive_ = amount - tax;
}

// To receive ETH from uniswapV2Router when swapping
 receive() external payable {}
}
