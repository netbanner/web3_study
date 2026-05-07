// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPositionManager is IERC721{

    struct PositionInfo {
        uint256 tokenId; // tokenId of the position
        address owner; // owner of the position 
        address token0;
        address token1;
        uint32 index; // index of the position
        uint24 fee;
        uint128 liquidity;  
        int24 tickLower;
        int24 tickUpper;
        uint128 token0Amount; // amount of token0 in the position
        uint128 token1Amount; // amount of token1 in the position
        uint256 feeGrowthInside0LastX128; // fee growth of token0 inside the position (per unit of liquidity)
        uint256 feeGrowthInside1LastX128; // fee growth of token1 inside the position (per unit of liquidity)
    }

    function getPositionInfo(uint256 tokenId) external view returns (PositionInfo memory);

    function getAllPositions() external view returns (PositionInfo[] memory positionInfos);

    struct MintParams {
        address token0;
        address token1;
        uint32 index; // index of the position
        uint128 amount0Desired;
        uint128 amount1Desired;
        address recipient;
        uint256 deadline;
    }
    // Mint a new position
    function mint(MintParams memory params) external payable returns (uint256 tokenId,uint128 liquidity,uint256 amount0,uint256 amount1);  

    // Burn a position
    function burn(uint256 tokenId) external returns (uint256 amount0,uint256 amount1);
    // Collect fees for a position
    function collect(uint256 tokenId,address recipient) external returns (uint256 amount0,uint256 amount1);
    // Callback function for minting a position
    function mintCallback(uint256 amount0,uint256 amount1, bytes calldata data ) external;
 
}