pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract CropsToken_2_test {
    
    CropsToken cropstoken;
    
    function beforeAll() public {
        cropstoken = new CropsToken();
    }
    
    function totalSupplyShouldBeThis() public returns (bool) {
        return Assert.equal(cropstoken.totalSupply(), uint(40000000000000000000000), "totalSupply is not correct");
    }
}
