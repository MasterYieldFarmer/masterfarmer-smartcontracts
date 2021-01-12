pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";
import "../MasterChef.sol";
import "../Sender.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract MasterChef_8_test is MasterChef(CropsToken(0xda1e412De67a9338c942513ee4297bc40EDeA38D), 0x4234C477e339b0EDc3b954EedF88C01f4C2b2227, uint(1000000000000000000), uint(9264000), uint(9263000)){
    
    address acc0;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        add(uint(10), IERC20(0x1190aEB8431e122eeAE6106c0DF6182657404BD0), true);
    }
    
    function pendingCropsShouldBeThis() public returns (bool) {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][acc0];
        uint256 accCropsPerShare = pool.accCropsPerShare;
        uint256 lpSupply = 1000000000000000000;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 cropsReward = multiplier.mul(cropsPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCropsPerShare = accCropsPerShare.add(cropsReward.mul(1e12).div(lpSupply));
        }
        return Assert.equal(user.amount.mul(accCropsPerShare).div(1e12).sub(user.rewardDebt), uint(0), "deposit is not correct");
    }
}
