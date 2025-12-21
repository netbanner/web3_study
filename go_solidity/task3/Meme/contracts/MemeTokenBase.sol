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

abstract contract MemeTokenBase is
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    UUPSUpgradeable
{
    // Core constants
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 billion tokens with 18 decimals
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10 ** 18; // 100 million tokens with 18 decimals
    uint256 public constant MAX_TX_AMOUNT = 10_000_000 * 10 ** 18; //every tx max 10 million tokens with 18 decimals
    uint256 public constant MAX_WALLET_BALANCE = 20_000_000 * 10 ** 18; //every wallet max 20 million tokens with 18 decimals

    // Core state variables
    address public developmentWallet;
    address public marketingWallet;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    // Exclusion mappings
    mapping(address => bool) internal _isExcludedFromFees;
    mapping(address => bool) internal _isExcludedFromMaxTransaction;
    mapping(address => bool) internal _isExcludedFromMaxWallet;

    // Events
    event LiquidityAdded(uint256 tokenAmount, uint256 ethAmount, uint256 timestamp);

    // Initializer function
    function __MemeTokenBase_init(
        address _routerAddress,
        address marketingWalletAddress,
        address developmentWalletAddress
    ) internal onlyInitializing {
        __ERC20_init("MemeToken", "MEME");
        __Ownable_init(msg.sender);
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();

        // Set core addresses
        developmentWallet = developmentWalletAddress;
        marketingWallet = marketingWalletAddress;
        //设置 uniswap 路由、交易对
        IUniswapV2Router02 _router = IUniswapV2Router02(_routerAddress);
        uniswapV2Router = _router;
        uniswapV2Pair = IUniswapV2Factory(_router.factory()).getPair(
            address(this),
            _router.WETH()
        );
        // Mint initial supply to the deployer
        _mint(msg.sender, INITIAL_SUPPLY);
    
        // Approve the maximum token allowance to the Uniswap V2 Router
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
    }

       // New function to create Uniswap pair - to be called after initialization
    function createUniswapPair() external onlyOwner {
        require(uniswapV2Pair == address(0), "Pair already created");
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this),
            uniswapV2Router.WETH()
        );
    }

    // Helper functions for exclusions
    function _setExcludedFromFees(address _a, bool _b) internal {
        _isExcludedFromFees[_a] = _b;
    }

    function _setExcludedFromMaxTx(address _a, bool _b) internal {
        _isExcludedFromMaxTransaction[_a] = _b;
    }

    function _setExcludedFromMaxWallet(address _a, bool _b) internal {
        _isExcludedFromMaxWallet[_a] = _b;
    }
}
