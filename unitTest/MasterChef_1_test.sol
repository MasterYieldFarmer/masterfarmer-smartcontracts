pragma solidity >=0.4.22 <0.8.0;
import "remix_tests.sol"; // this import is automatically injected by Remix.
import "remix_accounts.sol";
import "../CropsToken.sol";
import "../MasterChef.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract MasterChef_1_test {
    
    CropsToken cropstoken;
    MasterChef masterchef;
    
    function beforeAll() public {
        masterchef = new MasterChef(cropstoken, 0x4234C477e339b0EDc3b954EedF88C01f4C2b2227, uint(1000000000000000000), uint(9264000), uint(9263000));
    }

    function poolLengthShouldBeThis() public returns (bool) {
        return Assert.equal(masterchef.poolLength(), uint(0), "poolLength is not correct");
    }
}
