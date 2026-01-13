<template>
  <div class="home-container">
    <a-carousel
      class="carousel-container"
      :auto-play="true"
      indicator-type="dot"
      show-arrow="hover"
      >
        <a-carousel-item>
          <div class="carousel-item-wrapper">
            <img src="/plugins/Rectangle19.png" class="carousel-image"/>
            <div class="carousel-text-overlay">
              <p class="carousel-subtitle">Famous Attractions</p>
              <span class="carousel-title">Venice</span>
            </div>
          </div>
        </a-carousel-item>
        <a-carousel-item>
          <div class="carousel-item-wrapper">
            <img src="/plugins/Rectangle20.png" class="carousel-image"/>
            <div class="carousel-text-overlay">
              <p class="carousel-subtitle">Famous Attractions</p>
              <span class="carousel-title">Huangshan Mountain</span>
            </div>
          </div>
        </a-carousel-item>
      </a-carousel>
    <!-- Hero Section -->
    <div class="hero-section">
      <h1 class="hero-title">Trusted AI Travel Review System</h1>
      <div class="hero-subtitle">
        Built on blockchain technology to ensure authentic and trustworthy reviews; AI-powered summary helps you quickly obtain core information; Token incentive ecosystem rewards valuable content contributions.
      </div>
      <div class="hero-actions">
        <button class="action-btn primary-btn" @click="scrollToFeatures">Start Exploring</button>
        <button class="action-btn secondary-btn" @click="scrollToComparison">Leave a Review</button>
      </div>
    </div>
    <!-- Features Section -->
    <div class="features-section">
      <div class="feature-card">
        <div class="feature-icon shield-icon"><icon-common /></div>
        <h3 class="feature-title">Blockchain Trust Verification</h3>
        <p class="feature-description">
          All AI summaries are stored on-chain through Oracle, ensuring data immutability and verifiability.
        </p>
      </div>

      <div class="feature-card">
        <div class="feature-icon brain-icon"><icon-bug /></div>
        <h3 class="feature-title">AI Intelligent Summary</h3>
        <p class="feature-description">
          Extract core opinions from massive reviews to generate concise and trustworthy summaries, saving your valuable time.
        </p>
      </div>

      <div class="feature-card">
        <div class="feature-icon token-icon"><icon-sun-fill /></div>
        <h3 class="feature-title">Token Economic Incentive</h3>
        <p class="feature-description">
          Earn Token rewards by contributing high-quality reviews, and consume Tokens to unlock premium features and upgrade levels.
        </p>
      </div>
    </div>

    <!-- Popular Attractions Section -->
    <div v-if="list.length > 0" class="destinations-section">
      <div class="section-header">
        <h2 class="section-title">Popular Attractions</h2>
      </div>

      <div class="destinations-grid">
        <div v-for="item in list" :key="item.scenicId" class="destination-card" @click="scrollToComparisonDetail(item.scenicId)">
          <div class="destination-image">
            <img :src="'/plugins/'+item.name+'.png'" alt="">
          </div>
          <h3 class="destination-name">{{ item.name }}</h3>
          <div class="destination-rating">
            <a-rate :default-value="item.averageRating" allow-half readonly />
          </div>
          <p class="destination-description">
            {{ item.description }}
          </p>
          <div class="destination-tags">
            <span v-for="tag in item.tags" :key="tag" class="tag">{{ tag }}</span>
          </div>
          <button class="view-detail-btn">
            <icon-eye /> View Details
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
  import { ref, onMounted } from 'vue'
  import { useRouter } from 'vue-router';
  import { EthereumService } from '../services/ethereum';
  // Create service instance
  const router = useRouter();
  const ethereumService = new EthereumService()


  // Popular attractions recommendation list
  const list = ref([]);
  onMounted(()=>{      
      getHotScenicSpots()
  })
  // Get popular attractions list through contract
  const getHotScenicSpots =  async ()=> {
    try {
      // Ensure window.ethereum exists
      if (!window.ethereum) {
        throw new Error('Please install MetaMask or another Ethereum wallet first');
      }
      list.value = await ethereumService.getScenicSpotList();      
      list.value.forEach(item => {
        const content = item.latestSummary.content ? JSON.parse(item.latestSummary.content) : {}
        item.averageRating = item.latestSummary.content ? Number(content.detailed_analysis?.overall_rating) / 2 : 0
        const decimalPart = item.averageRating - Math.floor(item.averageRating)
        // Use fixed values as judgment criteria
        if (decimalPart <= 0.3) {
          item.averageRating = Math.floor(item.averageRating) // Set to 0 stars
        } else if (decimalPart <= 0.7) {
          item.averageRating =  Math.floor(item.averageRating) + 0.5 // Set to 0.5 stars
        } else if (decimalPart <= 0.9) {
          item.averageRating = Math.floor(item.averageRating) + 1 // Set to 1 star
        }
      })
    } catch (error) {
      console.error('Failed to retrieve popular attractions list:', error);
      throw error;
    }
  }
  // Navigate to destinations page
  const scrollToFeatures = () => {
    router.push('/destinations')
  }
  // Navigate to review page
  const scrollToComparison = () => {
    router.push('/review')
  }
  // Navigate to attraction details page
  const scrollToComparisonDetail = (id) => {
    router.push({
      path: '/attractionDetails',
      query: { id: id }
    })
  }
// Home page component logic
</script>

<style scoped>
.home-container {
  max-width: 1440px;
  margin: 0 auto;
  padding: 0;
}

