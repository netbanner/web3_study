const { expect } = require("chai");
const { ethers } = require("hardhat");
const FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const RouterJSON = require("@uniswap/v2-periphery/build/UniswapV2Router02.json");
const WETH9JSON = require("@uniswap/v2-periphery/build/WETH9.json");

// 解构ABI和字节码
const { abi: FactoryABI, bytecode: FactoryBytecode } = FactoryJSON;
const { abi: RouterABI, bytecode: RouterBytecode } = RouterJSON;
const { abi: WETHABI, bytecode: WETHBytecode } = WETH9JSON;

describe("MemeTokenUniswap", function () {
    let memeTokenUniswap;
    let owner;
    let router;
    let factory;
    let weth;
    let marketingWallet;
    let developmentWallet;


  beforeEach(async function () {
    [owner, marketingWallet, developmentWallet, testWallet] = await ethers.getSigners();

    // 部署WETH9（先部署WETH，因为Router需要WETH地址）
    const WETHFactory = new ethers.ContractFactory(WETHABI, WETHBytecode, owner);
    weth = await WETHFactory.deploy();
    await weth.waitForDeployment();

    // 部署Uniswap Factory（需要feeToSetter参数）
    const FactoryFactory = new ethers.ContractFactory(FactoryABI, FactoryBytecode, owner);
    factory = await FactoryFactory.deploy(owner.address); // 传入owner作为feeToSetter
    await factory.waitForDeployment();

    // 部署Uniswap Router（需要factory和weth地址）
    const RouterFactory = new ethers.ContractFactory(RouterABI, RouterBytecode, owner);
    router = await RouterFactory.deploy(await factory.getAddress(), await weth.getAddress());
    await router.waitForDeployment();

    // 部署MemeTokenUniswap合约
    const MemeTokenUniswapFactory = await ethers.getContractFactory("MemeTokenUniswap");
    memeTokenUniswap = await MemeTokenUniswapFactory.deploy();
    await memeTokenUniswap.waitForDeployment();
    console.log("MemeTokenUniswap deployed to:", await memeTokenUniswap.getAddress());
    
    // 初始化MemeTokenUniswap合约（提供完整的3个参数）
    await memeTokenUniswap.initializeUniswap(
      await router.getAddress(), 
      marketingWallet.address, 
      developmentWallet.address
    );
  });

  describe("add liquidity", function () {
    it("Should add liquidity to Uniswap", async function () {
      // 先 approve 合约 allowance
      await memeTokenUniswap.approve(await router.getAddress(), ethers.parseEther("1000"));

      // 调用 addLiquidity 函数
      await router.addLiquidityETH(
        await memeTokenUniswap.getAddress(),
        ethers.parseEther("1000"),
        0,
        0,
        owner.address,
        ethers.MaxUint256,
        { value: ethers.parseEther("1000") }
      );

      // 检查流动性是否增加
      const pairAddress = await factory.getPair(await memeTokenUniswap.getAddress(), await weth.getAddress());
      const pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress);
      const liquidity = await pair.balanceOf(owner.address);
      expect(liquidity).to.be.gt(0);
    });
  }); 

  describe("remove liquidity", function () {
    it("Should remove liquidity from Uniswap", async function () {
      // 先添加流动性
      await memeTokenUniswap.approve(await router.getAddress(), ethers.parseEther("1000"));
      await router.addLiquidityETH(
        await memeTokenUniswap.getAddress(),
        ethers.parseEther("1000"),
        0,
        0,
        owner.address,
        ethers.MaxUint256,
        { value: ethers.parseEther("1000") }
      );
      
      // 获取流动性代币
      const pairAddress = await factory.getPair(await memeTokenUniswap.getAddress(), await weth.getAddress());
      const pair = await ethers.getContractAt("IUniswapV2Pair", pairAddress);
      const liquidity = await pair.balanceOf(owner.address);
      
      // 批准并移除流动性
      await pair.approve(await router.getAddress(), liquidity);
      await router.removeLiquidityETH(
        await memeTokenUniswap.getAddress(),
        liquidity,
        0,
        0,
        owner.address,
        ethers.MaxUint256
      );
      
      // 检查流动性是否减少
      const liquidityAfter = await pair.balanceOf(owner.address);
      expect(liquidityAfter).to.be.lt(liquidity);
    });
  }); 

  
});