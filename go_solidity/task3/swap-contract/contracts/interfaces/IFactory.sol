// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;


interface IFactory {

    struct Parameters {
        address factory;
        address tokenA;
        address tokenB;
        int24 tickLower;
        int24 tickUpper;
        uint24 fee;
    }
    
    function createPool(address tokenA, address tokenB,int24 tickLower,int24 tickUpper,uint24 fee) external returns (address pool);

    function getPool(address tokenA, address tokenB,uint32 index) external view returns (address pool);

    function parameters() external view returns (address factory,address tokenA,address tokenB,int24 tickLower,int24 tickUpper,uint24 fee);

    event PoolCreated(address indexed tokenA,address indexed tokenB,uint32 index,int24 tickLower,int24 tickUpper,uint24 fee,address pool);   
    
}