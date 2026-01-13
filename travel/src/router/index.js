// Router configuration file
import { createRouter, createWebHistory } from 'vue-router'
const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('../views/Home.vue'),
    meta: { title: 'Home' }
  },
  {
    path: '/destinations',
    name: 'Destinations',
    component: () => import('../views/Destinations.vue'),
    meta: { title: 'Destinations' }
  },
  {
    path: '/attractionDetails',
    name: 'AttractionDetails',
    component: () => import('../views/AttractionDetails.vue'),
    meta: { title: 'Attraction Details' }
  },
  {
    path: '/exchange',
    name: 'Exchange',
    component: () => import('../views/Exchange.vue'),
    meta: { title: 'Exchange' }
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('../views/Profile.vue'),
    meta: { title: 'Profile' }
  },
  {
    path: '/docs',
    name: 'Docs',
    component: () => import('../views/Docs.vue'),
    meta: { title: 'Documentation' }
  },
  {
    path: '/review',
    name: 'Review',
    component: () => import('../views/Review.vue'),
    meta: { title: 'Submit Review' }
  },
  {
    path: '/comparison',
    name: 'AttractionComparison',
    component: () => import('../views/AttractionComparison.vue'),
    meta: { title: 'Compare Attractions' }
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('../views/NotFound.vue'),
    meta: { title: 'Page Not Found' }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    // Scroll to top
    return { top: 0 }
  }
})

// Global before guard to set page title and check wallet connection
router.beforeEach((to, from, next) => {
  document.title = to.meta.title ? `${to.meta.title} - TravelTrust` : 'TravelTrust'
  next()
})

export default router