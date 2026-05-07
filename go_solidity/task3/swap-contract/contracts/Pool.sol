// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./libraries/TransferHelper.sol";
import "./libraries/TickMath.sol";
import "./libraries/FullMath.sol";
import "./libraries/SqrtPriceMath.sol";
import "./libraries/FixedPoint128.sol";
import "./libraries/LiquidityMath.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IFactory.sol";
import "./libraries/SwapMath.sol";



contract Pool is IPool {
    
    address public override immutable factory;

    address public override immutable tokenA;
    address public override immutable tokenB;

    uint24 public override fee;

    int24 public override tickLower;
    int24 public override tickUpper;

   int24 public override tickCurrent;
   uint128 public override liquidity;
   uint160 public override sqrtPriceX96;
   uint256 public override feeGrowthGlobal0X128;
   uint256 public override feeGrowthGlobal1X128;

    struct Position {
        // 该 Position 拥有的流动性
        uint128 liquidity;
        // 可提取的 token0 数量
        uint128 tokensOwed0;
        // 可提取的 token1 数量
        uint128 tokensOwed1;
        // 上次提取手续费时的 feeGrowthGlobal0X128
        uint256 feeGrowthInside0LastX128;
        // 上次提取手续费是的 feeGrowthGlobal1X128
        uint256 feeGrowthInside1LastX128;
    }

    // 用一个 mapping 来存放所有 Position 的信息
    mapping(address => Position) public positions;

    constructor(){
        (factory, tokenA, tokenB,tickLower, tickUpper, fee) = IFactory(msg.sender).parameters();
    }

    function initialize(uint160 _sqrtPriceX96) external override {

       require(_sqrtPriceX96 ==0, "INITIALIZED");
        tickCurrent = TickMath.getTickAtSqrtPrice(_sqrtPriceX96);
        // sqrtPriceX96 should be within the range of [tickLower, tickUpper)
        require(tickCurrent >= tickLower && tickCurrent <= tickUpper, "TICK_OUT_OF_BOUNDS");
        sqrtPriceX96 = _sqrtPriceX96;
    }


    function getPosition(
        address owner
    )
        external
        view
        override
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0X128,
            uint256 feeGrowthInside1X128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        )
    {
        return (
            positions[owner].liquidity,
            positions[owner].feeGrowthInside0LastX128,
            positions[owner].feeGrowthInside1LastX128,
            positions[owner].tokensOwed0,
            positions[owner].tokensOwed1
        );
    }

    struct ModifyPositionParams {
        // 要修改的 Position 的地址
        address owner;
        // 要修改的 Position 的流动性增量
        int128 liquidityDelta;
    }

    function _modifyPosition(
        ModifyPositionParams memory params
    ) private returns (int256 amount0, int256 amount1) {
        amount0 = SqrtPriceMath.getAmount0Delta(
            sqrtPriceX96,
            TickMath.getSqrtPriceAtTick(tickUpper),
            params.liquidityDelta
        );
        amount1 = SqrtPriceMath.getAmount1Delta(
            TickMath.getSqrtPriceAtTick(tickLower),
            sqrtPriceX96,
            params.liquidityDelta
        );

        Position storage position = positions[params.owner];
    // 提取手续费，计算从上一次提取到当前的手续费
        uint128 tokensOwed0 = uint128(
            FullMath.mulDiv(
                feeGrowthGlobal0X128 - position.feeGrowthInside0LastX128,
                position.liquidity,
                FixedPoint128.Q128
            )
        );
        uint128 token1Owed = uint128(
            FullMath.mulDiv(
                feeGrowthGlobal1X128 - position.feeGrowthInside1LastX128,
                position.liquidity,
                FixedPoint128.Q128
            )
        );
        // 更新提取手续费的记录，同步到当前最新的 feeGrowthGlobal0X128，代表都提取完了
        position.feeGrowthInside0LastX128 = feeGrowthGlobal0X128;
        position.feeGrowthInside1LastX128 = feeGrowthGlobal1X128;
        // 把可以提取的手续费记录到 tokensOwed0 和 tokensOwed1 中
        // LP 可以通过 collect 来最终提取到用户自己账户上
        if (tokensOwed0 > 0 || token1Owed > 0) {
            position.tokensOwed0 += tokensOwed0;
            position.tokensOwed1 += token1Owed;
        }
        // 更新 Position 的流动性
         liquidity = LiquidityMath.addDelta(liquidity, params.liquidityDelta);
         
        position.liquidity = LiquidityMath.addDelta(position.liquidity,params.liquidityDelta);
    }
    // Get the pool's balance of tokenA
    function balance0() private view returns(uint256){
         (bool success, bytes memory data) = tokenA.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success&&data.length>=32);
        return abi.decode(data,(uint256));
    }

    // Get the pool's balance of tokenB
    function balance1() private view returns (uint256) {
        (bool success, bytes memory data) = tokenB.staticcall(
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(this))
        );
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function mint(
        address recipient,
        uint128 amount,
        bytes calldata data
    ) external override returns (uint256 amount0, uint256 amount1) {

       require(amount > 0, "Mint amount must be greater than 0");
        // 基于 amount 计算出当前需要多少 amount0 和 amount1
        (int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                liquidityDelta: int128(amount)
            })
        );
        // 检查计算出的 amount0 和 amount1 是否符合预期
        require(amount0Int >= 0 && amount1Int >= 0, "Invalid liquidity delta");
        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);
        uint256 balance0Before;
        uint256 balance1Before ;
        if(amount0 > 0){
            balance0Before = balance0();
        }
        if(amount1 > 0){
            balance1Before = balance1();
        }
        // mintCallBack 
        IMintCallBack(msg.sender).mintCallBack(amount0, amount1, data);
        // 检查 Pool 中是否有足够的 tokenA 和 tokenB 来满足 mint 操作
       if(amount0 > 0){
            require(balance0() >= balance0Before + amount0, "Insufficient tokenA balance");
        }
        if(amount1 > 0){
            require(balance1() >= balance1Before + amount1, "Insufficient tokenB balance");
        }
        
    }

    function collect(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override returns (uint128 amount0, uint128 amount1) {
        Position storage position = positions[msg.sender];
        // 把钱退还给用户 recipient
        amount0 = amount0Requested>position.tokensOwed0?position.tokensOwed0:amount0Requested;
        amount1 = amount1Requested>position.tokensOwed1?position.tokensOwed1:amount1Requested;
        // 从用户账户中提取 amount0 和 amount1
        if(amount0>0){
          position.tokensOwed0 -= amount0;
          TransferHelper.safeTransfer(tokenA, recipient, amount0);
        }
        if(amount1>0){
            position.tokensOwed1 -= amount1;
            TransferHelper.safeTransfer(tokenB, recipient, amount1);
        }
        emit Collect(msg.sender, recipient, amount0, amount1);  
    }

    struct SwapState{
           // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the global fee growth of the input token
        uint256 feeGrowthGlobalX128;
        // 该交易中用户转入的 token0 的数量
        uint256 amountIn;
        // 该交易中用户转出的 token1 的数量
        uint256 amountOut;
        // 该交易中的手续费，如果 zeroForOne 是 ture，则是用户转入 token0，单位是 token0 的数量，反正是 token1 的数量
        uint256 feeAmount;
    }

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        require(amountSpecified !=0, "Swap amount must be greater than 0");
        // zeroForOne: 如果从 token0 交换 token1 则为 true，从 token1 交换 token0 则为 false
        // 判断当前价格是否满足交易的条件
        require(zeroForOne?sqrtPriceLimitX96<=sqrtPriceX96&&sqrtPriceLimitX96>TickMath.MIN_SQRT_PRICE:sqrtPriceLimitX96>sqrtPriceX96&&sqrtPriceLimitX96<TickMath.MAX_SQRT_PRICE, "Price limit not met");

        // amountSpecified 大于 0 代表用户指定了 token0 的数量，小于 0 代表用户指定了 token1 的数量
        bool exactInput = amountSpecified > 0;

        SwapState memory swapState = SwapState({
            amountSpecifiedRemaining: amountSpecified,
            amountCalculated: 0,
            sqrtPriceX96: sqrtPriceX96,
            feeGrowthGlobalX128: zeroForOne?feeGrowthGlobal0X128:feeGrowthGlobal1X128,
            amountIn: 0,
            amountOut: 0,
            feeAmount: 0
        });

         // 计算交易的上下限，基于 tick 计算价格
        uint160 sqrtPriceX96Lower = TickMath.getSqrtPriceAtTick(tickLower);
        uint160 sqrtPriceX96Upper = TickMath.getSqrtPriceAtTick(tickUpper);
         // 计算用户交易价格的限制，如果是 zeroForOne 是 true，说明用户会换入 token0，会压低 token0 的价格（也就是池子的价格），所以要限制最低价格不能超过 sqrtPriceX96Lower
        uint160 sqrtPriceX96PoolLimit = zeroForOne
            ? sqrtPriceX96Lower
            : sqrtPriceX96Upper;

        (swapState.sqrtPriceX96, swapState.amountIn,swapState.amountOut,swapState.feeAmount) = SwapMath.computeSwapStep(
            swapState.sqrtPriceX96,
           (zeroForOne? sqrtPriceX96PoolLimit < sqrtPriceLimitX96: sqrtPriceX96PoolLimit > sqrtPriceLimitX96)? sqrtPriceLimitX96: sqrtPriceX96PoolLimit,
            liquidity,
            amountSpecified,
            fee
        );
        sqrtPriceX96 = swapState.sqrtPriceX96;
        tickCurrent = TickMath.getTickAtSqrtPrice(swapState.sqrtPriceX96);
        swapState.feeGrowthGlobalX128 += FullMath.mulDiv(
                    swapState.feeAmount,
                    FixedPoint128.Q128,
                    liquidity
                );

        // 更新全局手续费
        if(zeroForOne){
            feeGrowthGlobal0X128 = swapState.feeGrowthGlobalX128;
        }else{
            feeGrowthGlobal1X128 = swapState.feeGrowthGlobalX128;
        }

         // 计算交易后用户手里的 token0 和 token1 的数量
        if (exactInput) {
            swapState.amountSpecifiedRemaining -= int256(swapState.amountIn + swapState.feeAmount);
            swapState.amountCalculated = swapState.amountCalculated - int256(swapState.amountOut);
        } else {
            swapState.amountSpecifiedRemaining += int256(swapState.amountOut);
            swapState.amountCalculated = swapState.amountCalculated + int256(swapState.amountIn + swapState.feeAmount);
        }

       (amount0, amount1) = zeroForOne == exactInput
            ? (
                amountSpecified - swapState.amountSpecifiedRemaining,
                swapState.amountCalculated
            )
            : (
                swapState.amountCalculated,
                amountSpecified - swapState.amountSpecifiedRemaining
            );

            if(zeroForOne){
                // callback 中需要给 Pool 转入 token
                uint256 balance0Before = balance0();
                ISwapCallBack(msg.sender).swapCallBack(amount0, amount1, data);
                require(balance0Before+uint256(amount0) <= balance0(), "IIA");
                 // 转 Token 给用户
                if(amount1<0){
                    TransferHelper.safeTransfer(tokenB, recipient, uint256(-amount1));
                }
            }else{
               // callback 中需要给 Pool 转入 token
            uint256 balance1Before = balance1();
            ISwapCallBack(msg.sender).swapCallBack(amount0, amount1, data);
            require(balance1Before+uint256(amount1) <= balance1(), "IIA");
            // 转 Token 给用户
                if(amount0<0){
                    TransferHelper.safeTransfer(tokenA, recipient, uint256(-amount0));
                }
            }

            emit Swap(msg.sender,recipient, amount0, amount1, sqrtPriceX96, liquidity, tickCurrent);   
    }

    function burn(
        address recipient,
        uint128 amount
    ) external override returns (uint256 amount0, uint256 amount1) {
        require(amount > 0, "Burn amount must be greater than 0");
        require(amount <= positions[msg.sender].liquidity, "Burn amount exceeds liquidity");
        // 基于 amount 计算出当前需要多少 amount0 和 amount1
        (int256 amount0Int, int256 amount1Int) = _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                liquidityDelta: -int128(amount)
            })
        );
        // 检查计算出的 amount0 和 amount1 是否符合预期
        require(amount0Int <= 0 && amount1Int <= 0, "Invalid liquidity delta");
        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);
        if(amount0>0||amount1>0){
            (positions[msg.sender].tokensOwed0,positions[msg.sender].tokensOwed1) = (positions[msg.sender].tokensOwed0+uint128(amount0),positions[msg.sender].tokensOwed1+uint128(amount1));
        }
        emit Burn(msg.sender, amount, amount0, amount1);
    }
}