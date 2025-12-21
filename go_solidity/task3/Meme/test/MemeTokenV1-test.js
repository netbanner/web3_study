const { expect } = require("chai");
const { ethers } = require("hardhat");
const FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const RouterJSON = require("@uniswap/v2-periphery/build/UniswapV2Router02.json");
const WETH9JSON = require("@uniswap/v2-periphery/build/WETH9.json");

// 解构ABI和字节码
const { abi: FactoryABI, bytecode: FactoryBytecode } = FactoryJSON;
const { abi: RouterABI, bytecode: RouterBytecode } = RouterJSON;
const { abi: WETHABI, bytecode: WETHBytecode } = WETH9JSON;

describe("MemeTokenV1", function () {
  let memeTokenV1;
  let owner;
  let router;
  let factory;
  let weth;
  let marketingWallet;
  let developmentWallet;
  let testWallet;

  beforeEach(async function () {
    [owner, marketingWallet, developmentWallet, testWallet] = await ethers.getSigners();

    // 部署WETH9（先部署WETH，因为Router需要WETH地址）
    const WETHFactory = new ethers.ContractFactory(
      WETHABI,
      WETHBytecode,
      owner
    );
    weth = await WETHFactory.deploy();
    await weth.waitForDeployment();

    // 部署Uniswap Factory（需要feeToSetter参数）
    const FactoryFactory = new ethers.ContractFactory(
      FactoryABI,
      FactoryBytecode,
      owner
    );
    factory = await FactoryFactory.deploy(owner.address); // 传入owner作为feeToSetter
    await factory.waitForDeployment();

    // 部署Uniswap Router（需要factory和weth地址）
    const RouterFactory = new ethers.ContractFactory(
      RouterABI,
      RouterBytecode,
      owner
    );
    router = await RouterFactory.deploy(
      await factory.getAddress(),
      await weth.getAddress()
    );
    await router.waitForDeployment();

    // 部署MemeTokenV1合约
    const MemeTokenV1Factory = await ethers.getContractFactory(
      "MemeTokenV1"
    );
    memeTokenV1 = await MemeTokenV1Factory.deploy();
    await memeTokenV1.waitForDeployment();
    console.log("MemeTokenV1 deployed to:", await memeTokenV1.getAddress());

    // 初始化MemeTokenV1合约（提供完整的3个参数）
    await memeTokenV1.initialize(
      await router.getAddress(),
      marketingWallet.address,
      developmentWallet.address
    );

    // 创建Uniswap对（这是关键修复！）
    await memeTokenV1.createUniswapPair();
  });

  describe("initialize", function () {
    it("should set the router, marketingWallet, and developmentWallet", async function () {
      expect(await memeTokenV1.uniswapV2Router()).to.equal(await router.getAddress());
      expect(await memeTokenV1.marketingWallet()).to.equal(
        marketingWallet.address
      );
      expect(await memeTokenV1.developmentWallet()).to.equal(
        developmentWallet.address
      );
    });
  });

  describe("distribute", function () {
    it("Should apply and distribute taxes on transfers", async function () {
      // 1. 先添加流动性到Uniswap对
      await memeTokenV1.approve(
        await router.getAddress(),
        ethers.parseEther("1000")
      );
      await router.addLiquidityETH(
        await memeTokenV1.getAddress(),
        ethers.parseEther("1000"),
        0,
        0,
        owner.address,
        ethers.MaxUint256,
        { value: ethers.parseEther("1000") }
      );
    
      // 2. 测试钱包从Uniswap对购买代币（而不是直接转账）
      await router.connect(testWallet).swapExactETHForTokensSupportingFeeOnTransferTokens(
        0, // 最小接收代币数量
        [await weth.getAddress(), await memeTokenV1.getAddress()], // 路径
        testWallet.address, // 接收地址
        ethers.MaxUint256, // 截止时间
        { value: ethers.parseEther("100") } // 发送的ETH数量
      );
    
      // 获取测试钱包的实际代币余额
      const testWalletBalance = await memeTokenV1.balanceOf(testWallet.address);
      console.log("测试钱包实际余额:", ethers.formatEther(testWalletBalance));
    
      // 3. 从测试钱包卖出代币到Uniswap对，触发税收
      const initialMarketingBalance = await memeTokenV1.balanceOf(
        marketingWallet.address
      );
      const initialDevelopmentBalance = await memeTokenV1.balanceOf(
        developmentWallet.address
      );
    
      // 设置路由允许 - 使用实际余额
      await memeTokenV1
        .connect(testWallet)
        .approve(await router.getAddress(), testWalletBalance);
    
      // 卖出交易 - 使用实际余额
      await router
        .connect(testWallet)
        .swapExactTokensForETHSupportingFeeOnTransferTokens(
          testWalletBalance,
          0,
          [await memeTokenV1.getAddress(), await weth.getAddress()],
          testWallet.address,
          ethers.MaxUint256
        );
    
      // 检查是否分配了税收
      const finalMarketingBalance = await memeTokenV1.balanceOf(
        marketingWallet.address
      );
      const finalDevelopmentBalance = await memeTokenV1.balanceOf(
        developmentWallet.address
      );
    
      // 验证税收已分配
      expect(finalMarketingBalance).to.be.gt(initialMarketingBalance);
      expect(finalDevelopmentBalance).to.be.gt(initialDevelopmentBalance);
    });

    it("Should swap tokens for ETH", async function () {
      // 1. 先添加流动性到Uniswap对
      await memeTokenV1.approve(
        await router.getAddress(),
        ethers.parseEther("1000000")
      );
      await router.addLiquidityETH(
        await memeTokenV1.getAddress(),
        ethers.parseEther("1000000"),
        0,
        0,
        owner.address,
        ethers.MaxUint256,
        { value: ethers.parseEther("1000") }
      );
  
      // 2. 设置swapTokensAtAmount为较小的值，以便测试
      await memeTokenV1.setSwapTokensAtAmount(ethers.parseEther("100000"));
  
      // 3. 给测试钱包转账一些代币用于卖出
      await memeTokenV1.transfer(
        testWallet.address,
        ethers.parseEther("100000")
      );
  
      // 4. 获取测试钱包的实际代币余额（在转账后获取！）
      const testWalletBalance = await memeTokenV1.balanceOf(testWallet.address);
      console.log("测试钱包实际余额:", ethers.formatEther(testWalletBalance));
  
      // 5. 从测试钱包卖出代币到Uniswap对，触发税收和自动swap
      await memeTokenV1
        .connect(testWallet)
        .approve(await router.getAddress(), testWalletBalance);
  
      // 卖出交易 - 使用实际余额的90%
      await router
        .connect(testWallet)
        .swapExactTokensForETHSupportingFeeOnTransferTokens(
          testWalletBalance * BigInt(9) / BigInt(10), // 卖出90%的余额
          0,
          [await memeTokenV1.getAddress(), await weth.getAddress()],
          testWallet.address,
          ethers.MaxUint256
        );
      
    });
  });

});