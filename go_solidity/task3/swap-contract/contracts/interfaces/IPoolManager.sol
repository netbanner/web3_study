// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "./IFactory.sol";

interface IPoolManager is IFactory {

    struct PoolInfo {
        address pool;
        address token0;
        address token1;
        uint32 index;
        uint24 fee;
        uint8 feeProtocol;
        int24 tickLower;
        int24 tickUpper;
        int24 tickCurrent;
        uint128 liquidity;
        uint160 sqrtPriceX96;
    }

    struct Pair{
        address tokenA;
        address tokenB;
    }

    function getPoolInfo(address pool) external view returns (PoolInfo memory);
    function getPairs() external view returns (Pair[] memory);
    function getAllPools() external view returns (PoolInfo[] memory poolsInfo);

    struct CreateAndInitializeParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint160 sqrtPriceX96;
    }

    function createAndInitializePoolIfNecessary(CreateAndInitializeParams memory params) external payable returns (address pool);

}
