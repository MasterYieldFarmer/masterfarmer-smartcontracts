pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract CropsToken_8_test is CropsToken {
    
    function beforeAll() public {
    }
    
    function changetransBurnrateShouldBeThis() public returns (bool) {
        changetransBurnrate(300);
        return Assert.equal(transBurnrate, uint(300), "changetransBurnrate is not correct");
    }
    
    function checkFailurechangetransBurnrate() public returns (bool) {
        changetransBurnrate(1100);//this function must be failure because value is over maximum.
        return Assert.equal(transBurnrate, uint(300), "changetransBurnrate is not correct");
    }
    
}