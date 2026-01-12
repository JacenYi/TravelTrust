require('@nomicfoundation/hardhat-toolbox');
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: '0.8.20',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545'
    },
    mantleSepolia: {
      url: process.env.MANTLE_SEPOLIA_RPC_URL || 'https://rpc.sepolia.mantle.xyz',
      chainId: 5003,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    }
  },
  etherscan: {
    apiKey: {
      mantleSepolia: process.env.ETHERSCAN_API_KEY || ''
    },
    customChains: [
      {
        network: 'mantleSepolia',
        chainId: 5003,
        urls: {
          apiURL: 'https://explorer.sepolia.mantle.xyz/api',
          browserURL: 'https://explorer.sepolia.mantle.xyz'
        }
      }
    ]
  }
};
