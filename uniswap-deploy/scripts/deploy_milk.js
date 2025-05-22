/**
 * Script to deploy the Milk token contract
 * 
 * How to run:
 * 1. Create a .env file in the uniswap-deploy directory with your private key:
 *    PRIVATE_KEY=your_private_key_here
 * 
 * 2. Run the deployment:
 *    - For local development: npx hardhat run scripts/deploy_milk.js --network localhost
 *    - For AIIGO testnet: npx hardhat run scripts/deploy_milk.js --network aiigo
 */

const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying Milk token contract...");

  // Get the contract factory
  const MilkFactory = await ethers.getContractFactory("Milk");
  
  // Set initial supply to 1,000,000,000 tokens
  const initialSupply = 10000000000;
  
  // Deploy the contract
  const milkToken = await MilkFactory.deploy(initialSupply);
  
  // Wait for the contract to be deployed
  await milkToken.deployed();
  
  console.log("Milk token contract deployed to:", milkToken.address);
  console.log("Token details:");
  console.log("  Name:", await milkToken.name());
  console.log("  Symbol:", await milkToken.symbol());
  console.log("  Decimals:", await milkToken.decimals());
  console.log("  Total Supply:", ethers.utils.formatUnits(await milkToken.totalSupply(), await milkToken.decimals()));
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 