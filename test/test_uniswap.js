const IERC20 = artifacts.require('IERC20')
const UniswapOptimal = artifacts.require('UniswapOptimal');
const BN = require('bn.js');
const { assert } = require('hardhat');

require('dotenv').config();

contract('UniswapOptimal', accounts => {

    const USDC = '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48';
    const DECIMALS = 6;
    const USDC_AMOUNT = new BN(10).pow(new BN(DECIMALS)).mul(new BN(100000));
    const USDC_WHALE = process.env.USDC_WHALE;

    const WETH = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
    
    let uniswapOptimal, tokenA, tokenB, pair

    function sendEther(web3, from, to, amount) {
        return web3.eth.sendTransaction({
          from,
          to,
          value: web3.utils.toWei(amount.toString(), "ether"),
        });
    }
    console.log(`USDC AMOUNT: ${USDC_AMOUNT.toString()}`)

    beforeEach(async() => {
        
        tokenA = await IERC20.at(USDC);
        tokenB = await IERC20.at(WETH);
        uniswapOptimal = await UniswapOptimal.new();
        pair = await IERC20.at(await uniswapOptimal.getPair(tokenA.address, tokenB.address))    // USDC, WETH

        console.log(`Pair address is: ${pair.address}`);

        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [USDC_WHALE],
        });

        console.log(`contract address is: ${uniswapOptimal.address}`)
        
        // send ether to whale in case it doesnt have enough 
        await sendEther(web3, accounts[0], USDC_WHALE, 1)

        const whale_balance = await tokenA.balanceOf(USDC_WHALE);
        assert(whale_balance.gte(USDC_AMOUNT), 'Whales USDC balance has to be higher than USDC_AMOUNT');
        tokenA.approve(uniswapOptimal.address, USDC_AMOUNT, { from: USDC_WHALE })
        console.log(`Whales USDC balance is: ${whale_balance/1e6}\n`)
    })

    const snapshot = async() => {
        return {
            lp_tokens: await pair.balanceOf(uniswapOptimal.address),
            tokenA: await tokenA.balanceOf(uniswapOptimal.address),
            tokenB: await tokenB.balanceOf(uniswapOptimal.address)
        }
    }

    it('optimal swap works correctly', async () => {

        const before_op = await snapshot();
        console.log('Current amounts in the contract before operation:')
        console.log(`lp tokens: ${before_op.lp_tokens.toString()}`)
        console.log(`tokenA: ${before_op.tokenA.toString()}`)
        console.log(`tokenB: ${before_op.tokenB.toString()}\n`)
        
        await uniswapOptimal.swapAndAddLiquidity(tokenA.address, tokenB.address, USDC_AMOUNT, 
            { from: USDC_WHALE, gas: 50000 })
        
        const after_op = await snapshot();

        console.log('Current amounts in the contract after operation:')
        console.log(`lp tokens: ${after_op.lp_tokens.toString()}`)
        console.log(`tokenA: ${after_op.tokenA.toString()}`)
        console.log(`tokenB: ${after_op.tokenB.toString()}\n`)

        assert.notEqual(await pair.balanceOf(uniswapOptimal.address), 0, 
            'amount of LP tokens has to be different from 0')
    })
})