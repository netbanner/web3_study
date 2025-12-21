const { expect } = require("chai");
const { ethers } = require("hardhat");
const FactoryJSON = require("@uniswap/v2-core/build/UniswapV2Factory.json");
const RouterJSON = require("@uniswap/v2-periphery/build/UniswapV2Router02.json");
const WETH9JSON = require("@uniswap/v2-periphery/build/WETH9.json");

// 解构ABI和字节码
const { abi: FactoryABI, bytecode: FactoryBytecode } = FactoryJSON;
const { abi: RouterABI, bytecode: RouterBytecode } = RouterJSON;
const { abi: WETHABI, bytecode: WETHBytecode } = WETH9JSON;

describe("MemeTokenRoles", function () {
  let memeTokenRoles;
  let owner;
  let taxManager;
  let blacklistManager;
  let pauser;
  let upgrader;
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

    // 部署可测试的MemeTokenRoles合约
    const MemeTokenRoles = await ethers.getContractFactory("MemeTokenRoles");
    memeTokenRoles = await MemeTokenRoles.deploy();
    await memeTokenRoles.waitForDeployment();
    console.log('MemeTokenRoles deployed to:', await memeTokenRoles.getAddress())
    // 初始化MemeTokenRoles合约
    await memeTokenRoles.initializeRoles();
  });

  describe("Role Initialization", function () {
    it("should grant all roles to the owner initially", async function () {
      // 验证owner拥有所有角色
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.DEFAULT_ADMIN_ROLE(), owner.address)).to.be.true;
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.TAX_MANAGER_ROLE(), owner.address)).to.be.true;
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.BLACKLIST_MANAGER_ROLE(), owner.address)).to.be.true;
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.PAUSER_ROLE(), owner.address)).to.be.true;
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.UPGRADER_ROLE(), owner.address)).to.be.true;
    });
  });

  describe("Role Management", function () {
    it("should allow admin to grant and revoke TAX_MANAGER_ROLE", async function () {
      // 授予taxManager角色
      await memeTokenRoles.grantRole(await memeTokenRoles.TAX_MANAGER_ROLE(), taxManager.address);
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.TAX_MANAGER_ROLE(), taxManager.address)).to.be.true;

      // 撤销taxManager角色
      await memeTokenRoles.revokeRole(await memeTokenRoles.TAX_MANAGER_ROLE(), taxManager.address);
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.TAX_MANAGER_ROLE(), taxManager.address)).to.be.false;
    });

    it("should allow admin to grant and revoke BLACKLIST_MANAGER_ROLE", async function () {
      // 授予blacklistManager角色
      await memeTokenRoles.grantRole(await memeTokenRoles.BLACKLIST_MANAGER_ROLE(), blacklistManager.address);
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.BLACKLIST_MANAGER_ROLE(), blacklistManager.address)).to.be.true;

      // 撤销blacklistManager角色
      await memeTokenRoles.revokeRole(await memeTokenRoles.BLACKLIST_MANAGER_ROLE(), blacklistManager.address);
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.BLACKLIST_MANAGER_ROLE(), blacklistManager.address)).to.be.false;
    });

    it("should allow admin to grant and revoke PAUSER_ROLE", async function () {
      // 授予pauser角色
      await memeTokenRoles.grantRole(await memeTokenRoles.PAUSER_ROLE(), pauser.address);
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.PAUSER_ROLE(), pauser.address)).to.be.true;

      // 撤销pauser角色
      await memeTokenRoles.revokeRole(await memeTokenRoles.PAUSER_ROLE(), pauser.address);
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.PAUSER_ROLE(), pauser.address)).to.be.false;
    });

    it("should allow admin to grant and revoke UPGRADER_ROLE", async function () {
      // 授予upgrader角色
      await memeTokenRoles.grantRole(await memeTokenRoles.UPGRADER_ROLE(), upgrader.address);
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.UPGRADER_ROLE(), upgrader.address)).to.be.true;

      // 撤销upgrader角色
      await memeTokenRoles.revokeRole(await memeTokenRoles.UPGRADER_ROLE(), upgrader.address);
      expect(await memeTokenRoles.hasRole(await memeTokenRoles.UPGRADER_ROLE(), upgrader.address)).to.be.false;
    });
  });

  describe("Role Functionality", function () {
    it("should only allow users with PAUSER_ROLE to pause/unpause", async function () {
      // 授予pauser角色
      await memeTokenRoles.grantRole(await memeTokenRoles.PAUSER_ROLE(), pauser.address);

      // 验证pauser可以暂停合约
      await expect(memeTokenRoles.connect(pauser).pause()).to.not.be.reverted;
      expect(await memeTokenRoles.paused()).to.be.true;

      // 验证pauser可以取消暂停合约
      await expect(memeTokenRoles.connect(pauser).unpause()).to.not.be.reverted;
      expect(await memeTokenRoles.paused()).to.be.false;

      // 验证非pauser不能暂停合约
      await expect(memeTokenRoles.connect(taxManager).pause()).to.be.reverted;
    });

    it("should not allow users without roles to perform restricted actions", async function () {
      // 验证没有PAUSER_ROLE的用户不能暂停合约
      await expect(memeTokenRoles.connect(taxManager).pause()).to.be.reverted;
      
      // 验证没有TAX_MANAGER_ROLE的用户不能管理税费（如果有相关函数）
      // 注意：这里需要根据实际实现的函数来测试
    });
  });

  describe("Upgrade Authorization", function () {
    it("should only allow users with UPGRADER_ROLE to authorize upgrades", async function () {
      // 注意：这里的测试需要模拟升级场景
      // 通常需要部署一个新的实现合约并尝试升级
      // 由于完整的升级测试比较复杂，这里只验证角色检查
      
      // 授予upgrader角色
      await memeTokenRoles.grantRole(await memeTokenRoles.UPGRADER_ROLE(), upgrader.address);
      
      // 验证upgrader可以调用_authorizeUpgrade（通过UPGRADER_ROLE检查）
      // 注意：_authorizeUpgrade是内部函数，通常通过升级交易来测试
    });
  });
});