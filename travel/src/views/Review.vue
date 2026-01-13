<template>
  <div class="review-page" v-if="isWalletConnected">
    <h2 class="review-title">Submit Review</h2>
    <div class="review-container">
      <!-- Attraction Selection -->
      <div class="form-section">
        <h3 class="section-label">Select Destination</h3>
        <a-select 
          v-model="selectedDestination"
          style="width: 100%;"
          size="large"
          placeholder="Please select a destination"
        >
          <a-option v-for="spot in scenicSpotList" :key="spot.scenicId" :value="spot.scenicId">
            {{ spot.name }}
          </a-option>
        </a-select>
      </div>
      
      <!-- User Level and Reward Information -->
      <div class="user-level-info">
        <h3 class="section-label">Your Review Content</h3>
        <div>
          <span class="level-text">Your level: <strong>LV {{ userLevel.level }}</strong></span>
          <span class="reward-text">Estimated reward: <strong>{{ points }} Token</strong></span>
        </div>
      </div>
      
      <!-- Review Content Input -->
      <div class="form-section"> 
        <a-textarea
          v-model="reviewContent"
          :maxlength="300"
          :auto-size="{
            minRows:5,
            maxRows:10
          }"
          show-word-limit
          placeholder="You can review aspects like overall rating, crowd level, suitable audience, price level, recommended visiting time, and transportation convenience"
          style="width: 100%;"
        />
      </div>
      
      <!-- Star Rating -->
      <div class="form-section">
        <h3 class="section-label">Your Rating</h3>
        <div class="rating-container">
            <a-rate v-model="rating" allow-half />
        </div>
      </div>
      
      <!-- Tag Selection -->
      <div class="form-section">
        <h3 class="section-label">Select Tags</h3>
        <div class="tags-container">
          <div
            v-for="tag in availableTags"
            :key="tag"
            :class="['custom-tag', { 'selected': selectedTags.includes(tag) }]"
            @click="toggleTag(tag)"
          >
            {{ tag }}
          </div>
        </div>
      </div>
      
      <!-- Submit Button -->
      <div class="form-actions">
        <a-button 
          type="primary"
          :loading="subloading"
          :disabled="!canSubmit"
          @click="submitReview"
          style="width: 100%; height: 40px; font-size: 16px;"
        >
          <template #icon>
            <icon-send />
          </template>
          Submit Review
        </a-button>
      </div>
    </div>
  </div>
  <a-modal
    v-model:visible="ModalVisible"
    title=""
    width="420px"
    :footer="false"
    :mask-closable="false"
    @cancel="closeModal"
    :closable="false"
  >
    <div class="modal-box">
      <p class="modal-title">Your review is under AI review</p>
      <p class="modal-content">You can go to the profile page to check the review result or return to attraction details</p>
      <div class="modal-footer-buttons">
        <a-button size="large" shape="round" type="primary" @click="$router.push('/profile')">Go to Profile</a-button>
        <a-button size="large" shape="round" @click="$router.push('/attractionDetails?id=' + selectedDestination)">Back to Attraction Details</a-button>
      </div>
    </div>
  </a-modal>
</template>

<script setup>
import { ref, computed } from 'vue';
import { EthereumService } from '../services/ethereum';
import { useWalletStore } from '../stores/wallet';
import { useRouter } from 'vue-router';
import { Message } from '@arco-design/web-vue';
const router = useRouter();
const query = router.currentRoute.value.query
const ethereumService = new EthereumService();
const walletStore = useWalletStore()
const subloading = ref(false)
// Reactive data
const selectedDestination = ref('');
const reviewContent = ref('');
const rating = ref(5);
const userLevel = ref({})
const points = ref(0)
const ModalVisible = ref(false)
const availableTags = ref([
  'Beautiful Scenery', 
  'Convenient Transportation', 
  'Reasonable Price', 
  'Complete Facilities', 
  'Short Queue Time', 
  'Friendly Service'
]);
// Select all tags by default
const selectedTags = ref([...availableTags.value]);
const scenicSpotList = ref([])

// Method - Toggle tag selection status
const toggleTag = (tag) => {
  const index = selectedTags.value.indexOf(tag);
  if(selectedTags.value.length === 1 && index > -1){
    Message.warning('Please select at least one tag')
    return
  }
  if (index > -1) {
    // If already selected, deselect
    selectedTags.value.splice(index, 1);
  } else {
    // If not selected, add to selection
    selectedTags.value.push(tag);
  }
};

