pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";
import "../MasterChef.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract MasterChef_5_test is MasterChef(CropsToken(0xda1e412De67a9338c942513ee4297bc40EDeA38D), 0x4234C477e339b0EDc3b954EedF88C01f4C2b2227, uint(1000000000000000000), uint(9264000), uint(9263000)){
    
    
    function beforeAll() public {
        add(uint(10), IERC20(0x1190aEB8431e122eeAE6106c0DF6182657404BD0), true);
    }

    function setPoolShouldBeThis() public returns (bool) {
        set(uint(0), uint(15), true);
        return Assert.equal(poolInfo[0].allocPoint, uint(15), "setPool is not correct");
    }
}
