import { ethers } from 'ethers';
import { useWalletStore } from '../stores/wallet.js';


/**
 * Wallet Service Class
 */
class WalletService {
  constructor() {
    // Initialize properties
    this.provider = null;
    this.signer = null;
    this.connectedWallets = {}; // Used to store all connected wallets
    this.currentWallet = null; // Currently active wallet
    this.network = 'ETH'; // Default network
    this.tokenAddress = null;
    this.currency = null;
    
    // Event listeners
    this.eventListeners = {};
    
    // Set up event listeners
    this.setupWalletListeners();
  }
  
  /**
   * Set up wallet event listeners
   */
  setupWalletListeners() {
    // Listen for Ethereum account changes
    if (typeof window !== 'undefined' && window.ethereum) {
      window.ethereum.on('accountsChanged', (accounts) => {

        // Case 1: Account list is empty (user removed all authorizations)
        if (accounts.length === 0) {
          this.disconnectWallet();
          return;
        }

        // Case 2: Switched to a new authorized account
        const newActiveAccount = accounts[0];
        // Compare with current account to avoid duplicate updates
        
        if (this.currentWallet && newActiveAccount !== this.currentWallet.address) {
          this.currentWallet.address = newActiveAccount;
          
          // Trigger account switch event
          this.emit('accountsChanged', accounts);
          this.emit('accountSwitched', newActiveAccount);
          
          // Update address information in localStorage
          try {
            if (this.network === 'ETH') {
              const savedData = localStorage.getItem('ethereumWalletData');
              if (savedData) {
                const walletData = JSON.parse(savedData);
                walletData.address = newActiveAccount;
                localStorage.setItem('ethereumWalletData', JSON.stringify(walletData));
              }
            }
          } catch (e) {
            console.warn('Failed to update localStorage address info:', e);
          }
          
        }
        // Update Dapp business state
        this.updateDappWithNewAccount(newActiveAccount);
      });

      // Listen for chain switch events
      window.ethereum.on('chainChanged', (chainId) => {
        this.emit('chainChanged', chainId);
        
        // After chain switch, it's recommended to reinitialize account
        this.initMetaMaskAccount();
      });
    }
  }
  
  /**
   * Initialize MetaMask account (get initial authorized account)
   */
  async initMetaMaskAccount() {
    try {
      if (!window.ethereum) {
        console.warn('MetaMask wallet not detected');
        return null;
      }

      // Actively request user authorization to get account list (required for first authorization)
      const accounts = await window.ethereum.request({
        method: 'eth_requestAccounts'
      });

      // Initialize current active account (first element in array is current active account)
      if (accounts.length > 0) {
        const currentActiveAccount = accounts[0];
        
        // Update current wallet address
        if (this.currentWallet) {
          this.currentWallet.address = currentActiveAccount;
        }
        
        // Trigger Dapp internal account update logic
        this.updateDappWithNewAccount(currentActiveAccount);
        
        return currentActiveAccount;
      }
      
      return null;
    } catch (error) {
      // Handle when user rejects authorization
      if (error.code === 4001) {
        console.error('User rejected MetaMask authorization request');
        this.emit('authorizationRejected', error);
      } else {
        console.error('Failed to initialize account:', error);
        this.emit('initAccountError', error);
      }
      throw error;
    }
  }
  
  /**
   * Dapp internal account update logic (customizable based on business needs)
   */
  updateDappWithNewAccount(account) {
    if (account) {
      // 1. Update account display on page (e.g., show first 6 and last 4 digits: 0x1234...5678)
      const displayAccount = `${account.slice(0, 6)}...${account.slice(-4)}`;
      
      // Trigger event to allow other components to listen for account updates
      this.emit('accountUpdated', {
        address: account,
        displayAddress: displayAccount
      });
      
      // 2. Update wallet state in store
      try {
        const walletStore = useWalletStore();
        if (walletStore) {          
          walletStore.setWalletAddress(account);
        }
      } catch (e) {
        console.warn('Failed to update wallet address in store:', e);
      }
    } else {
      // Reset page display when no authorized account
      console.error('No authorized account, resetting state');
      
      // Trigger event to notify other components that account has been cleared
      this.emit('accountUpdated', null);
      
      // Clear wallet state in store
      try {
        const walletStore = useWalletStore();
        if (walletStore) {
          walletStore.clearWalletData();
        }
      } catch (e) {
        console.warn('Failed to clear wallet data in store:', e);
      }
    }
  }

