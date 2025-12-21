const { expect } = require("chai");
const { ethers } = require("hardhat");
const FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const RouterJSON = require("@uniswap/v2-periphery/build/UniswapV2Router02.json");
const WETH9JSON = require("@uniswap/v2-periphery/build/WETH9.json");

// 解构ABI和字节码
const { abi: FactoryABI, bytecode: FactoryBytecode } = FactoryJSON;
const { abi: RouterABI, bytecode: RouterBytecode } = RouterJSON;
const { abi: WETHABI, bytecode: WETHBytecode } = WETH9JSON;

describe("MemeTokenTax", function () {
  let memeTokenTax;
  let owner;
  let router;
  let factory;
  let routerAddress; 

  beforeEach(async function () {

     // 获取测试账户
    [owner, taxManager, blacklistManager, pauser, upgrader] = await ethers.getSigners();
    
    // 部署WETH合约
    const WETHFactory = new ethers.ContractFactory(WETHABI, WETHBytecode, owner);
    const weth = await WETHFactory.deploy();
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

    const MemeTokenTax = await ethers.getContractFactory("MemeTokenTax");
    memeTokenTax = await MemeTokenTax.deploy();
    await memeTokenTax.waitForDeployment();
    console.log('MemeTokenTax deployed to:', await memeTokenTax.getAddress());
    // 初始化MemeTokenTax合约
 // 更新初始化调用，传递正确的参数
    await memeTokenTax.initializeTax(
        routerAddress,    // 实际的router地址
        owner.address,    // marketing wallet
        owner.address     // development wallet
    );
    await memeTokenTax.createUniswapPair();
    // 设置实际的钱包地址
    await memeTokenTax.setMarketingWallet(owner.address);
    await memeTokenTax.setDevelopmentWallet(owner.address);
      expect(await memeTokenTax.buyTax()).to.equal(300);
      expect(await memeTokenTax.sellTax()).to.equal(500);
    });

    describe("setTaxRates", function () {  
        it("should allow tax manager to set tax rates within limits", async function () {
            // 将税务经理角色授予owner账户
            await memeTokenTax.grantRole(await memeTokenTax.TAX_MANAGER_ROLE(), owner.address);
            // 设置新的买卖税率
            await memeTokenTax.connect(owner).setTaxRates(400, 600); // 4% buy tax, 6% sell tax
            expect(await memeTokenTax.buyTax()).to.equal(400);
            expect(await memeTokenTax.sellTax()).to.equal(600);
        });

        it("should revert if tax rates exceed maximum limits", async function () {
            // 将税务经理角色授予owner账户
            await memeTokenTax.grantRole(await memeTokenTax.TAX_MANAGER_ROLE(), owner.address);
            // 尝试设置超过最大限制的税率，应该会失败
            await expect(
                memeTokenTax.connect(owner).setTaxRates(1500, 600) // 10% buy tax exceeds max limit
            ).  to.be.revertedWith("MemeToken: Buy tax cannot exceed 10%");

            await expect(
                memeTokenTax.connect(owner).setTaxRates(400, 2000) // 10% sell tax exceeds max limit
            ).to.be.revertedWith("MemeToken: Sell tax cannot exceed 10%");
        }); 
    });

    describe("Address Exclusion from Fees", function () {
        it("should allow owner to exclude and include addresses from fees", async function () {
            // 初始状态下，owner地址不应被排除在费用之外
            expect(await memeTokenTax.isExcludedFromFees(owner.address)).to.be.false;   
        });

        it("should allow only owner to set exclusion from fees", async function () {
            // 尝试使用非owner账户设置排除费用，应该会失败
            await expect(
                memeTokenTax.connect(taxManager).excludeFromFees(owner.address, true)
            ).to.be.revertedWithCustomError(memeTokenTax, "OwnableUnauthorizedAccount");   
        });

        it("should correctly exclude and include addresses from fees", async function () {
            // 使用owner账户将地址排除在费用之外
            await memeTokenTax.excludeFromFees(taxManager.address, true);
            expect(await memeTokenTax.isExcludedFromFees(taxManager.address)).to.be.true;   

            // 使用owner账户将地址重新包含在费用中
            await memeTokenTax.excludeFromFees(taxManager.address, false);
            expect(await memeTokenTax.isExcludedFromFees(taxManager.address)).to.be.false;   
        });
    });

    describe(" marketing and development wallets", function () {
        it("should set correct marketing and development wallets", async function () {
            const marketingWallet = ethers.Wallet.createRandom().address;
            const developmentWallet = ethers.Wallet.createRandom().address;
            
            await memeTokenTax.setMarketingWallet(marketingWallet);
            await memeTokenTax.setDevelopmentWallet(developmentWallet); 
            expect(await memeTokenTax.marketingWallet()).to.equal(marketingWallet);
            expect(await memeTokenTax.developmentWallet()).to.equal(developmentWallet);
        }   );
    });
});