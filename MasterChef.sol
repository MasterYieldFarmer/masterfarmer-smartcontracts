pragma solidity ^0.6.12;

import './libraries/SafeERC20.sol';
import './CropsToken.sol';


// MasterChef is the master of Crops. He can make Crops and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once CROPS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CROPSs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCropsPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCropsPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CROPSs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CROPSs distribution occurs.
        uint256 accCropsPerShare; // Accumulated CROPSs per share, times 1e12. See below.
    }

    // The CROPS TOKEN!
    CropsToken public crops;
    // Dev address.
    address public devaddr;
    // Block number when bonus CROPS period ends.
    uint256 public bonusEndBlock;
    // CROPS tokens created per block.
    uint256 public cropsPerBlock;
    // Bonus muliplier for early crops makers.
    uint256 public constant BONUS_MULTIPLIER = 10;
   

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CROPS mining starts.
    uint256 public startBlock;
    
    // initial value of teamMintrate
    uint256 public teamMintrate = 300;// additional 3% of tokens are minted and these are sent to the dev.
    
    // Max value of tokenperblock
    uint256 public constant maxtokenperblock = 10*10**18;// 10 token per block
    // Max value of teamrewards
    uint256 public constant maxteamMintrate = 1000;// 10%
    
    mapping (address => bool) private poolIsAdded;
    
    // Timer variables for globalDecay
    uint256 public timestart = 0;
    
    // Event logs 
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    

    constructor(
        CropsToken _crops,
        address _devaddr,
        uint256 _cropsPerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        crops = _crops;
        devaddr = _devaddr;
        cropsPerBlock = _cropsPerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }
    
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        require(poolIsAdded[address(_lpToken)] == false, 'add: pool already added');
        poolIsAdded[address(_lpToken)] = true;
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCropsPerShare: 0
        }));
    }

    // Update the given pool's CROPS allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

   
    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }

    // View function to see pending CROPSs on frontend.
    function pendingCrops(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCropsPerShare = pool.accCropsPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cropsReward = multiplier.mul(cropsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCropsPerShare = accCropsPerShare.add(cropsReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCropsPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    
    // Get pool LP according _pid
    function getPoolsLP(uint256 _pid) external view returns (IERC20) {
        return poolInfo[_pid].lpToken;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 cropsReward = multiplier.mul(cropsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        crops.mint(devaddr, cropsReward.div(10000).mul(teamMintrate));
        crops.mint(address(this), cropsReward);
        pool.accCropsPerShare = pool.accCropsPerShare.add(cropsReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for CROPS allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCropsPerShare).div(1e12).sub(user.rewardDebt);
            safeCropsTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accCropsPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    // Deposit LP tokens to MasterChef for CROPS allocation using ETH.
    function UsingETHdeposit(address useraccount, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][useraccount];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCropsPerShare).div(1e12).sub(user.rewardDebt);
            safeCropsTransfer(useraccount, pending);
        }
        pool.lpToken.safeTransferFrom(address(useraccount), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accCropsPerShare).div(1e12);
        emit Deposit(useraccount, 0, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCropsPerShare).div(1e12).sub(user.rewardDebt);
        safeCropsTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accCropsPerShare).div(1e12);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe crops transfer function, just in case if rounding error causes pool to not have enough CROPSs.
    function safeCropsTransfer(address _to, uint256 _amount) internal {
        uint256 cropsBal = crops.balanceOf(address(this));
        if (_amount > cropsBal) {
            crops.transfer(_to, cropsBal);
        } else {
            crops.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
    
    // globalDecay function
    function globalDecay() public {
        
        uint256 timeinterval = now.sub(timestart);
        require(timeinterval > 21600, "timelimit-6hours is not finished yet");
        
        uint256 totaltokenamount = crops.totalSupply(); 
        totaltokenamount = totaltokenamount.sub(totaltokenamount.mod(1000));
        uint256 decaytokenvalue = totaltokenamount.div(1000);//1% of 10%decayvalue
        uint256 originaldeservedtoken = crops.balanceOf(address(this));
        
        crops.globalDecay();
        
        uint256 afterdeservedtoken = crops.balanceOf(address(this));
        uint256 differtoken = originaldeservedtoken.sub(afterdeservedtoken);
        crops.mint(msg.sender, decaytokenvalue);
        crops.mint(address(this), differtoken);
        
        timestart = now;
        
    }
    
    //burn tokens
    function burntoken(address account, uint256 amount) public onlyOwner returns (bool) {
        crops.burn(account, amount);
        return true;
    }
    
    
    //change the TPB(tokensPerBlock)
    function changetokensPerBlock(uint256 _newTPB) public onlyOwner {
        require(_newTPB <= maxtokenperblock, "too high value");
        cropsPerBlock = _newTPB;
    }
    
    //change the TBR(transBurnRate)
    function changetransBurnrate(uint256 _newtransBurnrate) public onlyOwner returns (bool) {
        crops.changetransBurnrate(_newtransBurnrate);
        return true;
    }
    
    //change the DBR(decayBurnrate)
    function changedecayBurnrate(uint256 _newdecayBurnrate) public onlyOwner returns (bool) {
        crops.changedecayBurnrate(_newdecayBurnrate);
        return true;
    }
    
    //change the TMR(teamMintRate)
    function changeteamMintrate(uint256 _newTMR) public onlyOwner {
        require(_newTMR <= maxteamMintrate, "too high value");
        teamMintrate = _newTMR;
    }
}