pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract CropsToken_3_test is CropsToken {
    
   address acc0;
    
    function beforeAll() public {
        acc0 = TestsAccounts.getAccount(0); 
    }
    
    function balanceShouldBeThis() public returns (bool) {
        return Assert.equal(balanceOf(acc0), uint(40000000000000000000000), "balance is not correct");
    }
}