  /**
   * Remove wallet event listeners
   */
  removeWalletListeners() {
    // Remove Ethereum event listeners
    if (typeof window !== 'undefined' && window.ethereum) {
      try {
        window.ethereum.removeAllListeners('accountsChanged');
        window.ethereum.removeAllListeners('chainChanged');
      } catch (e) {
        console.warn('Failed to remove Ethereum event listeners:', e);
      }
    }
    
    // Remove Solana event listeners
    if (typeof window !== 'undefined' && window.solana) {
      try {
        window.solana.removeAllListeners('disconnect');
      } catch (e) {
        console.warn('Failed to remove Solana event listeners:', e);
      }
    }
  }
  
  /**
   * Event publish-subscribe system
   */
  on(event, listener) {
    if (!this.eventListeners[event]) {
      this.eventListeners[event] = [];
    }
    this.eventListeners[event].push(listener);
  }

  emit(event, data) {
    if (this.eventListeners[event]) {
      this.eventListeners[event].forEach(listener => {
        try {
          listener(data);
        } catch (error) {
          console.error(`Error in event listener for ${event}:`, error);
        }
      });
    }
  }
  
  /**
   * Check if wallet is installed
   */
  async checkWalletInstalled(walletId) {
    try {
      // Basic check
      if (typeof window === 'undefined') {
        return { installed: false, error: 'Not in a browser environment' };
      }

      // Check based on different wallet types
      switch (walletId) {
        case 'metamask':
          return window.ethereum && window.ethereum.isMetaMask 
            ? { installed: true } 
            : { installed: false, error: 'MetaMask is not installed. Please install MetaMask to continue.' };
        
        case 'coinbase':
          return window.ethereum && window.ethereum.isCoinbaseWallet 
            ? { installed: true } 
            : { installed: false, error: 'Coinbase Wallet is not installed. Please install Coinbase Wallet to continue.' };
        
        case 'solflare':
        case 'phantom':
          return window.solana 
            ? { installed: true } 
            : { installed: false, error: 'Solana wallet is not installed. Please install a Solana wallet like Phantom or Solflare to continue.' };
        
        default:
          // Default to checking Ethereum wallet
          return window.ethereum 
            ? { installed: true } 
            : { installed: false, error: 'No compatible wallet found. Please install a wallet to continue.' };
      }
    } catch (error) {
      console.error('Error checking wallet installation:', error);
      return { installed: false, error: 'Error checking wallet installation' };
    }
  }
  
  /**
   * Get wallet name
   */
  getWalletNameById(walletId) {
    const walletNames = {
      'metamask': 'MetaMask',
      'coinbase': 'Coinbase Wallet',
      'solflare': 'Solflare',
      'phantom': 'Phantom'
    };
    
    return walletNames[walletId] || walletId;
  }
  
  /**
   * Connect EVM compatible wallet
   */
  async connectEVMWallet(walletId) {
    try {
      if (!window.ethereum) {
        throw new Error('Ethereum provider not found');
      }
      
      // Initialize MetaMask account (get initial authorization)
      await this.initMetaMaskAccount();
      
      // Ensure using the correct Ethereum provider
      const provider = new ethers.BrowserProvider(window.ethereum);
      
      // Get signer
      const signer = await provider.getSigner();
      
      // Get network information
      const network = await provider.getNetwork();
      
      // Get currently active account address
      const accounts = await window.ethereum.request({ method: 'eth_accounts' });
      const address = accounts[0];
      
      // Store connection information
      this.provider = provider;
      this.signer = signer;
      
      const walletData = {
        id: walletId,
        address,
        chainId: network.chainId,
        network: 'ETH',
        networkType: 'ETH'
      };
      this.network = 'ETH'
      this.connectedWallets[walletId] = walletData;
      this.currentWallet = walletData;
      
      // Trigger connection event
      this.emit('walletConnected', walletData);
      
      return walletData;
    } catch (error) {
      console.error(`Error connecting to ${this.getWalletNameById(walletId)}:`, error);
      throw error;
    }
  }
  /**
   * Connect wallet based on wallet ID and network type
   */
  async connectWallet(walletId) {
    try {
      // Pre-check if wallet is installed
      const installCheck = await this.checkWalletInstalled(walletId);
      if (!installCheck.installed) {
        throw new Error(installCheck.error);
      }
      return this.connectEVMWallet(walletId);
    } catch (error) {
      console.error('Wallet connection error:', error);
      throw error;
    }
  }
  
