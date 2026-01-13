<template>
  <div class="wallet-modal" v-if="visible">
    <div class="modal-overlay" v-if="isLoading"></div>
    <div class="wallet-modal-content">
      <div class="wallet-modal-header">
        <h3>Connect Wallet</h3>
      </div>
      <div class="wallet-modal-body">
        <div class="wallet-selection">
          <p class="step-description">Choose a wallet to connect</p>
          <button 
            v-for="wallet in allWallets" 
            :key="wallet.id"
            class="wallet-option"
            @click="selectWallet(wallet.id)"
          >
            <img :src="wallet.icon" alt="" class="wallet-icon" />
            <span class="wallet-name">{{ wallet.name }}</span>
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, watch } from 'vue'
import walletService from '../services/wallet.service.js'
import { useWalletStore } from '../stores/wallet.js'
import { Message } from '@arco-design/web-vue'

export default {
  name: 'WalletConnectModal',
  props: {
    visible: {
      type: Boolean,
      default: false
    }
  },
  emits: ['close', 'connected'],
  setup(props, { emit }) {
    const selectedWallet = ref('')
    const isLoading = ref(false)

    const allWallets = [
      { id: 'metamask', name: 'MetaMask', icon: '/plugins/metamask.png' },
      { id: 'coinbase', name: 'Coinbase Wallet', icon: '/plugins/coinbase.png' },
      { id: 'phantom', name: 'Phantom', icon: '/plugins/phantom.png' },
      { id: 'okx', name: 'OKX Wallet', icon: '/plugins/okx.png'},
      { id: 'gate', name: 'Gate Wallet', icon: '/plugins/gate.png'}
    ]

    watch(() => props.visible, (newVal) => {
      if (newVal) {
        resetState()
      }
    })

    const resetState = () => {
      selectedWallet.value = ''
    }

    const selectWallet = async (walletId) => {
      isLoading.value = true

      try {
        const installCheck = await walletService.checkWalletInstalled(walletId)
        if (!installCheck.installed) {
          throw new Error(installCheck.error || 'Wallet not installed')
        }

        selectedWallet.value = walletId
        await connectWalletToNetwork(walletId)
      } catch (error) {
        console.error('Error in wallet selection:', error)
        Message.error(error.message || 'Failed to connect wallet')
      } finally {
        isLoading.value = false
      }
    }

    const connectWalletToNetwork = async (walletId) => {
      try {
        const walletData = await walletService.connectWallet(walletId)

        if (walletData) {
          const walletStore = useWalletStore()
          walletStore.saveWalletData(walletData)
          emit('connected', walletData)
          handleClose()
        } else {
          throw new Error('Wallet connection failed: no data returned')
        }
      } catch (error) {
        let userFriendlyMessage = error.message || 'Failed to connect wallet'
        if (userFriendlyMessage.includes('User rejected')) {
          userFriendlyMessage = 'Connection rejected by user'
        } else if (userFriendlyMessage.includes('No provider') || userFriendlyMessage.includes('not installed')) {
          userFriendlyMessage = `Please install ${walletId.charAt(0).toUpperCase() + walletId.slice(1)} wallet`
        }
        console.error('Wallet connection error:', error)
        throw new Error(userFriendlyMessage)
      }
    }

    const handleClose = () => {
      resetState()
      emit('close')
    }

    const getWalletName = (walletId) => {
      const wallet = allWallets.find(w => w.id === walletId)
      return wallet ? wallet.name : ''
    }

    return {
      selectedWallet,
      allWallets,
      isLoading,
      selectWallet,
      handleClose,
      getWalletName
    }
  }
}
</script>

<style scoped>
.wallet-modal {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-width: 600px;
  height: 100%;
}

.wallet-modal-content {
  margin: 20px 0;
  background: white;
  border-radius: 8px;
  width: 100%;
  min-width: 90%;
  border: 1px solid #eaeaea;
}

.wallet-modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px;
  border-bottom: 1px solid #eaeaea;
}

.wallet-modal-header h3 {
  margin: 0;
  color: #333;
}

.wallet-modal-body {
  padding: 20px;
}

.wallet-selection .step-description {
  color: #666;
  margin-bottom: 20px;
  text-align: center;
  font-size: 14px;
}

.wallet-option {
  display: flex;
  align-items: center;
  padding: 15px;
  border: 1px solid #eaeaea;
  border-radius: 8px;
  margin-bottom: 10px;
  cursor: pointer;
  transition: all 0.2s;
  background: white;
  width: 100%;
  text-align: left;
}

.wallet-option:hover {
  border-color: #00B42A;
  background-color: #f9f9f9;
}

.wallet-option:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.wallet-icon {
  width: 24px;
  height: 24px;
  margin-right: 12px;
}

.wallet-name {
  font-weight: 500;
  color: #333;
}

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  z-index: 999;
}

@media (max-width: 768px) {
  .wallet-modal {
    width: 100%;
    min-width: 100%;
    margin: 20px auto;
    padding: 0;
  }

  .wallet-option {
    padding: 12px;
    margin-bottom: 8px;
  }

  .wallet-option img {
    width: 22px;
    height: 22px;
  }

  .wallet-option span {
    font-size: 14px;
  }

  .wallet-modal-content {
    width: 100%;
  }
}

@media (max-width: 480px) {
  .wallet-modal {
    width: 100%;
    min-width: 100%;
    padding: 0;
    margin: 20px auto;
  }

  .wallet-selection .step-description {
    font-size: 13px;
  }

  .wallet-option {
    padding: 10px;
  }

  .wallet-option img {
    width: 20px;
    height: 20px;
  }

  .wallet-option span {
    font-size: 13px;
  }
}
</style>