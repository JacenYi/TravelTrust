// Configuration Manager - For unified management of environment variables and application configuration

const config = {
  // Ethereum configuration
  ethereum: {
    providerUrl: import.meta.env.VITE_ETHEREUM_PROVIDER_URL || 'https://sepolia.infura.io/v3/YOUR_INFURA_KEY'
  },
  
  // Solana configuration
  solana: {
    clusterUrl: import.meta.env.VITE_SOLANA_CLUSTER_URL || 'https://api.devnet.solana.com'
  },
  
  // Application configuration
  app: {
    nodeEnv: import.meta.env.VITE_NODE_ENV || 'development'
  }
}

export default config