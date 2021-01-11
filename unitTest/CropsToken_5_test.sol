pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract CropsToken_5_test is CropsToken {
    
   address acc0;
   address acc1;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
    }
    
    function transferShouldBeThis() public returns (bool) {
        transfer(acc1, 10000000000000000000000);
        return Assert.equal(balanceOf(acc1), uint(9750000000000000000000), "transfer is not correct");//consider transBurn 250000000000000000000->2.5%
    }
}
