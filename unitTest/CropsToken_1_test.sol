pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract CropsToken_1_test {
    
    CropsToken cropstoken;
    
    function beforeAll() public {
        cropstoken = new CropsToken();
    }
    
    function nameShouldBeThis() public returns (bool) {
        return Assert.equal(cropstoken.name(), "MasterFarmer Token", "name is not correct");
    }
    
    function symbolShouldBeThis() public returns (bool) {
        return Assert.equal(cropstoken.symbol(), "CROPS", "symbol is not correct");
    }
    
    function decimalsShouldBeThis() public returns (bool) {
        return Assert.equal(cropstoken.decimals(), uint(18), "decimals is not correct");
    }
}
