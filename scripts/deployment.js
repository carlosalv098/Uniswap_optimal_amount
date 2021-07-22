const hre = require('hardhat');

async function main() {
    
    const UniswapOptimal = await hre.ethers.getContractFactory('UniswapOptimal');
    const uniswapOptimal = await UniswapOptimal.deploy();

    await uniswapOptimal.deployed();

    console.log(`uniswapOptimal deployed at ${uniswapOptimal.address}`);
}

main()
    .then(() => process.exit(0))
    .catch(err => {
        console.error(err);
        process.exit(1);
    });