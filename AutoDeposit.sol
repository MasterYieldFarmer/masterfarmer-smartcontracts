pragma solidity ^0.6.12;

import './libraries/IUniswapV2Router02.sol';
import './libraries/UniStakingInterfaces.sol';
import './libraries/IUniswapV2Pair.sol';
import './MasterChef.sol';

contract AutoDeposit {
    using SafeERC20 for IERC20;
    
    // The CROPS TOKEN!
    CropsToken public crops;
    // The WETH Token
    IERC20 internal weth;
    // The Uniswap v2 Router
    IUniswapV2Router02 internal uniswapRouter;// 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    // MasterChef contract
    MasterChef internal masterchef;
    event CropsBuyback(address indexed user, uint256 ethSpentOnCROPS, uint256 cropsBought);
    
    constructor(MasterChef _masterchef, CropsToken _crops, IUniswapV2Router02 _uniswapRouter) public {
        masterchef = _masterchef;
        uniswapRouter = _uniswapRouter;
        crops = _crops;
        weth = IERC20(uniswapRouter.WETH());
    }

    receive() external payable {}
    
    // Internal function that buys back CROPS with the amount of ETH specified
    //function _buyCrops(uint256 _amount) internal returns (uint256 cropsBought) {
    function buyCrops() external payable {
        require(msg.value > 0);
        
        uint256 cropsBought = 0;
        uint256 deadline = block.timestamp + 5 minutes;
        address[] memory cropsPath = new address[](2);
        cropsPath[0] = address(weth);
        cropsPath[1] = address(crops);
        uint256[] memory amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(0, cropsPath, msg.sender, deadline);
        cropsBought = amounts[1];
        
        if (cropsBought > 0) emit CropsBuyback(msg.sender, msg.value, cropsBought);
    }
    
    //
    function _addLP(IERC20 _token, IERC20 _pool, uint256 _tokens, uint256 _eth) internal returns (uint256 liquidityAdded) {
        require(_tokens > 0 && _eth > 0);

        IUniswapV2Pair _pair = IUniswapV2Pair(address(_pool));
        (uint256 _reserve0, uint256 _reserve1, ) = _pair.getReserves();
        bool _isToken0 = _pair.token0() == address(_token);
        uint256 _tokensPerETH = 1e18 * (_isToken0 ? _reserve0 : _reserve1) / (_isToken0 ? _reserve1 : _reserve0);
        
        
        _token.safeApprove(address(uniswapRouter), 0);
        if (_tokensPerETH > 1e18 * _tokens / _eth) {
            uint256 _ethValue = 1e18 * _tokens / _tokensPerETH;
            _token.safeApprove(address(uniswapRouter), _tokens);
            ( , , liquidityAdded) = uniswapRouter.addLiquidityETH{value: _ethValue}(address(_token), _tokens, 0, 0, address(this), block.timestamp + 5 minutes);
        } else {
            uint256 _tokenValue = 1e18 * _tokensPerETH / _eth;
            _token.safeApprove(address(uniswapRouter), _tokenValue);
            ( , , liquidityAdded) = uniswapRouter.addLiquidityETH{value: _eth}(address(_token), _tokenValue, 0, 0, address(this), block.timestamp + 5 minutes);
        }
        
        uint256 _remainingETH = address(this).balance;
        uint256 _remainingTokens = _token.balanceOf(address(this));
        if (_remainingETH > 0) {
            msg.sender.transfer(_remainingETH);
        }
        if (_remainingTokens > 0) {
            _token.transfer(msg.sender, _remainingTokens);
        }
        
    }
    
    //
    function _convertToLP(IERC20 _token, IERC20 _pool, uint256 _amount) internal returns (uint256) {
        require(_amount > 0);

        address[] memory _poolPath = new address[](2);
        _poolPath[0] =  address(weth);
        _poolPath[1] = address(_token);
        uniswapRouter.swapExactETHForTokens{value: _amount / 2}(0, _poolPath, address(this), block.timestamp + 5 minutes);

        return _addLP(_token, _pool, _token.balanceOf(address(this)), address(this).balance);
    }
    
    
    //
    function depositInto() external payable {
        require(msg.value > 0);
        
        IERC20 _pool = masterchef.getPoolsLP(0);
        
        uint256 lpReceived = _convertToLP(crops, _pool, msg.value);
        _pool.safeApprove(address(this), 0);
        _pool.safeApprove(address(this), lpReceived);
        _pool.transfer(msg.sender, lpReceived);
        masterchef.UsingETHdeposit(msg.sender, lpReceived);
    }
}