  /**
   * Auto connect wallet (no user interaction required)
   */
  async autoConnectWallet(walletId) {
    try {      
      // Check if wallet is installed
      const installCheck = await this.checkWalletInstalled(walletId);
      if (!installCheck.installed) {
        console.warn(`${this.getWalletNameById(walletId)} not installed, skipping auto-connection`);
        return null;
      }
      
      return await this.autoConnectEVMWallet(walletId);
      
    } catch (error) {
      console.error('Failed to auto-connect wallet:', error);
      return null;
    }
  }
  
  /**
   * Auto connect EVM compatible wallet
   */
  async autoConnectEVMWallet(walletId) {
    try {
      if (!window.ethereum) {
        throw new Error('Ethereum provider not found');
      }
      
      // Try to get account info without requesting permissions (silent connection)
      const accounts = await window.ethereum.request({
        method: 'eth_accounts'
      });
      
      // If no account returned, user needs to authorize manually
      if (!accounts || accounts.length === 0) {
        console.warn(`No authorized ${this.getWalletNameById(walletId)} account found`);
        return null;
      }
      
      // Create provider and signer
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const network = await provider.getNetwork();
      const address = accounts[0];
      
      // Create wallet data object
      const walletData = {
        id: walletId,
        address,
        chainId: network.chainId,
        network: this.network,
        nenetworkType: this.network
      };
      
      // Update connection state
      this.provider = provider;
      this.signer = signer;
      this.connectedWallets[walletId] = walletData;
      this.currentWallet = walletData;
      
      this.emit('walletConnected', walletData);
      
      return walletData;
    } catch (error) {
      console.error(`Failed to auto-connect ${this.getWalletNameById(walletId)}:`, error);
      return null;
    }
  }
  
  /**
   * Verify wallet connection status
   */
  async verifyConnection() {
    try {
      if (!this.currentWallet) {
        return false;
      }
      
      const { id, networkType } = this.currentWallet;
      
      // Verify connection based on network type
      if (networkType === 'ETH') {
        // Check EVM wallet connection status
        if (window.ethereum) {
          const accounts = await window.ethereum.request({ method: 'eth_accounts' });
          return accounts && accounts.length > 0;
        }
      }
      
      // Disconnect if verification fails
      this.disconnectWallet();
      return false;
    } catch (error) {
      console.error('Failed to verify wallet connection status:', error);
      // Disconnect if verification error occurs
      this.disconnectWallet();
      return false;
    }
  }
  
  /**
   * Disconnect wallet
   */
  async disconnectWallet() {
    try {
      // Clear wallet data from localStorage
      try {
        localStorage.removeItem('ethereumWalletData');
        localStorage.removeItem('solanaWalletData');
        
        // Also clear wallet state in store
        const walletStore = useWalletStore();
        if (walletStore && typeof walletStore.clearWalletData === 'function') {
          walletStore.clearWalletData();
        }
      } catch (e) {
        console.warn('Failed to clear wallet data:', e);
      }
      
      // Try to call disconnect method if available
      if (this.currentWallet && this.currentWallet.networkType === 'ETH' && window.ethereum && typeof window.ethereum.disconnect === 'function') {
        try {
          await window.ethereum.disconnect();
        } catch (e) {
          console.warn('Failed to disconnect Ethereum wallet:', e);
        }
      }
      
      // Clean up internal state
      this.removeWalletListeners();
      this.provider = null;
      this.signer = null;
      this.connectedWallets = {};
      this.currentWallet = null;
      
      // Reset event listeners
      this.setupWalletListeners();
      
      // Trigger disconnection event
      this.emit('walletDisconnected');
      return true;
    } catch (error) {
      console.error('Failed to disconnect wallet:', error);
      // Try to clean up state even if error occurs
      try {
        this.removeWalletListeners();
        this.provider = null;
        this.signer = null;
        this.connectedWallets = {};
        this.currentWallet = null;
        this.setupWalletListeners();
        this.emit('walletDisconnected');
      } catch (cleanupError) {
        console.error('Failed to clean up connection state:', cleanupError);
      }
      return false;
    }
  }
  
  /**
   * Get currently connected wallet info
   */
  getWalletInfo() {
    if (!this.currentWallet) {
      return null;
    }
    return {
      address: this.currentWallet.address,
      network: this.network,
      networkType: this.network,
      connected: true
    };
  }
}

// Export singleton instance
export default new WalletService();