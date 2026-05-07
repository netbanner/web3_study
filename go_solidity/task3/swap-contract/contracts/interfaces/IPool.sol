// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IPool {
    // 工厂合约地址
    function factory() external view returns (address);
    // 令牌A地址
    function tokenA() external view returns (address);
    // 令牌B地址
    function tokenB() external view returns (address);
    // 手续费率
    function fee() external view returns (uint24);
    // 下边界刻度
    function tickLower() external view returns (int24);
    // 上边界刻度
    function tickUpper() external view returns (int24);

    // 流动性
    function liquidity() external view returns (uint128);
    // 当前价格
    function sqrtPriceX96() external view returns (uint160);
    // 当前刻度
    function tickCurrent() external view returns (int24);

    // 初始化函数
    function initialize(uint160 sqrtPriceX96) external;

    // 全局手续费增长0
    function feeGrowthGlobal0X128() external view returns (uint256);
    // 全局手续费增长1
    function feeGrowthGlobal1X128() external view returns (uint256);


    // 获取位置信息
    function getPosition(address owner) external view returns (uint128 _liquidity, uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128, uint128 tokensOwed0, uint128 tokensOwed1);
    // 铸造函数
    function mint(address recipient,  uint128 amount, bytes calldata data) external returns (uint256 amount0, uint256 amount1);
    // 收集函数
    function collect(address recipient,  uint128 amount0Requested, uint128 amount1Requested) external returns (uint128 amount0, uint128 amount1);
    // 交换函数
    function swap(address recipient, bool zeroForOne, int256 amountSpecified, uint160 sqrtPriceLimitX96, bytes calldata data) external returns (int256 amount0, int256 amount1);
    // 销毁函数
    function burn( uint128 amount) external returns (uint256 amount0, uint256 amount1);

    // event 铸造事件
    event Mint(address indexed sender, address indexed recipient, uint128 amount, uint256 amount0, uint256 amount1);
    // event 收集事件
    event Collect(address indexed owner, address indexed recipient, uint128 amount0, uint128 amount1);
    // event 交换事件
    event Swap(address indexed sender, address indexed recipient, int256 amount0, int256 amount1, uint160 sqrtPriceX96, uint128 liquidity, int24 tick);
    // event 销毁事件
    event Burn(address indexed owner, uint128 amount, uint256 amount0, uint256 amount1);
}

interface IMintCallBack {
    // 铸造回调函数
    function mintCallBack(uint256 amount0, uint256 amount1, bytes calldata data) external; 
}

interface ISwapCallBack {
    // 交换回调函数
    function swapCallBack(int256 amount0, int256 amount1, bytes calldata data) external;
}
