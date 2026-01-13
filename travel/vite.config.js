import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
// Add node polyfills plugin
import { nodePolyfills } from 'vite-plugin-node-polyfills'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    // Configure node polyfills plugin
    nodePolyfills({
      // Enable Buffer polyfill
      include: ['buffer'],
      // Enable global Buffer variable
      globals: {
        Buffer: true,
      }
    })
  ],
  server: {
    host: true // Allow access via IP address
  }
})


