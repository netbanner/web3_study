// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "../interface/IMetaNodeStack.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
contract MetaNodeStack is IMetaNodeStack, Initializable, UUPSUpgradeable, ReentrancyGuard, AccessControlUpgradeable,PausableUpgradeable {
    using SafeERC20 for IERC20;
    using Address for address;
    using Math for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("admin_role");
    bytes32 public constant UPGRADE_ROLE = keccak256("upgrade_role");
    bytes32 public constant OPERATOR_ROLE = keccak256("operator_role");

    // First block that MetaNodeStake will start from
    uint256 public startBlock;
    // First block that MetaNodeStake will end from
    uint256 public endBlock;
    IERC20 public metaNodeToken;
    uint256 public metaNodePerBlock;
    Pool[] public pools;
    uint256 public  totalPoolWeight;
     // Pause the withdraw function
    bool public withdrawPaused;
    // Pause the claim function
    bool public claimPaused;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    

    event Stake(address indexed user, uint256 indexed pid, uint256 amount);
    event Unstake(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ClaimMetaNode(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event PoolAdded(uint256 indexed pid, address stTokenAddress, uint256 poolWeight, uint256 minDepositAmount, uint256 unstakeLockBlocks);
    event PoolUpdated(uint256 indexed pid, uint256 poolWeight, uint256 minDepositAmount, uint256 unstakeLockBlocks, bool isActive);
    event MetaNodePerBlockUpdated(uint256 metaNodePerBlock);
    event PoolActiveStatusUpdated(uint256 indexed pid, bool isActive);

    function initialize(address _metaNodeTokenAddress,uint256 _startBlock,uint256 _endBlock,uint256 _metaNodePerBlock, address admin) public initializer {
         __AccessControl_init();
        __UUPSUpgradeable_init();

        require(_metaNodeTokenAddress != address(0), "Invalid MetaNode token address");
        require(admin != address(0), "Invalid admin address");
        metaNodeToken = IERC20(_metaNodeTokenAddress);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        _grantRole(UPGRADE_ROLE, admin);
   

        startBlock = _startBlock;
        endBlock = _endBlock;
        metaNodePerBlock = _metaNodePerBlock;
    }

  
    function addPool(address _stTokenAddress,uint256 _poolWeight,uint256 _minDepositAmount,uint256 _unstakeLockedBlocks) external override onlyRole(ADMIN_ROLE)   {
        require(_stTokenAddress != address(0), "Invalid staking token address");
        require(_poolWeight > 0, "Pool weight must be greater than zero");
        Pool memory newPool = Pool({
            stTokenAddress: _stTokenAddress,
            poolWeight: _poolWeight,
            accMetaNodePerST: 0,
            stTokenAmount: 0,
            minDepositAmount: _minDepositAmount,
            lastRewardBlock: block.number,
            accRewardPerShare: 0,
            isStarted: false,
            isActive: true,
            unstakeLockBlocks: _unstakeLockedBlocks
        });
        pools.push(newPool);
        totalPoolWeight += _poolWeight;
        emit PoolAdded(pools.length - 1, _stTokenAddress, _poolWeight, _minDepositAmount, _unstakeLockedBlocks);
    }

  
    function setPause(bool _isPaused) external override onlyRole(ADMIN_ROLE)   {
        if (_isPaused) {
            _pause();
        } else {
            _unpause();
        }       
  }

    function setPollActiveStatus(uint256 _pid,bool _isActive) external override onlyRole(ADMIN_ROLE)   {
        require(_pid < pools.length, "Invalid pool ID");
        pools[_pid].isActive = _isActive;
        emit PoolActiveStatusUpdated(_pid, _isActive);
    }
 
    function setMetaNodePerBlock(uint256 _metaNodePerBlock) external override onlyRole(ADMIN_ROLE)   {
        metaNodePerBlock = _metaNodePerBlock;
        emit MetaNodePerBlockUpdated(_metaNodePerBlock);
    }


    function updatePool(uint256 _pid,uint256 _poolWeight,uint256 _minDepositAmount,uint256 _unstakeLockedBlocks,bool _isActive) external override onlyRole(ADMIN_ROLE)   {
        require(_pid < pools.length, "Invalid pool ID");
        Pool storage pool = pools[_pid];
        totalPoolWeight = totalPoolWeight - pool.poolWeight + _poolWeight;
        pool.poolWeight = _poolWeight;
        pool.minDepositAmount = _minDepositAmount;
        pool.unstakeLockBlocks = _unstakeLockedBlocks;
        pool.isActive = _isActive;
        emit PoolUpdated(_pid, _poolWeight, _minDepositAmount, _unstakeLockedBlocks, _isActive);
    }

    function updatePoolRewards(uint256 _pid) public   {
        require(_pid < pools.length, "Invalid pool ID");
        Pool storage pool = pools[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 stTokenSupply = pool.stTokenAmount;
        if (stTokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = block.number - pool.lastRewardBlock;
        uint256 metaNodeReward = (multiplier * metaNodePerBlock * pool.poolWeight) / totalPoolWeight;
        pool.accMetaNodePerST += (metaNodeReward * 1e12) / stTokenSupply;
        pool.lastRewardBlock = block.number;
}

    function massUpdatePools() public   {
        uint256 length = pools.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePoolRewards(pid);
        }
    }

    function poolLength() external view override returns (uint256) {
        return pools.length;
    }

    function getUserInfo(uint256 _pid,address _user) external view override returns (UserInfo memory) {
        return userInfo[_pid][_user];
    }

    function getPoolInfo(uint256 _pid) external view override returns (Pool memory) {
        require(_pid < pools.length, "Invalid pool ID");
        return pools[_pid];
    }

    function getTotalPoolWeight() external view override returns (uint256) {
        return totalPoolWeight;
    }


 function withdraw(uint256 _pid,uint256 _amount) external override nonReentrant whenNotPaused  {
        require(_pid < pools.length, "Invalid pool ID");
        Pool storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0, "Withdraw amount must be greater than zero");
        uint256 availableAmount = 0;
        uint256 i = 0;
        while (i < user.requests.length) {
            if (block.number >= user.requests[i].unlockBlock) {
                availableAmount += user.requests[i].amount;
                user.requests[i] = user.requests[user.requests.length - 1];
                user.requests.pop();
            } else {
                i++;
            }
        }
        require(availableAmount >= _amount, "Insufficient unlocked amount to withdraw");
        updatePoolRewards(_pid);
        uint256 pending = (user.stAmount * pool.accMetaNodePerST) / 1e12 - user.finishedMetaNode;
        if (pending > 0) {
            user.pendingMetaNode += pending;
            user.finishedMetaNode += pending;
        }
        user.stAmount -= _amount;
        pool.stTokenAmount -= _amount;
        IERC20(pool.stTokenAddress).safeTransfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint256 _pid) external override nonReentrant whenNotPaused  {
        require(_pid < pools.length, "Invalid pool ID");
        Pool storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 stAmount = user.stAmount;
        require(stAmount > 0, "No staked amount to withdraw");
        user.stAmount = 0;
        user.finishedMetaNode = 0;
        user.pendingMetaNode = 0;
        delete user.requests;
        pool.stTokenAmount -= stAmount;
        IERC20(pool.stTokenAddress).safeTransfer(msg.sender, stAmount);
        emit EmergencyWithdraw(msg.sender, _pid, stAmount);
    }

    function pendingMetaNode(uint256 _pid,address _user) external view override returns (uint256) {
        require(_pid < pools.length, "Invalid pool ID");
        Pool storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMetaNodePerST = pool.accMetaNodePerST;
        uint256 stTokenSupply = pool.stTokenAmount;
        if (block.number > pool.lastRewardBlock && stTokenSupply != 0) {
            uint256 multiplier = block.number - pool.lastRewardBlock;
            uint256 metaNodeReward = (multiplier * metaNodePerBlock * pool.poolWeight) / totalPoolWeight;
            accMetaNodePerST += (metaNodeReward * 1e12) / stTokenSupply;
        }
        uint256 pending = (user.stAmount * accMetaNodePerST) / 1e12 - user.finishedMetaNode;
        return user.pendingMetaNode + pending;
    }

    function claimMetaNode(uint256 _pid) external override nonReentrant whenNotPaused  {
        require(_pid < pools.length, "Invalid pool ID");
        Pool storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePoolRewards(_pid);
        uint256 pending = (user.stAmount * pool.accMetaNodePerST) / 1e12 - user.finishedMetaNode;
        if (pending > 0) {
            user.pendingMetaNode += pending;
            user.finishedMetaNode += pending;
        }
        uint256 claimable = user.pendingMetaNode;
        require(claimable > 0, "No MetaNode to claim");
        user.pendingMetaNode = 0;
        
        // 实际转账代币给用户
        metaNodeToken.safeTransfer(msg.sender, claimable);
        
        emit ClaimMetaNode(msg.sender, _pid, claimable);
    }

    function stake(uint256 _pid,uint256 _amount) external override nonReentrant whenNotPaused  {
        require(_pid < pools.length, "Invalid pool ID");
        Pool storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.isActive, "Pool is not active");
        require(_amount >= pool.minDepositAmount, "Amount is less than minimum deposit");
        updatePoolRewards(_pid);
        uint256 pending = (user.stAmount * pool.accMetaNodePerST) / 1e12 - user.finishedMetaNode;
        if (pending > 0) {
            user.pendingMetaNode += pending;
            user.finishedMetaNode += pending;
        }
        user.stAmount += _amount;
        pool.stTokenAmount += _amount;
        IERC20(pool.stTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);
        emit Stake(msg.sender, _pid, _amount);

}

    function unstake(uint256 _pid,uint256 _amount) external override nonReentrant whenNotPaused  {
        require(_pid < pools.length, "Invalid pool ID");
        Pool storage pool = pools[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0, "Unstake amount must be greater than zero");
        require(user.stAmount >= _amount, "Insufficient staked amount to unstake");
        updatePoolRewards(_pid);
        uint256 pending = (user.stAmount * pool.accMetaNodePerST) / 1e12 - user.finishedMetaNode;
        if (pending > 0) {
            user.pendingMetaNode += pending;
            user.finishedMetaNode += pending;
        }
        user.stAmount -= _amount;
        pool.stTokenAmount -= _amount;
        uint256 unlockBlock = block.number + pool.unstakeLockBlocks;
        user.requests.push(UnstakeRequest({
            amount: _amount,
            unlockBlock: unlockBlock
        }));
        emit Unstake(msg.sender, _pid, _amount);
    }

/**
 * 必须实现：只有具备 UPGRADE_ROLE 的地址才能升级实现
 * @param newImplementation adress
 */
function _authorizeUpgrade(address newImplementation)
    internal
    override
    onlyRole(UPGRADE_ROLE)
{}

}