const { expect } = require("chai");
const hre = require("hardhat");
const { ethers, network } = hre;

describe("MetaNodeStack", function () {
  let metaNodeToken, metaNodeStack, owner, user1, user2;

  const metaNodePerBlock = hre.ethers.parseEther("10");
  const startBlock = "0";
  const endBlock = "10000";

  beforeEach(async function () {
    [owner, user1, user2] = await hre.ethers.getSigners();
    
    // Deploy MetaNodeToken and wait for deployment
    const metaNodeTokenFactory = await hre.ethers.getContractFactory("MetaNode");
    const metaNodeTokenTx = await metaNodeTokenFactory.deploy("MetaNodeToken", "MNT");
    metaNodeToken = await metaNodeTokenTx.waitForDeployment();

    // Deploy MetaNodeStack and wait for deployment
    const MetaNodeStackFactory = await hre.ethers.getContractFactory("MetaNodeStack");
    const metaNodeStackTx = await MetaNodeStackFactory.deploy();
    metaNodeStack = await metaNodeStackTx.waitForDeployment();
    
    // Get actual contract addresses (needed for initialize)
    const metaNodeTokenAddress = await metaNodeToken.getAddress();
    const metaNodeStackAddress = await metaNodeStack.getAddress();
    
    // Initialize the contract
    await metaNodeStack.initialize(
      metaNodeTokenAddress,
      startBlock,
      endBlock,
      metaNodePerBlock,
      owner.address
    );

    // Check owner's balance (for debugging)
    const ownerBalance = await metaNodeToken.balanceOf(owner.address);
    console.log(`Owner balance: ${hre.ethers.formatEther(ownerBalance)} MNT`);

    // Transfer tokens - adjust amounts to stay within owner's 1,000,000 MNT balance
    await metaNodeToken.transfer(metaNodeStackAddress, hre.ethers.parseEther("998000")); // 998,000 to stack
    await metaNodeToken.transfer(user1.address, hre.ethers.parseEther("1000")); // 1,000 to user1
    await metaNodeToken.transfer(user2.address, hre.ethers.parseEther("1000")); // 1,000 to user2
  });

  describe("Pool Manager", function () {
    it("Should add a new pool", async function () {
      // Use the metaNodeToken address as the staking token (can't use AddressZero)
      const stTokenAddress = await metaNodeToken.getAddress();
      const poolWeight = 100;
      const minDepositAmount = hre.ethers.parseEther("1");
      const unstakeLockBlocks = 100;

      await expect(metaNodeStack.addPool(stTokenAddress, poolWeight, minDepositAmount, unstakeLockBlocks))
        .to.emit(metaNodeStack, "PoolAdded");

      const pool = await metaNodeStack.pools(0);
      expect(pool.stTokenAddress).to.equal(stTokenAddress);
      expect(pool.poolWeight).to.equal(poolWeight);
      expect(pool.minDepositAmount).to.equal(minDepositAmount);
      expect(pool.unstakeLockBlocks).to.equal(unstakeLockBlocks);
      expect(pool.isActive).to.be.true;
    });
  });

  // Line 70 - Fix User Staking beforeEach
  describe("User Staking", function () {
    let metaNodeStackAddress;
    beforeEach(async function () {
      // Use correct addPool signature: (address, uint256, uint256, uint256)
      const stTokenAddress = await metaNodeToken.getAddress();
      console.log("Staking Token Address:", stTokenAddress);
       metaNodeStackAddress = await metaNodeStack.getAddress();
      await metaNodeStack.addPool(stTokenAddress, 100, hre.ethers.parseEther("1"), 100);
    });

    // Test case for user staking tokens
    it("Should allow user to stake tokens", async function () {
      const stakeAmount = ethers.parseEther("100");
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStackAddress, stakeAmount);   
      await metaNodeStack.connect(user1).stake(0, stakeAmount);
      const userInfo = await metaNodeStack.userInfo(0, user1.address);
      expect(userInfo.stAmount).to.equal(stakeAmount);
    });

    it("Should reject stake below minimum", async function () {
      const stakeAmount = ethers.parseEther("0.5"); // Assuming minimum is 1 token
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStackAddress, stakeAmount);
      await expect(
        metaNodeStack.connect(user1).stake(0, stakeAmount)
      ).to.be.revertedWith("Amount is less than minimum deposit");
    });

   it("Should reject stake amount of 0", async function () {
      const stakeAmount = 0;
      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStackAddress, stakeAmount);
      await expect(
        metaNodeStack.connect(user1).stake(0, stakeAmount)
      ).to.be.revertedWith("Amount is less than minimum deposit");
    });
    it("Should accumulate rewards over time", async function () {
      const depositAmount = ethers.parseEther("100");

      await metaNodeToken
        .connect(user1)
        .approve(metaNodeStackAddress, depositAmount);
      await metaNodeStack.connect(user1).stake(0, depositAmount);

      // 前进100个区块
        for (let i = 0; i < 100; i++) {
      await network.provider.send("evm_mine");
    }
    
      const pendingReward = await metaNodeStack.pendingMetaNode(
        0,
        user1.address
      );
      expect(pendingReward).to.be.gt(0);
    });
  });

  // Line 112 - Fix Withdrawals beforeEach  
  describe("Withdrawals", function () {
    let metaNodeStackAddress;
    beforeEach(async function () {
      const stTokenAddress = await metaNodeToken.getAddress();
      await metaNodeStack.addPool(stTokenAddress, 100, ethers.parseEther("10"), 100);
    
      const depositAmount = ethers.parseEther("100");
       metaNodeStackAddress= await metaNodeStack.getAddress();
    
      await metaNodeToken.connect(user1).approve(metaNodeStackAddress, depositAmount);
      await metaNodeStack.connect(user1).stake(0, depositAmount);
    });

    it("Should request withdrawals and lock token", async function () {
      const withdrawAmount = ethers.parseEther("50");
      // 发起 unstake 请求
      await metaNodeStack.connect(user1).unstake(0, withdrawAmount);
     
      const userInfo = await metaNodeStack.getUserInfo(0, user1.address);
      
      // 验证取款请求已创建
      expect(userInfo.requests.length).to.equal(1);
      expect(userInfo.requests[0].amount).to.equal(withdrawAmount);
      // 验证质押金额减少
      expect(userInfo.stAmount).to.equal(ethers.parseEther("50"));
    });

    it("Should execute withdrawal after lock period", async function () {
      const withdrawAmount = ethers.parseEther("50");

      await metaNodeStack.connect(user1).unstake(0, withdrawAmount);

       // 前进101个区块（超过锁定期）
    for (let i = 0; i < 101; i++) {
      await network.provider.send("evm_mine");
    }

      const balanceBefore = await metaNodeToken.balanceOf(user1.address);
      await metaNodeStack.connect(user1).withdraw(0, withdrawAmount);
      const balanceAfter = await metaNodeToken.balanceOf(user1.address);

      expect(balanceAfter-balanceBefore).to.equal(withdrawAmount);
    });

    it("Should reject early withdrawal execution", async function () {
      const withdrawAmount = ethers.parseEther("50");
      await metaNodeStack.connect(user1).unstake(0, withdrawAmount);
     
      // 只前进50个区块（未达锁定期）
      for (let i = 0; i < 50; i++) {
        await network.provider.send("evm_mine");
      }
      await expect(
        metaNodeStack.connect(user1).withdraw(0, withdrawAmount)
      ).to.be.revertedWith("Insufficient unlocked amount to withdraw")
    });
  });

  // Line 148 - Fix Rewards beforeEach
  describe("Rewards", async function () {
    beforeEach(async function () {
      const stTokenAddress = await metaNodeToken.getAddress();
      await metaNodeStack.addPool(stTokenAddress, 100, ethers.parseEther("10"), 100);
    
      const depositAmount = ethers.parseEther("100");
      const metaNodeStackAddress = await metaNodeStack.getAddress();
    
      await metaNodeToken.connect(user1).approve(metaNodeStackAddress, depositAmount);
      await metaNodeStack.connect(user1).stake(0, depositAmount);
    });
    it("Should claim rewards", async function () {
        for (let i = 0; i < 100; i++) {
        await network.provider.send("evm_mine");
      }
      const pendingReward = await metaNodeStack.pendingMetaNode(
        0,
        user1.address
      );
      const balanceBefore = await metaNodeToken.balanceOf(user1.address);
      await metaNodeStack.connect(user1).claimMetaNode(0);
      const balanceAfter = await metaNodeToken.balanceOf(user1.address);
      console.log("pendingReward:",pendingReward);
      console.log("claimedReward:",balanceAfter-balanceBefore);
    });

    it("Should update user reward tracking correctly", async function () {
      // 前进50个区块
    for (let i = 0; i < 50; i++) {
        await network.provider.send("evm_mine");
      }

      // 领取部分奖励
      await metaNodeStack.connect(user1).claimMetaNode(0);

      // 再前进50个区块
      for (let i = 0; i < 50; i++) {
        await network.provider.send("evm_mine");
      }

      const newPendingReward = await metaNodeStack.pendingMetaNode(
        0,
        user1.address
      );
      expect(newPendingReward).to.be.gt(0);
    });
  });

  // Line 176 - Fix Emergency Withdraw beforeEach
  describe("Emergency Withdraw", function () {
    beforeEach(async function () {
      const stTokenAddress = await metaNodeToken.getAddress();
      await metaNodeStack.addPool(stTokenAddress, 100, ethers.parseEther("10"), 100);
  
      const depositAmount = ethers.parseEther("100");
      const metaNodeStackAddress = await metaNodeStack.getAddress();
  
      await metaNodeToken.connect(user1).approve(metaNodeStackAddress, depositAmount);
      await metaNodeStack.connect(user1).stake(0, depositAmount); // Use stake instead of deposit
    });

    it("Should allow emergency withdrawal", async function () {
      const balanceBefore = await metaNodeToken.balanceOf(user1.address);
      await metaNodeStack.connect(user1).emergencyWithdraw(0);
      const balanceAfter = await metaNodeToken.balanceOf(user1.address);

      expect(balanceAfter-balanceBefore).to.equal(
        ethers.parseEther("100")
      );
      const user = await metaNodeStack.userInfo(0, user1.address);
      expect(user.stAmount).to.equal(0);
    });
  });

  // Line 200 - Fix Access Control tests  
  describe("Access Control", function () {
    it("Should restrict admin functions to admin role", async function () {
      const stTokenAddress = await metaNodeToken.getAddress();
      
      await expect(
        metaNodeStack.connect(user1).addPool(stTokenAddress, 100, hre.ethers.parseEther("10"), 100)
      ).to.be.reverted;
  
      await expect(
        metaNodeStack.connect(user1).setPause(true)
      ).to.be.reverted;
    });
  });
});