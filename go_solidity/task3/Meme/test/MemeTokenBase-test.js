// 引入测试框架和工具
const { expect } = require("chai"); // 引入Chai断言库用于编写测试断言
const { ethers } = require("hardhat"); // 引入Hardhat的ethers模块，用于与以太坊交互

// 导入Uniswap V2核心合约的ABI和字节码
// 这些JSON文件包含了合约的接口定义和编译后的字节码
const FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json"); // Uniswap V2工厂合约
const RouterJSON = require("@uniswap/v2-periphery/build/UniswapV2Router02.json"); // Uniswap V2路由器合约
const WETH9JSON = require("@uniswap/v2-periphery/build/WETH9.json"); // WETH合约（包装后的以太坊）

// 从JSON文件中解构出ABI和字节码，用于后续部署合约
// ABI(Application Binary Interface)定义了合约的接口，包括函数签名、参数类型和返回值类型
// Bytecode是合约编译后的二进制代码，用于在以太坊上部署
const { abi: FactoryABI, bytecode: FactoryBytecode } = FactoryJSON
const { abi: RouterABI, bytecode: RouterBytecode } = RouterJSON
const { abi: WETHABI, bytecode: WETHBytecode } = WETH9JSON

describe("MemeTokenBase", function () {
  let memeTokenBase; // 测试用的MemeTokenBase合约实例
  let owner; // 合约部署者账户
  let marketingWallet; // 营销钱包地址
  let developmentWallet; // 开发钱包地址
  let router; // Uniswap V2路由器合约实例
  let factory; // Uniswap V2工厂合约实例
  let routerAddress; // Uniswap V2路由器合约地址

  beforeEach(async function () {
    // Get accounts
    [owner, marketingWallet, developmentWallet] = await ethers.getSigners();
    console.log('Deploying contracts with the account:', owner.address)
    
    // 部署WETH合约
    // 1. 创建合约工厂：使用ABI和字节码创建一个可部署的合约工厂
    // 2. 调用deploy()部署合约
    // 3. 等待部署完成（waitForDeployment()）
    const WETHFactory = new ethers.ContractFactory(WETHABI, WETHBytecode, owner);
    const weth = await WETHFactory.deploy();
    await weth.waitForDeployment();
    console.log('WETH deployed to:', await weth.getAddress())

    // 部署Uniswap V2工厂合约
    // 工厂合约的作用是创建交易对
    // 构造函数参数是feeToSetter地址，即可以设置手续费接收者的账户
    const FactoryFactory = new ethers.ContractFactory(FactoryABI, FactoryBytecode, owner);  
    factory = await FactoryFactory.deploy(owner.address);
    await factory.waitForDeployment();
    console.log('UniswapV2Factory deployed to:', await factory.getAddress())  

    // 部署Uniswap V2路由器合约
    // 路由器合约提供了更高级的接口，如添加流动性、交换代币等
    // 构造函数参数是工厂合约地址和WETH合约地址
    const RouterFactory = new ethers.ContractFactory(RouterABI, RouterBytecode, owner);  
    router = await RouterFactory.deploy((await factory.getAddress()), await weth.getAddress());
    await router.waitForDeployment();
    routerAddress = await router.getAddress();
    console.log('UniswapV2Router deployed to:', routerAddress)

   // 初始化MemeTokenBase合约
    // 因为MemeTokenBase是使用OpenZeppelin的Upgradeable合约模式编写的
    // 需要调用initialize函数来初始化合约状态，而不是在构造函数中初始化
    // Deploy the testable MemeTokenBase contract
    const TestableMemeTokenBase = await ethers.getContractFactory("TestableMemeTokenBase");
    memeTokenBase = await TestableMemeTokenBase.deploy();
    await memeTokenBase.initialize(
      routerAddress,
      marketingWallet.address,
      developmentWallet.address
    );
    console.log('MemeTokenBase deployed to:', await memeTokenBase.getAddress()) 
    // Exclude marketing and development wallets from fees for testing
    await memeTokenBase.testSetExcludedFromFees(owner.address, true); 
    await memeTokenBase.testSetExcludedFromFees(marketingWallet.address, true);
    await memeTokenBase.testSetExcludedFromFees(developmentWallet.address, true);
  });

  describe("Constants", function () {
    it("should have correct MAX_SUPPLY", async function () {
      console.log("MAX_SUPPLY:", ethers.formatEther(await memeTokenBase.MAX_SUPPLY()));
      expect(await memeTokenBase.MAX_SUPPLY()).to.equal(ethers.parseEther("1000000000"));
    });
     it("should have correct INITIAL_SUPPLY", async function () {
    const initialSupply = ethers.parseEther("100000000"); // 100 million tokens
    console.log("INITIAL_SUPPLY:", ethers.formatEther(initialSupply));
    expect(await memeTokenBase.INITIAL_SUPPLY()).to.equal(initialSupply);
  });

  it("should have correct MAX_TX_AMOUNT", async function () {
    const maxTxAmount = ethers.parseEther("10000000"); // 10 million tokens
    console.log("MAX_TX_AMOUNT:", ethers.formatEther(maxTxAmount));
    expect(await memeTokenBase.MAX_TX_AMOUNT()).to.equal(maxTxAmount);
  });

  it("should have correct MAX_WALLET_BALANCE", async function () {
    const maxWalletBalance = ethers.parseEther("20000000"); // 20 million tokens
    console.log("MAX_WALLET_BALANCE:", ethers.formatEther(maxWalletBalance));
    expect(await memeTokenBase.MAX_WALLET_BALANCE()).to.equal(maxWalletBalance);
  });
  }); 
  
  describe("Initialization", function () {
     it("should initialize with correct name and symbol", async function () {
      expect(await memeTokenBase.name()).to.equal("MemeToken");
      expect(await memeTokenBase.symbol()).to.equal("MEME");
    });

    it("should set correct owner", async function () {
      expect(await memeTokenBase.owner()).to.equal(owner.address);
    });

    it("should set correct marketing wallet", async function () {
      expect(await memeTokenBase.marketingWallet()).to.equal(marketingWallet.address);
    });

    it("should set correct development wallet", async function () {
      expect(await memeTokenBase.developmentWallet()).to.equal(developmentWallet.address);
    });

    it("should set correct Uniswap router", async function () {
      expect(await memeTokenBase.uniswapV2Router()).to.equal(routerAddress);
    });

    it("should create Uniswap pair correctly", async function () {
      const pairAddress = await memeTokenBase.uniswapV2Pair();
      const expectedPairAddress = await factory.getPair(
        await memeTokenBase.getAddress(),
        await router.WETH()
      );
      expect(pairAddress).to.equal(expectedPairAddress);
    });

    it ("should mint initial supply to owner", async function () {
      const ownerBalance = await memeTokenBase.balanceOf(owner.address);
      console.log("ownerBalance:", ethers.formatEther(ownerBalance));
      expect(ownerBalance).to.equal(ethers.parseEther("100000000")); // 100 million tokens
    });

    it ("should approve max allowance to Uniswap router", async function () {
      const allowance = await memeTokenBase.allowance(
        memeTokenBase.getAddress(),
        routerAddress
      );
      expect(allowance).to.equal(ethers.MaxUint256); // type(uint256).max
    });
  });
 
  describe("Exclusions", function () {
    it("should set excluded from fees correctly", async function () {
      const testAddress = owner.address;
      await memeTokenBase.testSetExcludedFromFees(testAddress, true);
      expect(await memeTokenBase.isExcludedFromFees(testAddress)).to.be.true;
      
      await memeTokenBase.testSetExcludedFromFees(testAddress, false);
      expect(await memeTokenBase.isExcludedFromFees(testAddress)).to.be.false;
    });

    it("should set excluded from max transaction correctly", async function () {
      const testAddress = owner.address;
      await memeTokenBase.testSetExcludedFromMaxTx(testAddress, true);
      expect(await memeTokenBase.isExcludedFromMaxTransaction(testAddress)).to.be.true;
      
      await memeTokenBase.testSetExcludedFromMaxTx(testAddress, false);
      expect(await memeTokenBase.isExcludedFromMaxTransaction(testAddress)).to.be.false;
    });

     it("should set excluded from max wallet correctly", async function () {
      const testAddress = owner.address;
      await memeTokenBase.testSetExcludedFromMaxWallet(testAddress, true);
      expect(await memeTokenBase.isExcludedFromMaxWallet(testAddress)).to.be.true;
      
      await memeTokenBase.testSetExcludedFromMaxWallet(testAddress, false);
      expect(await memeTokenBase.isExcludedFromMaxWallet(testAddress)).to.be.false;
    });
    
  });
});