const { expect } = require("chai");
const { ethers } = require("hardhat");
const { ignition } = require("hardhat");
const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

// 1. 在测试文件里重新声明模块（或 import 已有文件）
const MyTokenModule = buildModule("MyToken", (m) => {
  const name   = m.getParameter("name", "LocalToken");
  const symbol = m.getParameter("symbol", "LOC");
  const initial = m.getParameter("initialSupply", ethers.parseEther("1000"));

  const token = m.contract("MyToken", [name, symbol, initial]);
  return { token };
});

describe("MyToken (Ignition)", function () {
  let token;
  let deployer, user;

  before(async () => {
    // 2. 部署 BuilderModule 实例
    const deployment = await ignition.deploy(MyTokenModule, {
      parameters: {
        name: "LocalToken",
        symbol: "LOC",
        initialSupply: ethers.parseEther("1000"),
      },
    });
    token = deployment.token;
    [deployer, user] = await ethers.getSigners();
  });

  it("初始供应量正确", async () => {
    const supply = await token.totalSupply();
    expect(supply).to.equal(ethers.parseEther("1000"));
  });

  it("transfer 成功", async () => {
    await token.transfer(user.address, ethers.parseEther("100"));
    const balUser = await token.balanceOf(user.address);
    expect(balUser).to.equal(ethers.parseEther("100"));
  });

  it("approve + transferFrom 成功", async () => {
    await token.approve(user.address, ethers.parseEther("50"));
    await token.connect(user).transferFrom(deployer.address, user.address, ethers.parseEther("50"));
    const balUser = await token.balanceOf(user.address);
    expect(balUser).to.equal(ethers.parseEther("150"));
  });

  it("mint 仅 owner", async () => {
    await token.mint(user.address, ethers.parseEther("200"));
    const bal = await token.balanceOf(user.address);
    expect(bal).to.equal(ethers.parseEther("350"));
    await expect(token.connect(user).mint(user.address, 1))
      .to.be.revertedWithCustomError(token, "OwnableUnauthorizedAccount")
  .withArgs(user.address);
  });
});