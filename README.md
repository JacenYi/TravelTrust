# Scenic Spot Review System on Mantle Network

A decentralized travel review system built on Mantle Network, combining blockchain technology with AI-powered review processing to create a transparent, secure, and intelligent platform for travel enthusiasts.

## Features

### Core Functionality
- **Scenic Spot Management**: Create and manage travel destinations with detailed information
- **Decentralized Reviews**: Users can submit reviews with ratings and tagged content
- **AI-Powered Review Processing**: Oracle node processes reviews using AI for quality assessment
- **Automated Rewards**: Users receive TravelTokens for approved reviews
- **AI-Generated Summaries**: Periodic summaries of reviews for each scenic spot using AI
- **Historical Data Tracking**: Maintain versions of summaries and reviews

### Technical Features
- **Mantle Network Integration**: Optimized for Layer 2 efficiency and cost savings
- **Smart Contract Architecture**: Modular design with clear separation of concerns
- **Oracle Integration**: Secure off-chain AI processing with on-chain verification
- **ERC20 Token System**: Custom TravelToken for rewards and ecosystem incentives
- **Access Control**: Role-based permissions for secure operations
- **Reentrancy Protection**: Built-in safeguards against common attacks

## Technology Stack

### Blockchain
- **Network**: Mantle Network (EVM Layer 2)
- **Framework**: Hardhat
- **Smart Contracts**: Solidity ^0.8.20
- **Libraries**: OpenZeppelin Contracts v5.0.2

### Oracle Node
- **Language**: Python
- **AI Integration**: Volc Engine AI API
- **Database**: SQLite
- **Web3 Provider**: Web3.py

### Development Tools
- **Testing**: Hardhat Test
- **Deployment**: Hardhat Deploy
- **Verification**: Etherscan/Hardhat Etherscan Plugin

## Project Structure

```
├── contracts/              # Solidity smart contracts
│   ├── interfaces/        # Contract interfaces
│   ├── CouponSystem.sol   # Coupon management
│   ├── FundPool.sol       # Reward pool management
│   ├── ReviewProcessor.sol # Review processing logic
│   ├── ScenicNFT.sol      # Scenic spot NFTs
│   ├── ScenicReviewCore.sol # Core review functionality
│   ├── ScenicStorage.sol  # Data storage
│   ├── SummaryGenerator.sol # Summary generation logic
│   ├── TravelToken.sol    # ERC20 reward token
│   └── UserLevel.sol      # User level management
├── oracle_node/           # Off-chain oracle system
│   ├── src/               # Oracle source code
│   ├── db/                # Database
│   └── logs/              # Log files
├── hardhat.config.js      # Hardhat configuration
├── package.json           # Project dependencies
└── README.md              # This file
```

## Installation

### Prerequisites
- Node.js v18+ and npm
- Python 3.8+
- Hardhat CLI
- Mantle Network RPC access
- Volc Engine AI API credentials (for oracle node)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/JacenYi/TravelTrust.git
   cd TravelTrust
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

4. **Set up Oracle Node**
   ```bash
   cd oracle_node
   pip install -r requirements.txt
   cp .env.example .env
   # Edit .env with your Oracle configuration
   ```

## Usage

### Compile Contracts
```bash
npm run compile
```

### Run Tests
```bash
npm run test
```

### Deploy to Mantle Sepolia
```bash
npm run deploy:sepolia
```

### Verify Contracts
```bash
npm run verify -- --network mantleSepolia <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

### Start Oracle Node
```bash
cd oracle_node
python src/main.py
```

## Contract Architecture

### Main Contracts

#### ScenicReviewSystem.sol
The central contract that manages:
- Scenic spot information
- User review submissions
- Review approval process
- Summary generation and storage
- Event emissions for oracle integration

#### TravelToken.sol
ERC20 token contract that:
- Handles token minting and burning
- Manages reward distributions
- Integrates with the review system

#### FundPool.sol
Manages the reward pool:
- Stores tokens for reviews
- Controls reward distribution logic
- Tracks pool balances

#### UserLevel.sol
Manages user levels and rewards:
- Calculates reward amounts based on user level
- Tracks user activity and level progression

### Oracle Node Integration

The oracle node performs these key functions:
1. **Event Listening**: Monitors blockchain for new reviews and summary requests
2. **AI Processing**: Uses Volc Engine AI to:
   - Validate and approve reviews
   - Generate summaries from multiple reviews
3. **On-chain Updates**: Sends processed results back to the blockchain

## Reward System

Users earn TravelTokens for submitting approved reviews:
- Rewards are calculated based on user level
- Review quality is assessed by AI
- Approved reviews contribute to summary generation
- Higher quality reviews receive greater rewards

## Gas Optimization on Mantle

- **Calldata Usage**: Minimized storage operations, using calldata where possible
- **Batch Processing**: Grouping similar operations to reduce transaction costs
- **Unchecked Operations**: Safe usage of unchecked blocks for arithmetic operations
- **Event Optimization**: Efficient event emissions to reduce gas costs
- **Storage Layout**: Optimized variable packing to reduce storage slots

## Security Considerations

### Smart Contract Security
- **Reentrancy Protection**: Implemented using OpenZeppelin's ReentrancyGuard
- **Access Control**: Role-based permissions using Ownable and custom modifiers
- **Input Validation**: Strict validation of all user inputs
- **Integer Safety**: Leveraging Solidity 0.8+ built-in overflow protection
- **Oracle Security**: Secure communication between on-chain and off-chain components

### Oracle Security
- **Signature Verification**: All oracle responses are signed and verified
- **Rate Limiting**: Protection against excessive requests
- **Error Handling**: Robust error handling and recovery mechanisms
- **Data Integrity**: Verification of data before on-chain updates

## Deployment

### Network Configuration

#### Mantle Sepolia Testnet
- RPC URL: `https://rpc.sepolia.mantle.xyz`
- Chain ID: `5003`
- Gas Price: EIP-1559 compatible

#### Mantle Mainnet
- RPC URL: `https://rpc.mantle.xyz`
- Chain ID: `5000`
- Gas Price: EIP-1559 compatible

### Deployment Steps

1. Configure network settings in `hardhat.config.js`
2. Set up environment variables in `.env`
3. Compile contracts: `npm run compile`
4. Run tests: `npm run test`
5. Deploy: `npm run deploy:sepolia` (for testnet)
6. Verify contracts: `npm run verify`
7. Start oracle node with appropriate configuration

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Make your changes
4. Test thoroughly (`npm run test`)
5. Commit with clear messages (`git commit -m 'Add some AmazingFeature'`)
6. Push to the branch (`git push origin feature/AmazingFeature`)
7. Open a Pull Request

## License

This project is licensed under the Apache-2.0 license.

## Acknowledgments

- [Mantle Network](https://mantle.xyz/) for their Layer 2 infrastructure
- [OpenZeppelin](https://openzeppelin.com/) for their security-focused contract libraries
- [Volc Engine](https://www.volcengine.com/) for AI capabilities
- All contributors to this project

Built with ❤️ on Mantle Network
