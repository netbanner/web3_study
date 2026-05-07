// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPoolManager.sol";
import "./interfaces/ISwapRouter.sol";

contract SwapRouter is ISwapRouter {
    IPoolManager public poolManager;

    constructor(address _poolManager) {
        poolManager = IPoolManager(_poolManager);
    }

    function swapInPool(
        IPool pool,
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1) {
        try   pool.swap(recipient,zeroForOne,amountSpecified,sqrtPriceLimitX96,data)
        returns(int256 _amount0,int256 _amount1){
            return(_amount0,_amount1);
        } catch(bytes memory reason)  {
            return parseRevertReason(reason);
        }
    }

    function parseRevertReason(bytes memory reason) private pure returns(int256,int256){
        if (reason.length != 64) {
            if (reason.length < 68) revert("Unexpected error");
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (int256, int256));
    }

    function swapCallBack(
        int256 amount0,
        int256 amount1,
        bytes calldata data
    ) external override {
        (address tokenIn, address tokenOut, uint32 index, address payer) = abi
            .decode(data, (address, address, uint32, address));
        address _pool = poolManager.getPool(tokenIn, tokenOut, index);

        require(msg.sender == _pool, "SwapRouter: not pool");
        uint256 amountToPay = amount0 > 0 ? uint256(amount0) : uint256(amount1);
        // payer 是 address(0)，这是一个用于预估 token 的请求（quoteExactInput or quoteExactOutput）
        // 参考代码 https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/Quoter.sol#L38
        if (payer == address(0)) {
            assembly {
                let ptr := mload(0x40)
                mstore(ptr, amount0)
                mstore(add(ptr, 0x20), amount1)
                revert(ptr, 64)
            }
        }
        // 只有当 amountToPay 大于 0 时，才需要从 payer 转账到 _pool
        if (amountToPay > 0) {
            IERC20(tokenIn).transferFrom(payer, _pool, amountToPay);
        }
    }

    function exactInput(
        ExactInputParams calldata params
    ) external payable override returns (uint256 amountOut) {
        uint256 amountIn = params.amountIn;
        bool zeroForOne = params.tokenIn<params.tokenOut;

        for(uint256 i=0;i<params.indexPath.length;i++){
            address poolAddress = poolManager.getPool(params.tokenIn,params.tokenOut,params.indexPath[i]);

            require(poolAddress!=address(0),"SwapRouter: pool not found");
            IPool pool = IPool(poolAddress); 
            bytes memory data = abi.encode(params.tokenIn,params.tokenOut,params.indexPath[i],params.recipient==address(0)?msg.sender:address(0));

            (int256 amount0,int256 amount1) = this.swapInPool(pool,params.recipient,zeroForOne,int256(amountIn),params.sqrtPriceLimitX96,data);
            
            amountIn -= uint256(zeroForOne?amount0:amount1);
            amountOut += uint256(zeroForOne?amount1:amount0);
            if(amountIn==0) break;
        }

        require(amountOut>=params.amountOutMinimum,"SwapRouter: amountOut less than minimum");
        emit Swap(msg.sender,zeroForOne,params.amountIn,amountIn,amountOut);
        return amountOut;
    }

    function exactOutput(
        ExactOutputParams calldata params
    ) external payable override returns (uint256 amountIn) {
        uint256 amountOut = params.amountOut;
        bool zeroForOne = params.tokenIn<params.tokenOut;
        for(uint256 i=params.indexPath.length-1;i>=0;i--){
            address poolAddress = poolManager.getPool(params.tokenIn,params.tokenOut,params.indexPath[i]);
            require(poolAddress!=address(0),"SwapRouter: pool not found");
            IPool pool = IPool(poolAddress); 
            bytes memory data = abi.encode(params.tokenIn,params.tokenOut,params.indexPath[i],params.recipient==address(0)?msg.sender:address(0));

            (int256 amount0,int256 amount1) = this.swapInPool(pool,params.recipient,zeroForOne,-int256(amountOut),params.sqrtPriceLimitX96,data);
            
            amountOut -= uint256(zeroForOne?amount1:amount0);
            amountIn += uint256(zeroForOne?amount0:amount1);
            if(amountOut==0) break;
        }
        require(amountIn<=params.amountInMaximum,"SwapRouter: amountIn greater than maximum");
        emit Swap(msg.sender,zeroForOne,params.amountOut,params.amountOut,amountIn);
        return amountIn;
    }

    // 参考代码 https://github.com/Uniswap/v3-periphery/blob/main/contracts/lens/Quoter.sol#L38
    function quoteExactInput(
        QuoteExactInputParams calldata params
    ) external  override returns (uint256 amountOut) {
        return this.exactInput(ExactInputParams({
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            indexPath: params.indexPath,
            recipient: address(0),
            deadline: block.timestamp+1 hours,
            amountIn: params.amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96
        }));
    }

    function quoteExactOutput(
        QuoteExactOutputParams calldata params
    ) external view override returns (uint256 amountIn) {}
}
