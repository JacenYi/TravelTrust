# TravelTrust Blockchain Travel Service Platform

## Notice
- node version:20.19.4
- This project is for learning and demonstration purposes only and is not recommended for use in production environments.
- This project requires connecting your wallet to the corresponding Ethereum network and chain before it can be used properly.

## Project Introduction

TravelTrust is a travel service platform based on blockchain technology, integrated with the Ethereum blockchain, aiming to provide decentralized travel service solutions. This project demonstrates how to integrate blockchain wallet connection functionality in Vue3 applications.

## Tech Stack

- **Frontend Framework**: Vue 3
- **Build Tool**: Vite
- **UI Component Library**: Arco Design
- **Blockchain Integration**:
  - Ethereum (ethers.js)
- **Development Language**: JavaScript

## Directory Structure

```
├── public/             # Static assets
├── src/                # Source code
│   ├── components/     # Vue components
│   ├── config/         # Configuration files
│   ├── plugins/        # Plugins
│   ├── services/       # Service layer (blockchain related)
│   ├── App.vue         # Root component
│   ├── main.js         # Entry file
│   └── style.css       # Global styles
├── .env                # Environment variables
├── .env.example        # Environment variables example
├── .gitignore          # Git ignore file
├── index.html          # HTML template
├── package.json        # Project configuration and dependencies
└── vite.config.js      # Vite configuration
```

## Installation and Running

### 1. Clone the Project

```bash
git clone <repository-url>
cd TravelTrust
```

### 2. Install Dependencies

```bash
npm install
```

### 3. Configure Environment Variables

Copy the example environment variable file and modify it according to your needs:

```bash
cp .env.example .env
```

Open the `.env` file and enter your API keys and other configurations:

```
# Ethereum configuration
VITE_ETHEREUM_PROVIDER_URL=https://mainnet.infura.io/v3/YOUR_INFURA_API_KEY

# Application environment
VITE_NODE_ENV=development
```

### 4. Run Development Server

```bash
npm run dev
```

Then open your browser and visit the local development URL (usually http://localhost:3000).

### 5. Build Production Version

```bash
npm run build
```

The build output will be generated in the `dist` directory.

## Features

### 1. Wallet Connection

- **Ethereum**: Connect MetaMask wallet to view account address and ETH balance

### 2. Balance Query

Provides the ability to query the balance of a specified blockchain account by entering an address.

## Blockchain Services

The project implements Ethereum blockchain service classes:

1. **ethereumService.js**: Encapsulates functionality for interacting with the Ethereum network

## Usage Instructions

1. Ensure you have installed the MetaMask browser extension
2. Connect your wallet on the homepage
3. After successful connection, you can view account information and balance
4. You can also use the balance query feature to enter other addresses to query their balances

## Notes

- The development environment connects to the test network by default, please ensure your wallet is also switched to the corresponding network
- Before deploying to production, be sure to replace API keys and configure the correct network nodes
- This project is for demonstration purposes, please strengthen security measures in actual production environments

## License

MIT License
