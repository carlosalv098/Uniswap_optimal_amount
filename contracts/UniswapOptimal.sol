// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IUniswap.sol';

contract UniswapOptimal {

    using SafeMath for uint;

    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < y) {
                z = x;
                x = (y / x + x) / 2;
            }
        }
        else if (y != 0) {
            z = 1;
        }
    }

    /*
    s = optimal swap amount
    r = amount of reserve for token a 
    a = amount of token a the user currently has
    f = swap fee %
    s = (sqrt(((2 - f)r)^2 + 4(1 - f)ar) -(2 - f)r) / (2(1 - f))
    */

    function getSwapAMount(uint r, uint a) public pure returns (uint) {
        return (sqrt(r.mul(r.mul(3988009) + a.mul(3988000))).sub(r.mul(1997))) / 1994;
    }

    function _addLiquidity(address _tokenA, address _tokenB) internal {

        // get balances of tokenA and tokenB in this contract
        uint balance_tokenA = IERC20(_tokenA).balanceOf(address(this));
        uint balance_tokenB = IERC20(_tokenB).balanceOf(address(this));

        // approve ROUTER to spend both balances
        IERC20(_tokenA).approve(ROUTER, balance_tokenA);
        IERC20(_tokenB).approve(ROUTER, balance_tokenB);

        // call addLiquidity function on UniswapV2Router, this add liquidity to an ERC20 - ERC20 pool
        IUniswapV2Router(ROUTER).addLiquidity(
            _tokenA, 
            _tokenB, 
            balance_tokenA, 
            balance_tokenB, 
            0, 
            0, 
            address(this), 
            block.timestamp);
    }

    function _swap(address _from, address _to, uint _amount) internal {
        IERC20(_from).approve(ROUTER, _amount);
        
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;

        IUniswapV2Router(ROUTER).swapExactTokensForTokens(_amount, 1, path, address(this), block.timestamp);
    }

    function swapAndAddLiquidity(address _tokenA, address _tokenB, uint _tokenA_amount) external {

        // etiher tokenA or tokenB has to be USDC
        require(_tokenA == USDC || _tokenB == USDC, 'neither of the tokens is USDC');

        // transfer token A to this contract
        IERC20(_tokenA).transferFrom(msg.sender, address(this), _tokenA_amount);

        // get pair address on uniswap
        address pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);

        // with the address get how much token A and token B is inside the contract
        (uint reserve_0, uint reserve_1,) = IUniswapV2Pair(pair).getReserves();

        // calculate amount to swap of tokenA, token0 => reserve_0 && token1 => reserve_!
        uint swapAmount;

        if (IUniswapV2Pair(pair).token0() == _tokenA) {
            swapAmount = getSwapAMount(reserve_0, _tokenA_amount);
        } else {
            swapAmount = getSwapAMount(reserve_1, _tokenA_amount);
        }
        
        // pass the amount to swap of tokenA with the addresses of tokenA and tokenB, this will send to this contract
        // tokenA and tokenB
        _swap(_tokenA, _tokenB, swapAmount);

        // having tokenA and tokenB in this contract, add liquidity to Uniswap
        _addLiquidity(_tokenA, _tokenB);    
    }    

    function getPair(address _tokenA, address _tokenB) external view returns (address) {
        return IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);
    }
}