// Computed property - Whether review can be submitted
const canSubmit = computed(() => {
  return selectedDestination.value && 
         reviewContent.value.trim().length > 0 && 
         rating.value > 0;
});

// Computed property: Check if wallet is connected
const isWalletConnected = computed(() => {
  if (walletStore.ethereumConnected) {
    // Get popular attractions list through contract
    getHotScenicSpots()
  }
 
  return walletStore.ethereumConnected
})

// Get popular attractions list through contract
const getHotScenicSpots =  async ()=> {
  try {    
    scenicSpotList.value = await ethereumService.getScenicSpotList();
    selectedDestination.value = query.id ? Number(query.id) : scenicSpotList.value[0].scenicId
    
    // Call getUserLevelInfo method to get user level info
    const levelInfo = await ethereumService.getUserLevelInfo(walletStore.ethereumAddress);    
    userLevel.value = levelInfo;
    // Call getUserReviewReward method to get user review reward
    points.value = await ethereumService.getUserReviewReward(walletStore.ethereumAddress);
   
  } catch (error) {
    console.error(error);
    throw error;
  }
}

// Method - Submit review
const submitReview = async () => {
  // Validate form
  if (!canSubmit.value) {
    return;
  }
  
  try {
    // Ensure window.ethereum exists
    if (!window.ethereum) {
      throw new Error('Please install MetaMask or another Ethereum wallet first');
    }
    subloading.value = true
    
    /* Build review data */
    const scenicId = Number(selectedDestination.value);
    const availableTagsStr = selectedTags.value.join(',')
    const content = JSON.stringify({
      tags: availableTagsStr,
      content: reviewContent.value
    })
    
    // Call contract to submit review
    await ethereumService.userSubmitReview(scenicId, content, Math.round(rating.value * 2));
    
    Message.success('Review submitted successfully');
    // Clear form
    reviewContent.value = '';
    rating.value = 5;
    // Reset selected tags to all available tags
    selectedTags.value = [...availableTags.value];
    subloading.value = false
    ModalVisible.value = true
  } catch (error) {
    Message.error('Review submission failed, please try again later');
    console.error(error);
    subloading.value = false
  }
};
</script>

<style scoped>
.review-page {
  max-width: 800px;
  margin: 0 auto;
}
.review-container {
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 5px 24px 24px 24px;
}

.review-title {
  font-size: 20px;
  font-weight: 600;
  color: #263238;
  border-left: 4px solid #1976d2;
  padding-left: 12px;
  margin: 0 0 16px 0;
}

.form-section {
  margin-bottom: 24px;
}

.section-label {
  font-size: 16px;
  font-weight: bold;
  color: #1677ff;
  margin-bottom: 12px;
}

.user-level-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 20px;
  font-size: 14px;
  color: #666;
}
.level-text{
  margin-right: 20px;
}
.level-text strong,
.reward-text strong {
  color: #1976d2;
}

.rating-container {
  padding: 8px 0;
}

.tags-container {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.custom-tag {
  padding: 6px 12px;
  border-radius: 16px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.2s ease;
  background-color: #f0f0f0;
  color: #666;
}

.custom-tag:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.custom-tag.selected {
  background-color: #e6f4ff;
  color: #1677ff;
}

/* Delete old tag styles */
.tags-container :deep(.arco-tag) {
  display: none;
}
.tags-container :deep(.arco-tag:hover) {
  transform: translateY(-1px);
}

.form-actions {
  margin-top: 32px;
}

/* Modal content styles */
.modal-box {
  text-align: center;
  padding: 10px 24px;
}
.modal-title {
  font-size: 20px;
  font-weight: 900;
  color: #1677ff;
  margin-bottom: 12px;
}
.modal-content {
  font-size: 16px;
  color: #666;
  margin-bottom: 20px;
}
.modal-footer-buttons {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-top: 20px;
}
/* Responsive design */
@media (max-width: 768px) {
  .review-container {
    padding: 16px;
  }
  
  .user-level-info {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .review-title {
    font-size: 18px;
  }
}
</style>










