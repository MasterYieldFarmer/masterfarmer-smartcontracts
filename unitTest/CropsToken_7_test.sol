pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract CropsToken_7_test is CropsToken {
    
   address acc0;
   address acc1;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0);
        acc1 = TestsAccounts.getAccount(1);
    }
    
    function increaseAllowanceShouldBeThis() public returns (bool) {
        approve(acc1, 10000000000000000000000);
        increaseAllowance(acc1, 5000000000000000000000);
        return Assert.equal(allowance(acc0, acc1), uint(15000000000000000000000), "increaseAllowance is not correct");
    }
    
    function decreaseAllowanceShouldBeThis() public returns (bool) {
        approve(acc1, 10000000000000000000000);
        decreaseAllowance(acc1, 5000000000000000000000);
        return Assert.equal(allowance(acc0, acc1), uint(5000000000000000000000), "decreaseAllowance is not correct");
    }
}