/* Carousel Styles */
.carousel-container {
  width: 100%;
  height: 400px;
  margin-bottom: 50px;
  overflow: hidden;
  border-radius: 10px;
  position: relative;
}

.carousel-item-wrapper {
  position: relative;
  width: 100%;
  height: 100%;
}

.carousel-image {
  border-radius: 10px;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.carousel-text-overlay {
  position: absolute;
  bottom: 120px;
  left: 0;
  right: 0;
  padding: 30px;
  background: linear-gradient(transparent, rgba(0,0,0,0.5));
  color: white;
}

.carousel-subtitle {
  display: inline-block;
  font-size: 30px;
  margin-bottom: 10px;
  border-bottom: 1px solid #fff;
  font-weight: bold;
  padding-bottom: 16px;
}

.carousel-title {
  font-size: 30px;
  font-weight: bold;
  display: block;
}

/* Hero Section Styles */
.hero-section {
  background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%);
  padding: 60px 40px;
  text-align: center;
  margin-bottom: 50px;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);
  border-radius: 12px;
}

.hero-title {
  font-size: 2.5rem;
  color: #0d47a1;
  margin-bottom: 25px;
  font-weight: 700;
}

.hero-subtitle {
  font-size: 1rem;
  color: #263238;
  line-height: 1.6;
  margin-bottom: 30px;
  max-width: 800px;
  margin-left: auto;
  margin-right: auto;
}

.hero-actions {
  display: flex;
  justify-content: center;
  gap: 16px;
}

.action-btn {
  padding: 12px 24px;
  border: none;
  border-radius: 6px;
  font-size: 1rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}

.primary-btn {
  background-color: #1976d2;
  color: white;
}

.primary-btn:hover {
  background-color: #1565c0;
  transform: translateY(-2px);
}

.secondary-btn {
  background-color: #ffffff;
  color: #1976d2;
  border: 1px solid #1976d2;
}

.secondary-btn:hover {
  background-color: #f5f5f5;
  transform: translateY(-2px);
}

/* Features Styles */
.features-section {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 24px;
  margin-bottom: 20px;
}

.feature-card {
  background: white;
  border-radius: 8px;
  padding: 32px 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.feature-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.12);
}

.feature-icon {
  font-size: 2.5rem;
  margin-bottom: 16px;
  width: 60px;
  height: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
}

.shield-icon {
  background-color: #e3f2fd;
  color: #1976d2;
}

.brain-icon {
  background-color: #e8f5e9;
  color: #388e3c;
}

.token-icon {
  background-color: #fff3e0;
  color: #f57c00;
}

.feature-title {
  font-size: 1.25rem;
  font-weight: 600;
  margin-bottom: 12px;
  color: #263238;
}

.feature-description {
  color: #607d8b;
  line-height: 1.6;
}

/* Popular Attractions Styles */
.destinations-section {
  margin-bottom: 60px;
}

.section-header {
  margin-bottom: 24px;
}

.section-title {
  font-size: 20px;
  font-weight: 700;
  color: #263238;
  position: relative;
  display: inline-block;
}

.section-title::after {
  content: '';
  position: absolute;
  left: 0;
  bottom: -8px;
  width: 40px;
  height: 3px;
  background-color: #1976d2;
  border-radius: 2px;
}

.destinations-grid {
  display: flex;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: 24px;
}

.destination-card {
  width: 22%;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  transition: transform 0.3s ease;
  cursor: pointer;
  position: relative;
  padding-bottom: 60px;
}

.destination-card:hover {
  transform: translateY(-4px);
  cursor: pointer;
}

.destination-image {
  width: 100%;
  height: 160px;
  background-color: #e0e0e0;
  border-radius: 8px 8px 0 0;
}
.destination-image img{
  width: 100%;
  height: 100%;
}
.destination-name {
  font-size: 1.125rem;
  font-weight: 600;
  color: #263238;
  margin: 16px 16px 8px 16px;
}

.destination-rating {
  margin: 0 16px 12px 16px;
}

.star {
  font-size: 1rem;
  margin-right: 2px;
}

.full-star {
  color: #ffc107;
}

.empty-star {
  color: #e0e0e0;
}

.destination-description {
  font-size: 0.875rem;
  color: #607d8b;
  line-height: 1.5;
  margin: 0 16px 12px 16px;
  height: 60px;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
}

.destination-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: 0 16px 16px 16px;
}

.tag {
  font-size: 0.75rem;
  padding: 4px 8px;
  background-color: #e3f2fd;
  color: #1976d2;
  border-radius: 4px;
}

.view-detail-btn {
  width: calc(100% - 32px);
  margin: 0 16px 16px 16px;
  padding: 8px 16px;
  background-color: #1976d2;
  color: white;
  border: none;
  border-radius: 4px;
  font-size: 0.875rem;
  cursor: pointer;
  transition: background-color 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  position: absolute;
  bottom: 0px;
}

.view-detail-btn:hover {
  background-color: #1565c0;
}

.view-icon {
  font-size: 0.75rem;
}

/* Responsive Design */
@media (max-width: 768px) {
  .hero-section {
    padding: 40px 20px;
  }

  .hero-title {
    font-size: 2rem;
  }

  .hero-actions {
    flex-direction: column;
    align-items: center;
  }

  .action-btn {
    width: 200px;
  }

  .features-section {
    grid-template-columns: 1fr;
    padding: 0 20px;
  }

  .destinations-section {
    padding: 0 20px;
  }

  .destinations-grid {
    grid-template-columns: 1fr;
  }
}
</style>
