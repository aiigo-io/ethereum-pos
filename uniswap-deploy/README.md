# Uniswap V3 Deployment for AIIGO Blockchain

This project deploys Uniswap V3 to the AIIGO blockchain using WAIGO (Wrapped AIGO) as the native wrapped token instead of WETH.

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

## Deployment

To deploy Uniswap V3 to the AIIGO testnet:

```bash
npm run deploy
```

This script will:
1. Deploy WAIGO (Wrapped AIGO) token
2. Deploy TestUSDC token
3. Deploy UniswapV3Factory
4. Deploy SwapRouter
5. Deploy NFT Descriptor components for liquidity positions
6. Create a WAIGO/USDC pool with initial price of 1 AIGO = 1000 USDC
7. Save all deployment information to `uniswap-deployment.json`

If you need to deploy the WAIGO token separately, you can directly run:

```bash
npx hardhat run scripts/deploy_waigo.js --network aiigo
```

For local development:

```bash
npm run deploy:local
```

Or to deploy only the WAIGO token to the local network:

```bash
npx hardhat run scripts/deploy_waigo.js --network localhost
```

## Adding Liquidity

After deployment, you can add liquidity to the WAIGO/USDC pool:

```bash
npm run add-liquidity
```

This script will:
1. Deposit AIGO to get WAIGO
2. Approve WAIGO and USDC tokens for the Position Manager
3. Create a liquidity position in the WAIGO/USDC pool
4. Return an NFT representing your position

## Making Swaps

To perform a swap on Uniswap:

```bash
npm run swap
```

This script will:
1. Swap 0.1 WAIGO for USDC
2. Display the swap details and rate

## Using Local Network

You can also deploy to a local Ethereum node by using the `:local` versions of the scripts:

```bash
npm run deploy:local
npm run add-liquidity:local
npm run swap:local
```

## Contract Addresses

After deployment, all contract addresses are saved in `uniswap-deployment.json`:

```json
{
  "network": {
    "name": "AIIGO Testnet",
    "chainId": 38888,
    "rpc": "https://testnet.aiigo.org"
  },
  "tokens": {
    "WAIGO": "0x...",
    "USDC": "0x..."
  },
  "uniswap": {
    "factory": "0x...",
    "router": "0x...",
    "positionManager": "0x..."
  },
  "pools": {
    "WAIGO-USDC": "0x..."
  }
}
```

## License

MIT
