pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";
import "../MasterChef.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract MasterChef_4_test is MasterChef(CropsToken(0xda1e412De67a9338c942513ee4297bc40EDeA38D), 0x4234C477e339b0EDc3b954EedF88C01f4C2b2227, uint(1000000000000000000), uint(9264000), uint(9263000)){
    
    
    function beforeAll() public {
        
    }

    function getMultiplierShouldBeThis() public returns (bool) {
        add(uint(10), IERC20(0xda1e412De67a9338c942513ee4297bc40EDeA38D), true);
        return Assert.equal(poolInfo.length, uint(1), "getMultiplier is not correct");
    }
}
