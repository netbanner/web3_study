// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
pragma abicoder v2;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IPoolManager.sol";
import "./interfaces/IPositionManager.sol";
import "./interfaces/IPool.sol";
import "./libraries/TickMath.sol";
import "./libraries/LiquidityAmounts.sol";
import "./libraries/FullMath.sol";
import "./libraries/FixedPoint128.sol";

contract PositionManager is IPositionManager, ERC721 {

    IPoolManager public poolManager;

    uint256 public nextTokenId;

    mapping(uint256 => PositionInfo) public positionInfos;
    constructor(address _poolManager) ERC721("MetaNodeSwapPosition", "MNSP") {
        poolManager = IPoolManager(_poolManager);
    }

    function getPositionInfo(
        uint256 tokenId
    ) external view override returns (PositionInfo memory) {}

    function getAllPositions()
        external
        view
        override
        returns (PositionInfo[] memory positionInfos)
    {
        positionInfos = new PositionInfo[](nextTokenId-1);
        for (uint256 i = 0; i < nextTokenId-1; i++) {
            positionInfos[i] = positionInfos[i+1];
        }
        return positionInfos;
    }

  function getSender() public view returns (address) {
        return msg.sender;
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    modifier checkDeadline(uint256 deadline) {
        require(_blockTimestamp() <= deadline, "PositionManager: EXPIRED");
        _;
    }

    function mint(
        MintParams memory params
    )
        external
        payable
        override checkDeadline(params.deadline)
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
          // mint 一个 NFT 作为 position 发给 LP
        // NFT 的 tokenId 就是 positionId
        // 通过 MintParams 里面的 token0 和 token1 以及 index 获取对应的 Pool
        // 调用 poolManager 的 getPool 方法获取 Pool 地址
        address _pool = poolManager.getPool(
            params.token0,
            params.token1,
            params.index
        );
        IPool _poolContract = IPool(_pool); 

        uint160 sqrtPriceX96 = _poolContract.sqrtPriceX96();
        uint160 sqrtRatioAX96 = TickMath.getSqrtPriceAtTick(_poolContract.tickLower());
        uint160 sqrtRatioBX96 = TickMath.getSqrtPriceAtTick(_poolContract.tickUpper());

        liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            params.amount0Desired,
            params.amount1Desired
        );

          // data 是 mint 后回调 PositionManager 会额外带的数据
        // 需要 PoistionManger 实现回调，在回调中给 Pool 打钱
        bytes memory data = abi.encode(
            params.token0,
            params.token1,
            params.index,
            msg.sender
        );

        (amount0,amount1) = _poolContract.mint(address(this),liquidity,data);
        _mint(params.recipient,(tokenId = nextTokenId++));
        
           (
            ,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            ,

        ) = _poolContract.getPosition(address(this));

        positionInfos[tokenId] = PositionInfo({
            tokenId: tokenId,
            owner: params.recipient,
            token0: params.token0,
            token1: params.token1,
            index: params.index,
            fee: _poolContract.fee(),
            liquidity: liquidity,
            tickLower: _poolContract.tickLower(),
            tickUpper: _poolContract.tickUpper(),
            token0Amount: 0,
            token1Amount: 0,
            feeGrowthInside0LastX128: feeGrowthInside0LastX128,
            feeGrowthInside1LastX128: feeGrowthInside1LastX128
        });
    }

      modifier isAuthorizedForToken(uint256 tokenId) {
        address owner = ERC721.ownerOf(tokenId);
        require(_isAuthorized(owner, msg.sender, tokenId), "Not approved");
        _;
    }


    function burn(
        uint256 tokenId
    ) external override isAuthorizedForToken(tokenId) returns (uint256 amount0, uint256 amount1) {
         PositionInfo storage  positionInfo = positionInfos[tokenId];
            // 通过 isAuthorizedForToken 检查 positionId 是否有权限
            // 移除流动性，但是 token 还是保留在 pool 中，需要再调用 collect 方法才能取回 token
            // 通过 positionId 获取对应 LP 的流动性
            uint128 _liguidity = positionInfo.liquidity;

            address _pool= poolManager.getPool(
                positionInfo.token0,
                positionInfo.token1,
                positionInfo.index
            );
            IPool pool = IPool(_pool);  
            // 调用 Pool 的 collect 方法移除流动性
            (amount0, amount1) = pool.burn(_liguidity);
                //计算这部分流动性产生的手续费
                (
                ,
                uint256 feeGrowthInside0LastX128,
                uint256 feeGrowthInside1LastX128,
                ,

            ) = pool.getPosition(address(this));

            positionInfo.token0Amount += uint128(amount0)+uint128(FullMath.mulDiv(
                positionInfo.feeGrowthInside0LastX128 - positionInfo.feeGrowthInside0LastX128,
                positionInfo.liquidity,
                FixedPoint128.Q128
            ));
            positionInfo.token1Amount += uint128(amount1)+uint128(FullMath.mulDiv(
                positionInfo.feeGrowthInside1LastX128 - positionInfo.feeGrowthInside1LastX128,
                positionInfo.liquidity,
                FixedPoint128.Q128
            ));

            positionInfo.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
            positionInfo.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
            positionInfo.liquidity = 0;
    }

    // 移除流动性
    function collect(
        uint256 tokenId,
        address recipient
    ) external override returns (uint256 amount0, uint256 amount1) {
       PositionInfo storage  positionInfo = positionInfos[tokenId];
       address _pool = poolManager.getPool(
            positionInfo.token0,
            positionInfo.token1,
            positionInfo.index
        );
        IPool pool = IPool(_pool);
        (amount0, amount1) = pool.collect(
            recipient,
            positionInfo.token0Amount,
            positionInfo.token1Amount
        );
        positionInfo.token0Amount = 0;
        positionInfo.token1Amount = 0;
        // 销毁nft
        if (positionInfo.liquidity == 0) {
            _burn(tokenId);
        }           
    }

    function mintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override {
         // 检查 callback 的合约地址是否是 Pool
        (address token0, address token1, uint32 index, address payer) = abi
            .decode(data, (address, address, uint32, address));
        address _pool = poolManager.getPool(token0, token1, index);
        require(_pool == msg.sender, "Invalid callback caller");
          // 在这里给 Pool 打钱，需要用户先 approve 足够的金额，这里才会成功
        if (amount0 > 0) {
            IERC20(token0).transferFrom(payer, msg.sender, amount0);
        }
        if (amount1 > 0) {
            IERC20(token1).transferFrom(payer, msg.sender, amount1);
        }
    }
}