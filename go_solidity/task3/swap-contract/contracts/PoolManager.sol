// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
pragma abicoder v2;

import "./interfaces/IPoolManager.sol";
import "./Factory.sol";
import "./interfaces/IPool.sol";
contract PoolManager is Factory,IPoolManager {
    Pair[] public pairs;

    function getPairs() external view override returns (Pair[] memory) {
        return pairs;
    }

    function createAndInitializePoolIfNecessary(
        CreateAndInitializeParams calldata params
    ) external payable override returns (address poolAddress) {
        require(params.token0<params.token1," token0 must be less than token1");
        poolAddress = this.createPool(
            params.token0,
            params.token1,
            params.tickLower,
            params.tickUpper,
            params.fee
        );

        IPool pool = IPool(poolAddress);
        uint256 index = pools[pool.tokenA()][pool.tokenB()].length; 


        // 新创建的池子，没有初始化价格，需要初始化价格
        if (pool.sqrtPriceX96() == 0) {
            pool.initialize(params.sqrtPriceX96);

            if (index == 1) {
                // 如果是第一次添加该交易对，需要记录
                pairs.push(
                    Pair({tokenA: pool.tokenA(), tokenB: pool.tokenB()})
                );
            }
        }
    }

    function getAllPools()
        external
        view
        override
        returns (PoolInfo[] memory poolsInfo)
    {
        uint32 length = 0;
        for(uint32 i=0;i<pairs.length;i++){
            length += uint32(pools[pairs[i].tokenA][pairs[i].tokenB].length);
        }
        poolsInfo = new PoolInfo[](length);
        uint256 index;
        for (uint32 i = 0; i < pairs.length; i++) {
            address[] memory addresses = pools[pairs[i].tokenA][
                pairs[i].tokenB
            ];
            for (uint32 j = 0; j < addresses.length; j++) {
                IPool pool = IPool(addresses[j]);
                poolsInfo[index] = PoolInfo({
                    pool: addresses[j],
                    token0: pool.tokenA(),
                    token1: pool.tokenB(),
                    index: j,
                    fee: pool.fee(),
                    feeProtocol: 0,
                    tickLower: pool.tickLower(),
                    tickUpper: pool.tickUpper(),
                    tickCurrent: pool.tickCurrent(),
                    sqrtPriceX96: pool.sqrtPriceX96(),
                    liquidity: pool.liquidity()
                });
                index++;
            }
        }
    }

    function getPoolInfo(
        address pool
    ) external view override returns (PoolInfo memory) {

        IPool poolContract = IPool(pool);
         uint256 index = pools[poolContract.tokenA()][poolContract.tokenB()].length; 
        return PoolInfo({
            pool: pool,
            token0: poolContract.tokenA(),
            token1: poolContract.tokenB(),
            index: uint32(index),
            fee: poolContract.fee(),
            feeProtocol: 0,
            tickLower: poolContract.tickLower(),
            tickUpper: poolContract.tickUpper(),
            tickCurrent: poolContract.tickCurrent(),
            sqrtPriceX96: poolContract.sqrtPriceX96(),
            liquidity: poolContract.liquidity()
        });
    }
}