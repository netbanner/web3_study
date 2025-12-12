const { expect } = require("chai");
const { ethers, upgrades,network } = require("hardhat");

describe("MetaNodeStack", function () {
  let metaNodeToken, metaNodeStack, owner, user1, user2;

  const metaNodePerBlock = ethers.parseEther("10");
  const startBlock = "0";
  const endBlock = "10000";
  const initialSupply = ethers.parseEther("1000000");

  beforeEach(async function () {
    [owner, user1, user1] = await ethers.getSigners();
    const mintAmount    = initialSupply * 10n;  
    const metaNodeTokenFactory = await ethers.getContractFactory("MetaNode");
    metaNodeToken = await metaNodeTokenFactory.deploy(
      "MetaNodeToken",
      "MNT",
      mintAmount
    );
    await metaNodeToken.deployed();

    const MetaNodeStack = await ethers.getContractFactory("MetaNodeStack");
    metaNodeStack = await upgrades.deployProxy(MetaNodeStack, [
      metaNodeToken.address,
      startBlock,
      endBlock,
      metaNodePerBlock,
      owner,
    ]);
    await metaNodeStack.deployed();

    await metaNodeToken.transfer(
      metaNodeStack.address,
      ethers.parseEther("1000000")
    );
    await metaNodeToken.transfer(
      user1.address,
      ethers.parseEther("1000")
    );
    await metaNodeToken.transfer(
      user2.address,
      ethers.parseEther("1000")
    );
  });

  describe("Pool Manager", function () {
    // Test case for adding a new pool
    it("Should add a new pool", async function () {
      await metaNodeStack.addPool(metaNodeToken.address,300,1,0);
      const poolInfo = await metaNodeStack.poolInfo(0);
      expect(poolInfo.allocPoint).to.equal(100);
      expect(poolInfo.token).to.equal(metaNodeToken.address);
    });
    // Test case for updating a pool
    it("Should update a pool", async function () {
      await metaNodeStack.addPool(100, metaNodeToken.address, true);
      await metaNodeStack.setPool(0, 200, true);
      const poolInfo = await metaNodeStack.poolInfo(0);
      expect(poolInfo.allocPoint).to.equal(200);
    });
  });

  describe("User Staking", function () {
    beforeEach(async function () {
      await metaNodeStack.addPool(100, metaNodeToken.address, true);
    });

    // Test case for user staking tokens
    it("Should allow user to stake tokens", async function () {
      const stakeAmount = ethers.parseEther("100");
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStack.address, stakeAmount);   
      await metaNodeStack.connect(user1).stake(0, stakeAmount);
      const userInfo = await metaNodeStack.userInfo(0, user1.address);
      expect(userInfo.amount).to.equal(stakeAmount);
    });

    it("Should reject stake below minimum", async function () {
      const stakeAmount = ethers.parseEther("0.5"); // Assuming minimum is 1 token
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStack.address, stakeAmount);
      await expect(
        metaNodeStack.connect(user1).stake(0, stakeAmount)
      ).to.be.revertedWith("Stake amount below minimum");
    });

    it("Should reject stake above maximum", async function () {
      const stakeAmount = ethers.parseEther("2000"); //Assuming maxmum is 1000 token
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStack.address, stakeAmount);
      await expect(
        metaNodeStack.connect(user1).stake(0, stakeAmount)
      ).to.be.revertedWith("Stake amount below minimum");
    });
    it("Should accumulate rewards over time", async function () {
      const depositAmount = ethers.parseEther("100");

      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStack.address, depositAmount);
      await metaNodeStack.connect(user1).stake(0, depositAmount);

      // 前进100个区块
      await network.provider.send("evm_mine", [100]);
    
      const pendingReward = await metaNodeStack.pendingMetaNode(
        0,
        user1.address
      );
      expect(pendingReward).to.be.gt(0);
    });
  });

  describe("Withdrawals", function () {
    beforeEach(async function () {
      await metaNodeStack.addPool(
        metaNodeToken.address,
        100,
        ethers.parseEther("10"),
        100
      );
      const depositAmount = ethers.parseEther("100");
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStack.address, depositAmount);
      await metaNodeStack.connect(user1).stake(0, depositAmount);
    });

    it("Should request withdrawals and lock token", async function () {
      const withdrawAmout = ethers.parseEther("50");
      await metaNodeStack.connect(user1).requestWithdraw(0, withdrawAmout);
      const userInfo = await metaNodeStack.userInfo(0, user1.address);
      expect(userInfo.lockedAmount).to.equal(withdrawAmout);

      const request = await metaNodeStack.getUserRequests(0, user1.address);
      expect(request.length).to.equal(1);
      expect(request[0].amount).to.equal(withdrawAmout);
    });

    it("Should execute withdrawal after lock period", async function () {
      const withdrawAmount = ethers.parseEther("50");

      await metaNodeStack.connect(user1).requestWithdraw(0, withdrawAmount);

      // 前进101个区块（超过锁定期）
      await mineBlocks(101);

      const balanceBefore = await metaNodeToken.balanceOf(user1.address);
      await metaNodeStack.connect(user1).withdrawAmount(0);
      const balanceAfter = await metaNodeToken.balanceOf(user1.address);

      expect(balanceAfter.sub(balanceBefore)).to.equal(withdrawAmount);
    });

    it("Should reject early withdrawal execution", async function () {
      const withdrawAmount = ethers.parseEther("50");
      await metaNodeStack.connect(user1).requestWithdraw(0, withdrawAmount);
      // 只前进50个区块（未达锁定期）
      await mineBlocks(50);
      await expect(
        metaNodeStack.connect(user1).executeWithdraw(0)
      ).to.be.revertedWithCustomError(metaNodeStack, "UnlockTimeNotReached");
    });
  });

  describe("Rewards", async function () {
    beforeEach(async function () {
      await metaNodeStack.addPool(
        metaNodeToken.address,
        100,
        ethers.parseEther("10"),
        100
      );
      const depositAmount = ethers.parseEther("100");
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStack.address, depositAmount);
      await metaNodeStack.connect(user1).stake(0, depositAmount);
    });
    it("Should claim rewards", async function () {
      await mineBlocks(100);
      const pendingReward = await metaNodeStack.pendingMetaNode(
        0,
        user1.address
      );
      const balanceBefore = await metaNodeToken.balanceOf(user1.address);
      await metaNodeStack.connect(user1).claimMetaNode(0);
      const balanceAfter = await metaNodeToken.balanceOf(user1.address);
      expect(balanceAfter.sub(balanceBefore)).to.be.closeTo(
        pendingReward,
        ethers.parseEther("0.1")
      );
    });

    it("Should update user reward tracking correctly", async function () {
      // 前进50个区块
      await mineBlocks(50);

      // 领取部分奖励
      await metaNodeStack.connect(user1).claimMetaNode(0);

      // 再前进50个区块
      await mineBlocks(50);

      const newPendingReward = await metaNodeStack.pendingMetaNode(
        0,
        user1.address
      );
      expect(newPendingReward).to.be.gt(0);
    });
  });

  describe("Emergency Withdraw", function () {
    beforeEach(async function () {
      await metaNodeStack.addPool(
        metaNodeToken.address,
        100,
        ethers.parseEther("10"),
        100
      );

      const depositAmount = ethers.parseEther("100");
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStack.address, depositAmount);
      await metaNodeStack.connect(user1).deposit(0, depositAmount);
    });

    it("Should allow emergency withdrawal", async function () {
      const balanceBefore = await metaNodeToken.balanceOf(user1.address);
      await metaNodeStack.connect(user1).emergencyWithdraw(0);
      const balanceAfter = await metaNodeToken.balanceOf(user1.address);

      expect(balanceAfter.sub(balanceBefore)).to.equal(
        ethers.parseEther("100")
      );
      const user = await metaNodeStack.userInfo(0, user1.address);
      expect(user.stAmount).to.equal(0);
    });
  });

describe("Access Control", function () {
    it("Should restrict admin functions to admin role", async function () {
      await expect(
        metaNodeStack.connect(user1).addPool(metaNodeToken.address, 100, 10, 100)
      ).to.be.reverted;

      await expect(
        metaNodeStack.connect(user1).pause()
      ).to.be.reverted;
    });

    it("Should allow admin to pause operations", async function () {
      await metaNodeStack.setPaused("deposit", true);
      expect(await metaNodeStack.paused("deposit")).to.be.true;
      const depositAmount = ethers.parseEther("50");
      await metaNodeToken.connect(user1).approve(metaNodeStack.address, depositAmount);
      
      await expect(
        metaNodeStack.connect(user1).stake(0, depositAmount)
      ).to.be.reverted();
    });
  });

});
