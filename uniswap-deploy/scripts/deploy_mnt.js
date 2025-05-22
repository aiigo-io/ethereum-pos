/**
 * Script to deploy the MNT token contract
 * 
 * How to run:
 * 1. Create a .env file in the uniswap-deploy directory with your private key:
 *    PRIVATE_KEY=your_private_key_here
 * 
 * 2. Run the deployment:
 *    - For local development: npx hardhat run scripts/deploy_mnt.js --network localhost
 *    - For AIIGO testnet: npx hardhat run scripts/deploy_mnt.js --network aiigo
 */

const { ethers } = require("hardhat");

async function main() {
  console.log("Deploying MNT token contract...");

  // Get the contract factory
  const MNTFactory = await ethers.getContractFactory("MNT");
  
  // Set initial supply to 1,000,000,000 tokens
  const initialSupply = 1000000000000;
  
  // Deploy the contract
  const mntToken = await MNTFactory.deploy(initialSupply);
  
  // Wait for the contract to be deployed
  await mntToken.deployed();
  
  console.log("MNT token contract deployed to:", mntToken.address);
  console.log("Token details:");
  console.log("  Name:", await mntToken.name());
  console.log("  Symbol:", await mntToken.symbol());
  console.log("  Decimals:", await mntToken.decimals());
  console.log("  Total Supply:", ethers.utils.formatUnits(await mntToken.totalSupply(), await mntToken.decimals()));
}

// Execute the deployment
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 