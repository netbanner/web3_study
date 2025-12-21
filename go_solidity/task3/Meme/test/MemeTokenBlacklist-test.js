const { expect } = require("chai");
const { ethers, upgrades } = require("hardhat");
const FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const RouterJSON = require("@uniswap/v2-periphery/build/UniswapV2Router02.json");
const WETH9JSON = require("@uniswap/v2-periphery/build/WETH9.json");

// 解构ABI和字节码
const { abi: FactoryABI, bytecode: FactoryBytecode } = FactoryJSON;
const { abi: RouterABI, bytecode: RouterBytecode } = RouterJSON;
const { abi: WETHABI, bytecode: WETHBytecode } = WETH9JSON;

describe("MemeTokenBlacklist", function () {
  let memeTokenBlacklist;
  let owner;
  let router;
  let factory;

  beforeEach(async function () {
    // 获取测试账户
    [owner] = await ethers.getSigners();
    
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

    const memeTokenBlacklistFactory = await ethers.getContractFactory("MemeTokenBlacklist");
    memeTokenBlacklist = await memeTokenBlacklistFactory.deploy();
    await memeTokenBlacklist.waitForDeployment();
    console.log('MemeTokenBlacklist deployed to:', await memeTokenBlacklist.getAddress());
    // 初始化MemeTokenBlacklist合约
    await memeTokenBlacklist.initializeUniswap(await factory.getAddress(), await router.getAddress());

  });

  describe("Blacklist Functionality", function () {
    it("should allow blacklist manager to add and remove addresses from blacklist", async function () {
      // 初始时地址不在黑名单中
      expect(await memeTokenBlacklist.isBlacklisted(owner.address)).to.be.false;    
        // 将地址添加到黑名单   
        await memeTokenBlacklist.addToBlacklist(owner.address,true); 
        expect(await memeTokenBlacklist.isBlacklisted(owner.address)).to.be.true;   
        // 从黑名单中移除地址       
        await memeTokenBlacklist.addToBlacklist(owner.address,false);
        expect(await memeTokenBlacklist.isBlacklisted(owner.address)).to.be.false;  
    });

    it ("should prevent blacklisted addresses from transferring tokens", async function () {
      // 将地址添加到黑名单
      await memeTokenBlacklist.addToBlacklist(owner.address,true);
      // 尝试从黑名单地址转账，预期失败
      await expect(
        memeTokenBlacklist.transfer("0x0000000000000000000000000000000000000001", ethers.parseUnits("10", 18))
      ).to.be.revertedWithCustomError(memeTokenBlacklist, "ERC20InsufficientBalance"); 
    });

    it("should allow non-blacklisted addresses to transfer tokens", async function () {
      // 确保地址不在黑名单中
      expect(await memeTokenBlacklist.isBlacklisted(owner.address)).to.be.false;
   });


    it("should allow BLACKLIST_MANAGER_ROLE to manage blacklist", async function () {
      const [_, blacklistManager] = await ethers.getSigners();  
        // 将blacklistManager角色授予otherAccount   
        await memeTokenBlacklist.grantRole(await memeTokenBlacklist.BLACKLIST_MANAGER_ROLE(), blacklistManager.address);    
           // 使用blacklistManager账户将地址添加到黑名单
        await memeTokenBlacklist.connect(blacklistManager).addToBlacklist(owner.address,true);
        expect(await memeTokenBlacklist.isBlacklisted(owner.address)).to.be.true;  
    });  
    it("should prevent non-BLACKLIST_MANAGER_ROLE from managing blacklist", async function () {
      const [_, otherAccount] = await ethers.getSigners();  
        // 确保otherAccount没有blacklistManager角色   
        expect(await memeTokenBlacklist.hasRole(await memeTokenBlacklist.BLACKLIST_MANAGER_ROLE(), otherAccount.address)).to.be.false;    
           // 使用otherAccount尝试将地址添加到黑名单，预期失败
        await expect(
          memeTokenBlacklist.connect(otherAccount).addToBlacklist(owner.address,true)
        ).to.be.revertedWithCustomError(memeTokenBlacklist, "AccessControlUnauthorizedAccount"); 
        });
         it("should emit events on blacklist changes", async function () {
      // 监听Blacklisted事件
      await expect(memeTokenBlacklist.addToBlacklist(owner.address,true))
        .to.emit(memeTokenBlacklist, "Blacklisted")
        .withArgs(owner.address,true); 
        // 监听Blacklisted事件（从黑名单移除）
    await expect(memeTokenBlacklist.addToBlacklist(owner.address, false))
        .to.emit(memeTokenBlacklist, "Blacklisted")
        .withArgs(owner.address, false);       
    });
    });
});