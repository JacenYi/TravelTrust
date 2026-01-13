<template>
  <div class="destinations-container">
    <!-- Review Token Banner -->
    <div class="token-banner">
      <div class="banner-content">
        <h3>Earn Tokens by Reviewing! Share Your Journey, Get Rewarded~</h3>
        <p>Share authentic travel experiences and earn TRT Token rewards! Get 1-5 tokens directly when accepted by AI, higher levels earn more rewards~ Accumulate tokens to unlock premium features like attraction comparison. Share while earning - trustworthy reviews are more valuable!</p>
      </div>
      <a-button type="primary" size="large" class="banner-button" @click="scrollToComparison">Submit a Review</a-button>
    </div>

    <!-- Popular Attractions Section -->
    <div class="destinations-section">
      <div class="section-header">
        <h2 class="section-title">Popular Attractions</h2>
        <a-input-search
        :style="{width:'320px',backgroundColor:'rgba(134, 144, 156, 0.2)',borderRadius:'20px'}"
        placeholder="Search popular attractions by keyword"
        v-model="searchQuery"
        @search="handleSearch"
        />
      </div>

      <div class="destinations-grid">
        <div 
          v-for="(destination, index) in destinations" 
          :key="index"
          class="destination-card"
          @click="viewDetails(destination.scenicId)"
        >
          <div class="destination-image">
            <img :src="'/plugins/'+destination.name+'.png'" alt="">
          </div>
          <h3 class="destination-name">{{ destination.name }}</h3>
          <div class="destination-rating">
            <a-rate :default-value="destination.averageRating" allow-half readonly />
          </div>
          <p class="destination-description">
            {{ destination.description }}
          </p>
          <div class="destination-tags">
            <span v-for="(tag, tagIndex) in destination.tags" :key="tagIndex" class="tag">{{ tag }}</span>
          </div>
          <button class="view-detail-btn">
            <icon-eye /> View Details
          </button>
        </div>
      </div>
    </div>

    <!-- Pagination -->
    <div class="pagination">
      <a-pagination
        :current="current"
        page-size="8"
        :total="total"
        size="default"
        show-total
        @change="handlePageChange"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { EthereumService } from '../services/ethereum';
const ethereumService = new EthereumService()

// Router instance
const router = useRouter();

// Current page number
const current = ref(1);
const total = ref(0);
// Search query
const searchQuery = ref('');

// Attraction data array
const destinations = ref([]);
const list = ref([]);
// Popular attractions recommendation list
onMounted(()=>{
  getHotScenicSpots()  
})
// Get popular attractions recommendation list
const getHotScenicSpots =  async ()=> {
  try {
    // Create contract instance directly using ethers
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
        item.averageRating = Math.floor(item.averageRating) + 0.5 // Set to 0.5 stars
      } else if (decimalPart <= 0.9) {
        item.averageRating = Math.floor(item.averageRating) + 1 // Set to 1 stars
      }
    })
    // Initialize display of first page data
    handlePageChange(list.value);
  } catch (error) {
    console.error('Failed to retrieve hot scenic spots list:', error);
    throw error;
  }
}
// Handle search
const handleSearch = () => {
  let data = []
  if (searchQuery.value) {
    // Filter attraction data
    data = list.value.filter(item =>
      item.name.includes(searchQuery.value)
    );
  }else{
    data = list.value
  }
  
  // Calculate total pages
  total.value = data.length;
  current.value = 1;
  // Initialize display of first page data
  handlePageChange(data);
}
// Handle page change
const handlePageChange = (data = null) => {
  // Calculate start and end indexes for current page
  const startIndex = (current.value - 1) * 8;
  const endIndex = startIndex + 8;
  // Update displayed attraction data    
  if(data){    
    destinations.value = data.slice(startIndex, endIndex);
  }else{
    destinations.value = list.value.slice(startIndex, endIndex);
  }  
  total.value = data ? data.length : list.value.length
}
// Navigate to review page
const scrollToComparison = () => {
  router.push('/review')
}

// View attraction details
const viewDetails = (id) => {
  router.push({
    path: '/attractionDetails',
    query: { id: id }
  })
}
// Attraction recommendation page component
</script>

<style scoped>
.destinations-container {
  max-width: 1440px;
  margin: 0 auto;
}

/* Review Token Banner Styles */
.token-banner {
  background-color: #e6f7ff;
  border-radius: 8px;
  padding: 0 32px;
  margin-bottom: 30px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.banner-content{
  width: 60%;
}
.banner-content h3{
  font-size: 1.5rem;
  font-weight: 700;
  color: #096dd9;
  margin-bottom: 12px;
}
.banner-button{
  border-radius: 4px;
  background-color: #096dd9;
}
/* Popular Attractions Styles */


.section-header {
  margin-bottom: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-title {
  font-size: 1.75rem;
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
  cursor: pointer
}

.destination-image {
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
/* Pagination Styles */
.pagination {
  margin-top: 30px;
  display: flex;
  justify-content: flex-end;
}

/* Responsive Design */
@media (max-width: 768px) {
  .destinations-container {
    padding: 0 16px 24px;
  }
  
  .banner-content {
    flex-direction: column;
    align-items: stretch;
  }
  
  .section-title {
    margin-bottom: 16px;
  }
}
</style>