/**
 * Script to deploy the Yacht Coin (YTC) token contract
 * 
 * How to run:
 * 1. Create a .env file in the uniswap-deploy directory with your private key:
 *    PRIVATE_KEY=your_private_key_here
 * 
 * 2. Run the deployment:
 *    - For local development: npx hardhat run scripts/deploy_yachtcoin.js --network localhost
 *    - For AIIGO testnet: npx hardhat run scripts/deploy_yachtcoin.js --network aiigo
 */

const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Yacht Coin (YTC) contract...");

  // Get the contract factory
  const YachtCoinFactory = await ethers.getContractFactory("YachtCoin");
  
  // Set initial supply to 1,000,000 tokens
  const initialSupply = 100000000;
  
  // Deploy the contract
  const yachtCoin = await YachtCoinFactory.deploy(initialSupply);
  
  // Wait for the contract to be deployed
  await yachtCoin.deployed();
  
  console.log("Yacht Coin contract deployed to:", yachtCoin.address);
  console.log("Token details:");
  console.log("  Name:", await yachtCoin.name());
  console.log("  Symbol:", await yachtCoin.symbol());
  console.log("  Decimals:", await yachtCoin.decimals());
  console.log("  Total Supply:", ethers.utils.formatUnits(await yachtCoin.totalSupply(), await yachtCoin.decimals()));
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 