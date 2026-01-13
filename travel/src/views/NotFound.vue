<template>
  <div class="not-found-container">
    <h1>404
    </h1>
    <h2>Page Not Found</h2>
    <p>The page you're looking for doesn't exist or has been removed.</p>
    <RouterLink to="/" class="btn-link">Go Home</RouterLink>
  </div>
</template>

<script setup>
import { RouterLink } from 'vue-router'
</script>

<style scoped>
.not-found-container {
  max-width: 500px;
  margin: 4rem auto;
  text-align: center;
}

h1 {
  font-size: 6rem;
  margin: 0;
  color: #1677ff;
}

h2 {
  margin: 1rem 0;
  color: #1a1a1a;
}

.btn-link {
  display: inline-block;
  margin-top: 2rem;
  padding: 0.5rem 1.5rem;
  background: #1677ff;
  color: white;
  text-decoration: none;
  border-radius: 4px;
  transition: background-color 0.3s;
}

.btn-link:hover {
  background: #4096ff;
}
</style>