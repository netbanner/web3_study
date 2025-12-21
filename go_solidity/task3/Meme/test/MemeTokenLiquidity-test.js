const { expect } = require("chai");
const { ethers } = require("hardhat");
const FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const RouterJSON = require("@uniswap/v2-periphery/build/UniswapV2Router02.json");
const WETH9JSON = require("@uniswap/v2-periphery/build/WETH9.json");

// 解构ABI和字节码
const { abi: FactoryABI, bytecode: FactoryBytecode } = FactoryJSON;
const { abi: RouterABI, bytecode: RouterBytecode } = RouterJSON;
const { abi: WETHABI, bytecode: WETHBytecode } = WETH9JSON

describe("MemeTokenLiquidity", function () {
  let memeTokenLiquidity;
  let owner;
  let router;
  let factory;
  let routerAddress;
  let weth;

    beforeEach(async function () {
 // 获取测试账户
    [owner, taxManager, blacklistManager, pauser, upgrader, marketingWallet, developmentWallet] = await ethers.getSigners();
    
    // 部署WETH合约
    const WETHFactory = new ethers.ContractFactory(WETHABI, WETHBytecode, owner);
    weth = await WETHFactory.deploy();
    await weth.waitForDeployment();

    // 部署Uniswap V2工厂合约
    const FactoryFactory = new ethers.ContractFactory(FactoryABI, FactoryBytecode, owner);  
    factory = await FactoryFactory.deploy(owner.address);
    await factory.waitForDeployment();

    // 部署Uniswap V2路由器合约
    const RouterFactory = new ethers.ContractFactory(RouterABI, RouterBytecode, owner);  
    router = await RouterFactory.deploy((await factory.getAddress()), await weth.getAddress());
    await router.waitForDeployment();
    routerAddress = await router.getAddress();

    const MemeTokenLiquidityFactory = await ethers.getContractFactory("MemeTokenLiquidity");
    memeTokenLiquidity = await MemeTokenLiquidityFactory.deploy();
    await memeTokenLiquidity.waitForDeployment();
    console.log('MemeTokenLiquidity deployed to:', await memeTokenLiquidity.getAddress());
    
    // 更新初始化调用，传入必要的参数
    await memeTokenLiquidity.initializeLiquidity(
        routerAddress,
        marketingWallet.address,
        developmentWallet.address
    );
   });

  describe("setSwapTokensAtAmount", function () {
    it("Should set swap tokens at amount", async function () {
        // 设置足够大的数量（超过最小值100,000 tokens）
        const newAmount = ethers.parseUnits("200000", 18); // 200,000 tokens
        await memeTokenLiquidity.setSwapTokensAtAmount(newAmount);
        
        // 检查值是否正确设置
        expect(await memeTokenLiquidity.getSwapTokensAtAmount()).to.equal(newAmount);
    });
    it("Should revert with insufficient amount", async function () {
        // 尝试设置低于最小值的数量
        const insufficientAmount = ethers.parseUnits("50000", 18); // 50,000 tokens (below minimum)
        
        // 应该调用setSwapTokensAtAmount()而不是getSwapTokensAtAmount()
        await expect(memeTokenLiquidity.setSwapTokensAtAmount(insufficientAmount))
            .to.be.revertedWith("MemeToken: Swap tokens at amount must be at least 100,000 tokens");
    });
});
  
  describe("withdrawTokens", function () {
     it("Should withdraw tokens to owner", async function () {
        // 首先向合约发送一些代币（从所有者账户，而不是合约自己）
        const transferAmount = ethers.parseEther("10");
        
        // 确保所有者拥有代币（检查初始供应量）
        const ownerBalance = await memeTokenLiquidity.balanceOf(owner.address);
        expect(ownerBalance).to.be.greaterThan(transferAmount);
        
        // 从所有者账户向合约转账
        await memeTokenLiquidity.transfer(await memeTokenLiquidity.getAddress(), transferAmount);
        
        // 检查合约是否收到代币
        expect(await memeTokenLiquidity.balanceOf(await memeTokenLiquidity.getAddress())).to.equal(transferAmount);
        
        // 提取部分代币
        const withdrawAmount = ethers.parseEther("1");
        await memeTokenLiquidity.withdrawTokens(withdrawAmount);
        
        // 检查合约剩余代币
        expect(await memeTokenLiquidity.balanceOf(await memeTokenLiquidity.getAddress())).to.equal(transferAmount - withdrawAmount);
    });
});
   

describe("withdrawETH", function () {
    it("Should withdraw ETH", async function () {
        // 先向合约发送一些ETH
        const sendAmount = ethers.parseEther("2");
        await owner.sendTransaction({
            to: await memeTokenLiquidity.getAddress(),
            value: sendAmount
        });
        
        // 检查合约ETH余额
        expect(await ethers.provider.getBalance(await memeTokenLiquidity.getAddress())).to.equal(sendAmount);
        
        // 提取部分ETH
        const withdrawAmount = ethers.parseEther("1");
        const initialOwnerBalance = await ethers.provider.getBalance(owner.address);
        
        const tx = await memeTokenLiquidity.withdrawETH(withdrawAmount);
        const receipt = await tx.wait();
        
        // 检查合约剩余ETH
        expect(await ethers.provider.getBalance(await memeTokenLiquidity.getAddress())).to.equal(sendAmount - withdrawAmount);
        
        // 检查owner收到的ETH
        const finalOwnerBalance = await ethers.provider.getBalance(owner.address);
        
        // 对于BigInt，使用原生比较运算符
        const gasEstimate = ethers.parseEther("0.01"); // 估算的gas成本，足够覆盖交易费用
        const shouldBeAbove = finalOwnerBalance > (initialOwnerBalance + withdrawAmount - gasEstimate);
        const shouldBeBelow = finalOwnerBalance < (initialOwnerBalance + withdrawAmount);
        
        expect(shouldBeAbove).to.be.true;
    });
});
});
 