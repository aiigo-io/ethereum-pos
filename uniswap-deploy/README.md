# Uniswap V3 Deployment for AIIGO Blockchain

This project aims to deploy Uniswap V3 to the AIIGO blockchain using WAIGO (Wrapped AIGO) as the native wrapped token instead of WETH.

## Current Status

Currently, only the WAIGO token contract is implemented and deployable. The full Uniswap V3 deployment is under development.

## Prerequisites

- Node.js (v14+ recommended)
- npm or yarn
- Access to AIIGO blockchain (https://testnet.aiigo.org)
- Some AIGO tokens for gas fees

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the root directory with your private key:
```
PRIVATE_KEY=your_private_key_here
```

## WAIGO Token Deployment

To deploy only the WAIGO (Wrapped AIGO) token to the AIIGO testnet:

```bash
npm run deploy-waigo
```

For local development:

```bash
npx hardhat run scripts/deploy_waigo.js --network localhost
```

## Upcoming Features

The following features are planned but not yet implemented:

- Full Uniswap V3 deployment (Factory, Router, NFT components)
- WAIGO/USDC pool creation
- Adding liquidity functionality
- Swap functionality

Once fully implemented, deployment information will be saved to `uniswap-deployment.json`.

## License

MIT
