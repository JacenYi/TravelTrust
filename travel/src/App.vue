<script setup>
import Header from './components/Header.vue'
</script>

<template>
  <div class="app">
    <Header />
    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<style scoped>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  width: 100%;
  background-color: #f2f2f2;
}

.main-content {
  flex: 1;
  padding: 30px 100px;
  width: 100%;
  box-sizing: border-box;
}
</style>