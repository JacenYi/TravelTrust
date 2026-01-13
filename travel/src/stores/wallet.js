import { defineStore } from 'pinia'
import walletService from '../services/wallet.service.js'

const STORAGE_KEY = 'ethereumWalletData'

export const useWalletStore = defineStore('wallet', {
  state: () => ({
    ethereumConnected: false,
    ethereumAddress: '',
    ethereumBalance: '0',
    ethereumWalletId: '',
    savedWallet: null,
    network: 'ETH',
  }),

  getters: {
    connectedWalletType: (state) => {
      if (state.ethereumConnected) return 'ethereum'
      return null
    },

    connectedAddress: (state) => {
      if (state.ethereumConnected) return state.ethereumAddress
      return ''
    },

    isConnected: (state) => state.ethereumConnected
  },

  actions: {
    saveToStorage(walletData) {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify({
          id: walletData.id,
          address: walletData.address,
          network: walletData.network,
          networkType: walletData.networkType
        }))
      } catch (error) {
        console.error('Failed to save wallet data to localStorage:', error)
      }
    },

    loadFromStorage() {
      try {
        const data = localStorage.getItem(STORAGE_KEY)
        return data ? JSON.parse(data) : null
      } catch (error) {
        console.error('Failed to load wallet data from localStorage:', error)
        return null
      }
    },

    clearStorage() {
      try {
        localStorage.removeItem(STORAGE_KEY)
      } catch (error) {
        console.error('Failed to clear wallet data from localStorage:', error)
      }
    },

    saveWalletData(walletData) {
      this.savedWallet = walletData
      this.ethereumConnected = true
      this.ethereumAddress = walletData.address
      this.ethereumWalletId = walletData.id
      this.saveToStorage(walletData)
    },

    clearWalletData() {
      this.ethereumConnected = false
      this.ethereumAddress = ''
      this.ethereumWalletId = ''
      this.savedWallet = null
      this.clearStorage()
    },

    setWalletAddress(address) {
      this.ethereumAddress = address
    },

    loadWalletFromStorage() {
      const walletData = this.loadFromStorage()
      if (walletData && this.network === 'ETH') {
        this.savedWallet = walletData
        this.ethereumWalletId = walletData.id
        return walletData
      }
      return null
    },

    async initializeAndConnectWallet() {
      try {
        const savedWallet = this.loadWalletFromStorage()
        
        if (savedWallet?.id && typeof walletService.autoConnectWallet === 'function') {
          const connectedWallet = await walletService.autoConnectWallet(savedWallet.id, savedWallet.networkType)
          
          if (connectedWallet) {
            this.saveWalletData(connectedWallet)
          }
        }
      } catch (error) {
        console.error('Error occurred when auto-connecting wallet:', error)
      }
    },

    async verifyWalletConnection() {
      if (!this.isConnected || typeof walletService.verifyConnection !== 'function') {
        return this.isConnected
      }

      try {
        const isValid = await walletService.verifyConnection()
        
        if (!isValid) {
          console.warn('Wallet connection status verification failed, clearing connection state')
          this.clearWalletData()
        }
        
        return isValid
      } catch (error) {
        console.error('Error occurred when verifying wallet connection status:', error)
        this.clearWalletData()
        return false
      }
    }
  }
})

export async function initializeWallet() {
  try {
    const walletStore = useWalletStore()
    await walletStore.initializeAndConnectWallet()
  } catch (error) {
    console.error('Error occurred when initializing wallet:', error)
  }
}