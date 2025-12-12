// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IMetaNodeStack {


    struct Pool {
        address stTokenAddress; // Staking token address 
        uint256 poolWeight; // Pool weight for reward distribution
        uint256 accMetaNodePerST; //every pool's accumulated MetaNode per staked token  
        uint256 stTokenAmount; // Total staked tokens in the pool   
        uint256 minDepositAmount; // Minimum deposit amount for the pool
        uint256 lastRewardBlock; // Last block number that rewards were distributed
        uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12
        bool isStarted; // if lastRewardBlock has been set
        bool isActive; // Pool active status
        uint256 unstakeLockBlocks; // Number of blocks tokens are locked after unstaking    
    }       

    struct UserInfo {
        uint256 stAmount; // How many staking tokens the user has provided
        uint256 finishedMetaNode; // Finished MetaNode for the user

        uint256 pendingMetaNode; // Pending MetaNode for the user
        UnstakeRequest[] requests; // Array of unstake requests
    }    
    
    struct UnstakeRequest {
        uint256 amount; //amount to withdraw    
        uint256 unlockBlock; // Block number when tokens can be withdrawn
    }

    function addPool(address _stTokenAddress,uint256 _poolWeight,uint256 _minDepositAmount,uint256 _unstakeLockedBlocks) external ;
    function setPause(bool _isPaused) external   ;
    function setPollActiveStatus(uint256 _pid,bool _isActive) external  ;  
    function setMetaNodePerBlock(uint256 _metaNodePerBlock) external   ;
    function updatePool(uint256 _pid,uint256 _poolWeight,uint256 _minDepositAmount,uint256 _unstakeLockedBlocks,bool _isActive) external ;

    function stake(uint256 _pid,uint256 _amount) external ;
    function unstake(uint256 _pid,uint256 _amount) external ;
    function withdraw(uint256 _pid,uint256 _amount) external ;
    function claimMetaNode(uint256 _pid) external ;
    function emergencyWithdraw(uint256 _pid) external ;
    function pendingMetaNode(uint256 _pid,address _user) external view returns (uint256);

    function poolLength() external view returns (uint256);
    function getUserInfo(uint256 _pid,address _user) external view returns (UserInfo memory);

    function getPoolInfo(uint256 _pid) external view returns (Pool memory);

    function getTotalPoolWeight() external view returns (uint256);


}
