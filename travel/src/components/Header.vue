<template>
  <header class="header">
    <div class="container">
      <div class="logo">
        <img src="/plugins/logo.svg" alt="TravelTrust Logo" />
        <span class="logo-text">TravelTrust</span>
      </div>

      <nav class="nav">
        <router-link to="/" class="nav-item"><icon-apps /> Home</router-link>
        <router-link to="/destinations" class="nav-item"><icon-bar-chart /> Destinations</router-link>
        <router-link to="/exchange" class="nav-item"><icon-archive /> Exchange</router-link>
        <router-link to="/profile" class="nav-item"><icon-user /> Profile</router-link>
        <router-link to="/docs" class="nav-item"><icon-book /> Documentation</router-link>
      </nav>

      <div class="header-actions">
        <div class="wallet-status" v-if="isConnected">
          <span class="connected-indicator"></span>
          <span class="wallet-address">{{ formattedAddress }}</span>
        </div>
        <icon-close class="close-icon" size="20" v-if="isConnected" @click="disconnectWallet" />
        <button class="connect-btn" v-else @click="connectWallet">Connect Wallet</button>
      </div>
    </div>

    <div v-if="showModal" class="modal-container">
      <div class="modal-backdrop" @click="closeModal"></div>
      <div class="modal-content">
        <wallet-connect-modal 
          :visible="showModal" 
          @close="closeModal" 
        />
      </div>
    </div>
  </header>
</template>

<script setup>
import { useRoute } from 'vue-router'
import { ref, computed, watch } from 'vue'
import { useWalletStore } from '../stores/wallet'
import walletService from '../services/wallet.service.js'
import WalletConnectModal from './WalletConnectModal.vue'

const walletStore = useWalletStore()
const route = useRoute()
const showModal = ref(false)

const PUBLIC_ROUTES = ['Home', 'Docs', 'Destinations']

watch(() => route.name, (newRouteName) => {
  if (!PUBLIC_ROUTES.includes(newRouteName) && !isConnected.value) {
    setTimeout(() => {
      if (!isConnected.value) {
        showModal.value = true
      }
    }, 2000)
  }
})

const isConnected = computed(() => walletStore.ethereumAddress)

const formattedAddress = computed(() => {
  const address = walletStore.ethereumAddress
  if (!address) return ''
  return `${address.slice(0, 6)}...${address.slice(-4)}`
})

const connectWallet = () => {
  showModal.value = true
}

const disconnectWallet = () => {
  walletStore.ethereumAddress = ''
  walletService.disconnectWallet()
}

const closeModal = () => {
  showModal.value = false
}
</script>

<style scoped>
.header {
  background-color: #0066ff;
  color: white;
  padding: 0 20px;
  height: 60px;
  display: flex;
  align-items: center;
  position: sticky;
  top: 0;
  z-index: 1000;
}

.container {
  width: 100%;
  max-width: 1400px;
  margin: 0 auto;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.logo {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 20px;
  font-weight: bold;
}

.logo img {
  width: 32px;
  height: 32px;
  border-radius: 4px;
}

.nav {
  display: flex;
  gap: 24px;
}

.nav-item {
  font-size: 16px;
  color: white;
  text-decoration: none;
  padding: 8px 12px;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.nav-item:hover {
  background-color: rgba(255, 255, 255, 0.1);
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 16px;
}

.wallet-status {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 12px;
  background-color: rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  cursor: pointer;
}

.wallet-status:hover {
  background-color: rgba(255, 255, 255, 0.2);
}

.connected-indicator {
  width: 8px;
  height: 8px;
  background-color: #52c41a;
  border-radius: 50%;
}

.wallet-address {
  font-size: 14px;
}

.close-icon {
  cursor: pointer;
}

.connect-btn {
  background-color: white;
  color: #0066ff;
  border: none;
  padding: 6px 16px;
  border-radius: 4px;
  cursor: pointer;
  font-weight: 500;
  transition: background-color 0.3s;
}

.connect-btn:hover {
  background-color: rgba(255, 255, 255, 0.9);
}

.modal-container {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: 2000;
  display: flex;
  align-items: center;
  justify-content: center;
}

.modal-backdrop {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.5);
}

.modal-content {
  position: relative;
  z-index: 2001;
  max-width: 90%;
  max-height: 90%;
  overflow: hidden;
}
</style>


