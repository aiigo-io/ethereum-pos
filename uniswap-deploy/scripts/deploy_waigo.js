/**
 * Script to deploy the WAIGO (Wrapped AIGO) token contract
 * 
 * How to run:
 * 1. Create a .env file in the uniswap-deploy directory with your private key:
 *    PRIVATE_KEY=your_private_key_here
 * 
 * 2. Run the deployment:
 *    - For local development: npx hardhat run scripts/deploy_waigo.js --network localhost
 *    - For AIIGO testnet: npx hardhat run scripts/deploy_waigo.js --network aiigo
 */

const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying WAIGO contract...");

  // Get the contract factory
  const WAIGOFactory = await ethers.getContractFactory("WAIGO");
  
  // Deploy the contract
  const waigo = await WAIGOFactory.deploy();
  
  // Wait for the contract to be deployed
  await waigo.deployed();
  
  console.log("WAIGO contract deployed to:", waigo.address);
  console.log("Token details:");
  console.log("  Name:", await waigo.name());
  console.log("  Symbol:", await waigo.symbol());
  console.log("  Decimals:", await waigo.decimals());
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 