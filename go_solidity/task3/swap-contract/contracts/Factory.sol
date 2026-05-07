// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "./interfaces/IFactory.sol";
import "./Pool.sol";

contract Factory is IFactory {
  Parameters public override parameters;
   mapping(address => mapping(address => address[])) public pools;
   function sortToken(
        address tokenA,
        address tokenB
    ) private pure returns (address, address) {
        return tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function createPool(
        address tokenA,
        address tokenB,
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external override returns (address pool) {
      require(tokenA!=tokenB, "Tokens must be different");

      address token0;
      address token1;

      (token0, token1) = sortToken(tokenA, tokenB);
      address[] memory poolAddresses = pools[token0][token1];
      // check if pool already exists
      for (uint32 i = 0; i < poolAddresses.length; i++) {
         IPool  currentPool = IPool(poolAddresses[i]);
         if(currentPool.tickLower() == tickLower && currentPool.tickUpper() == tickUpper && currentPool.fee() == fee) {
          return poolAddresses[i];  
        }
      }
      parameters = Parameters({
        factory: address(this),
        tokenA: token0,
        tokenB: token1,
        tickLower: tickLower,
        tickUpper: tickUpper,
        fee: fee
      });
        // generate create2 salt
        bytes32 salt = keccak256(
            abi.encode(token0, token1, tickLower, tickUpper, fee)
        );
      pool = address(new Pool{salt: salt}());
      pools[token0][token1].push(pool);
      delete parameters;

      emit PoolCreated(token0, token1,uint32(poolAddresses.length), tickLower, tickUpper, fee, pool);
    }

    function getPool(
        address tokenA,
        address tokenB,
        uint32 index
    ) external view override returns (address pool) {
      require(tokenA != tokenB, "Tokens must be different");
      require(tokenA!=address(0) && tokenB!=address(0), "Tokens must be non-zero");
     
     address token0;
     address token1;

      (token0, token1) = sortToken(tokenA, tokenB);
      pool = pools[token0][token1][index];
    }

}