// Add Buffer polyfill at top
import { Buffer } from 'buffer';
globalThis.Buffer = Buffer;

import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import ArcoVue from '@arco-design/web-vue';
// Import icon library
import ArcoVueIcon from '@arco-design/web-vue/es/icon';
// Import Arco UI styles
import '@arco-design/web-vue/dist/arco.css'

// Import router configuration
import router from './router/index.js'

// Import Pinia state management
import pinia from './stores/index.js'

// Import wallet initialization function
import { initializeWallet } from './stores/wallet.js'

const app = createApp(App);

// Use plugins

app.use(pinia)
app.use(router)
app.use(ArcoVue);
app.use(ArcoVueIcon);

// Mount app
app.mount('#app');

// Initialize wallet after app mount (ensure Pinia is activated)
if (typeof window !== 'undefined' && typeof document !== 'undefined') {
  // Ensure execution after DOM loading
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', async () => {
      try {
        // Try to load wallet data from localStorage first
        const ethereumData = localStorage.getItem('ethereumWalletData')
        if (ethereumData) {
          // If saved wallet data exists, initialize wallet directly
          await initializeWallet();
        }
      } catch (error) {
        console.error('Wallet initialization failed:', error);
      }
    });
  } else {
    // DOM already loaded, execute directly
    initializeWallet().catch(error => {
      console.error('Wallet initialization failed:', error);
    });
  }
}