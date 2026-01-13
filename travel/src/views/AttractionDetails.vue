<template>
  <div class="docs-container" v-if="isWalletConnected">
    <!-- Attraction details area -->
    <div class="section-title">Attraction Details</div>
    <div class="destination-details">
      <div class="destination-content">
        <div class="destination-header">
          <h1 class="destination-name">{{scenicSpotDate.name}}</h1>
          <!-- Tags section -->
          <div class="destination-tags">
            <a-tag v-for="tag in scenicSpotDate.tags" :key="tag" class="tag" type="primary" color="blue">{{tag}}</a-tag>
          </div>
        </div>
        <!-- Comments section -->
        <div class="destination-comment">
          <p>{{scenicSpotDate.description}}
          </p>
        </div>
        <div class="destination-info">
          <div class="info-item">
            <span class="info-label">Location</span>
            <span class="info-value">{{ scenicSpotDate.location }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Attraction Rating</span>
            <span class="info-value">{{latestSummary.overall_rating ? latestSummary.overall_rating + ' / 10' : ''}}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Last Summary Update</span>
            <span class="info-value">{{ latestSummary.timestamp }}</span>
          </div>
        </div>
      </div>
      <div class="destination-rating">
        <span class="rating-score">{{ latestSummary.overall_rating}}</span>
        <span class="rating-label">Attraction Rating (Out of 10)</span>
      </div>
    </div>

    <!-- Data display area -->
    <div class="section-title" v-if="latestSummary && latestSummary.content">AI Summary</div>
    <div class="data-section" v-if="latestSummary && latestSummary.content">
      <!-- Hash section -->
      <div class="hash-section" v-if="!latestSummary.txHash.includes('0x00000000000')">
        <span class="hash-label">Hash:</span>
        <span class="hash-value">{{ latestSummary.txHash}}</span>
      </div>
      
      <!-- Attraction review example -->
      <div class="evaluation-card">
        <div class="evaluation-content1">
          {{ latestSummary.core_feedback_summary || 'N/A' }}
        </div>
      </div>
      
      <!-- Statistics data cards -->
      <div class="stats-cards">
        <div class="stat-card">
          <div class="stat-number blue">{{ latestSummary.positive || '0' }}</div>
          <div class="stat-label">Positive Reviews</div>
        </div>
        <div class="stat-card">
          <div class="stat-number orange">{{ latestSummary.neutral || '0' }}</div>
          <div class="stat-label">Neutral Reviews</div>
        </div>
        <div class="stat-card">
          <div class="stat-number red">{{ latestSummary.negative || '0' }}</div>
          <div class="stat-label">Negative Reviews</div>
        </div>
      </div>
      
      <!-- Popular tags -->
      <div class="tags-section">
        <div class="section-title-sm">Popular Tags</div>
        <div class="tags-list">
          <div v-for="tag in latestSummary.popular_tags" :key="tag" class="tag">{{tag}}</div>
        </div>
      </div>

      <!-- Detailed analysis table -->
      <div class="analysis-table">
        <div class="section-title-sm">Detailed Analysis</div>
        <div class="table-content">
          <div class="table-row">
            <div class="table-cell title">Overall Rating</div>
            <div class="table-cell">{{ latestSummary.overall_rating }} / 10.0</div>
            <div class="table-cell title">Location</div>
            <div class="table-cell">{{ latestSummary.location }}</div>
          </div>
          <div class="table-row">
            <div class="table-cell title">Crowd Level</div>
            <div class="table-cell">{{ latestSummary.crowd_level }}</div>
            <div class="table-cell title">Best Season</div>
            <div class="table-cell">{{ latestSummary.best_season }}</div>
          </div>
          <div class="table-row">
            <div class="table-cell title">Suitable For</div>
            <div class="table-cell">{{ latestSummary.suitable_people }}</div>
            <div class="table-cell title">Price Level</div>
            <div class="table-cell">{{ latestSummary.price_level }}</div>
          </div>
          <div class="table-row">
            <div class="table-cell title">Suggested Duration</div>
            <div class="table-cell">{{ latestSummary.suggested_duration }}</div>
            <div class="table-cell title">Transportation</div>
            <div class="table-cell">{{ latestSummary.traffic_convenience }}</div>
          </div>
        </div>
      </div>
      <div class="action-buttons">
        <a-button type="primary" shape="round" size="large" class="action-btn" @click="viewHistorySummary">View Historical Summaries</a-button>
        <a-button type="primary" shape="round" size="large" class="action-btn" @click="viewOriginalEvaluations">View Original Reviews</a-button>
        <a-button type="primary" status="success" shape="round" size="large" class="action-btn" @click="compareAttractions">Compare Attractions</a-button>
        <a-button type="primary" shape="round" size="large" class="action-btn" @click="submitEvaluation">Submit a Review</a-button>
      </div>
    </div>
    
    <!-- Trustworthy review collection module -->
    <div class="trustworthy-feedback-section" v-else>
      <div class="feedback-header">
        <div class="feedback-header-content">
          <icon-clock-circle class="header-icon" />
          <h2>{{scenicSpotDate.name}} Trustworthy Review Collection</h2>
        </div>
        <p class="feedback-description">{{scenicSpotDate.name}} currently lacks sufficient trustworthy review data to generate an attraction summary. Become one of the first reviewers and provide authentic references for future travelers.</p>
      </div>
      
      <div class="welcome-box">
        <p>Welcome to participate in {{scenicSpotDate.name}}'s trustworthy review collection! As one of the first reviewers, your contribution will help future travelers make better decisions while earning corresponding <span class="token-highlight">Token</span> rewards.</p>
      </div>
      
      <div class="reward-explanation">
        <p>Review rewards are calculated based on your account level</p>
        <p style="color: #666;">Higher levels earn more Tokens per AI-verified review. You can use reward Tokens to upgrade your account level.</p>
        
        <div class="level-cards">
          <div class="level-card v1">
            <h3>V1</h3>
            <p>Per review reward: <span>1 Token</span></p>
          </div>
          <div class="level-card v2">
            <h3>V2</h3>
            <p>Per review reward: <span>2 Token</span></p>
          </div>
          <div class="level-card v3">
            <h3>V3</h3>
            <p>Per review reward: <span>3 Token</span></p>
          </div>
        </div>
      </div>
      
      <div class="authentication-box">
        <div class="auth-content">
          <icon-subscribed class="auth-icon" />
          <div class="auth-text">
            <p>All reviews will undergo AI verification, and their hash values will be permanently stored on-chain to ensure authenticity and immutability</p>
            <p class="auth-highlight">20 valid reviews needed to generate an AI summary</p>
          </div>
        </div>
      </div>
      
      <div class="action-buttons">
        <a-button type="primary" shape="round" size="large" class="action-btn" @click="viewOriginalEvaluations">View Original Reviews</a-button>
        <a-button type="primary" shape="round" size="large" class="action-btn" @click="submitEvaluation">Submit a Review</a-button>
      </div>
    </div>
    
    <!-- History records module, only displayed after user payment -->
    <div v-if="hasPaidHistory" class="data-section" style="margin-top: 30px;">
      <div class="section-title">Historical Summaries</div>
      <div class="history-list">
        <div v-for="record in historyRecords" :key="record.id" class="history-item" @click="openHistoryModal(record)">
          <div class="history-header">
            <span class="history-name">{{ record.scenicSpot.name }}</span>
            <span class="history-time">Attraction summary update time:</span>
          </div>
          <div style="display:flex;justify-content: space-between;align-items: center;">
            <div class="hash-section" style="color:#666;border-radius: 20px;">
              <span v-if="!record.txHash.includes('0x00000000000')" class="hash-label">Hash:</span>
              <span v-if="!record.txHash.includes('0x00000000000')" class="hash-value">{{ record.txHash }}</span>
            </div>
            <div>
              {{ record.timestamp }}
            </div>
          </div>
        </div>
      </div>
      <div class="pagination">
        <a-pagination 
          :total="total" 
          :page-size="8"
          :current="current"
          @change="paginateData"
          show-total
        />
      </div>
    </div>

    <!-- Original review content -->
    <div v-if="hasPaidOriginal" class="data-section" style="margin-top: 30px;">
      <div class="section-title">Original Reviews</div>
      <!-- Review list -->
      <div class="evaluation-list">
        <div v-for="evaluation in evaluations" :key="evaluation.scenicId" class="evaluation-item" @click="openEvaluationModal(evaluation)">
          <div class="evaluation-header">
            <h4 class="destination-name">{{ evaluation.name }}</h4>
            <div class="evaluation-time">
              <span class="user-name">User: {{ evaluation.userName }}</span>
              <span class="evaluation-time">{{ evaluation.formattedTimestamp }}</span>
            </div>
          </div>
          <div v-if="!evaluation.txHash.includes('0x00000000000')" class="hash-section" style="background-color: #fff;">
            <span class="hash-label">Hash:</span>
            <span class="hash-value">{{ evaluation.txHash}}</span>
          </div>
          <div class="evaluation-content">
            {{ evaluation.content }}
          </div>
          <div class="evaluation-footer">
            <a-tag :color="evaluation.statusTagsColor">{{ evaluation.statusText }}</a-tag>
            <span v-if="evaluation.status === 1" class="token-reward">💰 +{{ evaluation.rewardAmount }}</span>
          </div>
        </div>
      </div>

      <!-- Pagination controls - Using Arco UI's Pagination component -->
      <div class="pagination">
        <a-pagination 
          :total="total" 
          :current="current" 
          :page-size="8" 
          show-total
          @change="paginateData"
        />
      </div>
    </div>

    <!-- History record details modal -->
    <a-modal
      v-model:visible="historyModalVisible"
      title="Historical Record Details"
      width="820px"
      :footer="false"
      @cancel="closeHistoryModal">
      <div class="history-content">
        <!-- Attraction details area -->
        <div class="section-title">Attraction Details</div>
        <div class="destination-details">
          <div class="destination-content" style="width: 70%;">
            <div class="destination-header">
              <h1 class="destination-name">{{ historyModalItem.scenicSpot?.name }}</h1>
              <!-- Tags section -->
              <div class="destination-tags">
                <a-tag v-for="tag in historyModalItem.scenicSpot?.tags" :key="tag" class="tag" type="primary" color="blue">{{ tag }}</a-tag>
              </div>
            </div>
            <!-- Comments section -->
            <div class="destination-comment">
              <p>{{ historyModalItem.scenicSpot?.description }}</p>
            </div>
            <div class="destination-info">
              <div class="info-item">
                <span class="info-label">Attraction Rating</span>
                <span class="info-value">{{ historyModalItem.overall_rating + '/ 10.0' }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Location</span>
                <span class="info-value">{{ historyModalItem.location }}</span>
              </div>
              <div class="info-item">
                <span class="info-label">Attraction Info Update Time</span>
                <span class="info-value">{{ historyModalItem.timestamp }}</span>
              </div>
            </div>
          </div>
          <div class="destination-rating">
            <span class="rating-score">{{ historyModalItem.overall_rating }}</span>
            <span class="rating-label">Attraction Rating (Out of 10)</span>
          </div>
        </div>

        <!-- Data display area -->
        <div class="section-title">AI Summary</div>
        <div class="data-section">
          <!-- Hash section -->
          <div class="hash-section" v-if="historyModalItem.txHash && !historyModalItem.txHash.includes('0x00000000000')">
            <span class="hash-label">Hash:</span>
            <span class="hash-value">{{ historyModalItem.txHash }}</span>
          </div>
          
          <!-- Attraction review example -->
          <div class="evaluation-card">
            <div class="evaluation-content1">
              {{ historyModalItem.core_feedback_summary }}
            </div>
          </div>
          
          <!-- Statistics data cards -->
          <div class="stats-cards">
            <div class="stat-card">
              <div class="stat-number blue">{{ historyModalItem.positive }}</div>
              <div class="stat-label">Positive Reviews</div>
            </div>
            <div class="stat-card">
              <div class="stat-number orange">{{ historyModalItem.neutral }}</div>
              <div class="stat-label">Neutral Reviews</div>
            </div>
            <div class="stat-card">
              <div class="stat-number red">{{ historyModalItem.negative }}</div>
              <div class="stat-label">Negative Reviews</div>
            </div>
          </div>
          
          <!-- Popular tags -->
          <div class="tags-section">
            <div class="section-title-sm">Popular Tags</div>
            <div class="tags-list">
              <div v-for="tag in historyModalItem.popular_tags" :key="tag" class="tag">{{ tag }}</div>
            </div>
          </div>
          
          <!-- Detailed analysis table -->
          <div class="analysis-table">
            <div class="section-title-sm">Detailed Analysis</div>
            <div class="table-content">
              <div class="table-row">
                <div class="table-cell title">Overall Rating</div>
                <div class="table-cell">{{ historyModalItem.overall_rating + '/ 10.0' }}</div>
                <div class="table-cell title">Location</div>
                <div class="table-cell">{{ historyModalItem.location }}</div>
              </div>
              <div class="table-row">
                <div class="table-cell title">Crowd Level</div>
                <div class="table-cell">{{ historyModalItem.crowd_level }}</div>
                <div class="table-cell title">Best Season</div>
                <div class="table-cell">{{ historyModalItem.best_season }}</div>
              </div>
              <div class="table-row">
                <div class="table-cell title">Suitable For</div>
                <div class="table-cell">{{ historyModalItem.suitable_people }}</div>
                <div class="table-cell title">Price Level</div>
                <div class="table-cell">{{ historyModalItem.price_level }}</div>
              </div>
              <div class="table-row">
                <div class="table-cell title">Suggested Duration</div>
                <div class="table-cell">{{ historyModalItem.suggested_duration }}</div>
                <div class="table-cell title">Transportation</div>
                <div class="table-cell">{{ historyModalItem.transportation }}</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </a-modal>

    <!-- Review details modal -->
    <a-modal
      class="evaluation-modal"
      v-model:visible="evaluationModalVisible"
      title="Review Details"
      width="760px"
      :footer="false"
      @cancel="closeEvaluationModal"
    >
      <div class="evaluationModalContent">
        <div class="form-section">
          <div class="section-label">Reviewer:</div>
          <a-input v-model="evaluationModalItem.userName" disabled />
        </div>
        <div class="form-section" v-if="evaluationModalItem.txHash && !evaluationModalItem.txHash.includes('0x00000000000')">
          <div class="section-label">hash:</div>
          <a-input v-model="evaluationModalItem.txHash" disabled />
        </div>
        <div class="form-section">
          <div class="section-label">Attraction:</div>
          <a-input v-model="evaluationModalItem.name" disabled />
        </div>
        <div class="form-section">
          <div class="section-label">Review Content:</div>
          <a-textarea v-model="evaluationModalItem.content" disabled max-length="200"/>
        </div>
        <div class="form-section">
          <div class="section-label">Rating:</div>
          <a-rate v-model="evaluationModalItem.rating" allow-half readonly/>
        </div>
        <div class="form-section">
          <div class="section-label">Review Tags:</div>
          <div class="tags-container">
            <a-tag
              v-for="tag in evaluationModalItem.tags"
              :key="tag"
              color='blue'
              @click="toggleTag(tag)"
            >
              {{ tag }}
            </a-tag>
          </div>
        </div>
        <div class="form-section">
          <div class="section-label">Review Time:</div>
          <a-input v-model="evaluationModalItem.timestamp" disabled />
        </div>
         <div class="form-section">
          <a-tag :color="evaluationModalItem.statusTagsColor">{{ evaluationModalItem.statusText }}</a-tag>
          <span v-if="evaluationModalItem.status === 1" class="token-reward">💰 +{{ evaluationModalItem.rewardAmount }}</span>
        </div>
      </div>
    </a-modal>
  </div>
</template>
<script setup>
import { ref, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useWalletStore } from '../stores/wallet';
import { ethereumService } from '../services/ethereum';
const walletStore = useWalletStore()

// Router instance
const router = useRouter();
const current = ref(1);
const total = ref(0);
const hasPaidHistory = ref(false); // Whether user has paid to view history records
const hasPaidOriginal = ref(false); // Whether user has paid to view original reviews
const historyModalVisible = ref(false); // History record details modal state
const historyModalItem = ref({}); // History record details modal data item
const evaluationModalVisible = ref(false); // Review details modal state
const evaluationModalItem = ref({}); // Review details modal data item

const scenicSpotDate = ref({
  scenicId: null,
  name: '',
  location: '',
  description: '',
  tags: '',
  reviewCount: 0,
  averageRating: 0, // Assuming rating is stored as 10x
  active: ''
});
const latestSummary = ref({
  content: '',
  version: 1,
  timestamp:''
});
// Computed property: Check if wallet is connected
const isWalletConnected = computed(() => {
  if (walletStore.ethereumConnected) {
    // Get attraction details through contract
    getHotScenicSpotDetails()
  }
  
  return walletStore.ethereumConnected
})
// Review data array
const allEvaluations = ref([]);
const evaluations = ref([])

// History records data array
const historyRecords = ref([]);
const allHistoryRecords = ref([])

// Get popular attraction details
const getHotScenicSpotDetails = async()=>{
   try {
      const scenicId = router.currentRoute.value.query.id;
      if (!scenicId) {
        throw new Error('Attraction ID parameter is missing');
      }
      
      const scenicSpot = await ethereumService.getScenicSpot(scenicId);
      scenicSpotDate.value = scenicSpot.scenicSpot
      latestSummary.value = scenicSpot.latestSummary
      latestSummary.value.content = latestSummary.value.content ? JSON.parse(latestSummary.value.content) : ''
    } catch (error) {
      throw error;
    }
}
// Pagination data
const paginateData = (e) => {    
  current.value = e
  const start = (current.value - 1) * 8
  const end = start + 8
  if(hasPaidHistory.value){
    historyRecords.value = allHistoryRecords.value.slice(start, end)
    total.value = allHistoryRecords.value.length
  }else if(hasPaidOriginal.value){    
    evaluations.value = allEvaluations.value.slice(start, end)
    total.value = allEvaluations.value.length
  }
}
// Open review details modal
const openEvaluationModal = (item) => {    
  evaluationModalVisible.value = true;
  evaluationModalItem.value = item;  
};

// Close review details modal
const closeEvaluationModal = () => {
  evaluationModalVisible.value = false;
};

// Open history record details modal
const openHistoryModal = (item) => {    
  historyModalVisible.value = true;
  historyModalItem.value = item;  
};

// Close history record details modal
const closeHistoryModal = () => {
  historyModalVisible.value = false;
};
// View history summary
const viewHistorySummary = async() => {
  hasPaidHistory.value = true
  hasPaidOriginal.value = false
  total.value = 0
  if(walletStore.ethereumConnected){
    const list = await ethereumService.getScenicSpotList(); 
    allHistoryRecords.value = await ethereumService.getHistoricalSummaries(scenicSpotDate.value.scenicId);
    allHistoryRecords.value.forEach(item => {
      item.scenicSpot = list.find(spot => spot.scenicId === item.scenicId) || {};
    })
    allHistoryRecords.value.reverse()
  }
  
  paginateData(1)
};
// View original reviews
const viewOriginalEvaluations = async() => {
  hasPaidOriginal.value = true
  hasPaidHistory.value = false
  total.value = 0
  if(walletStore.ethereumConnected){
    const list = await ethereumService.getScenicSpotList(); 
    allEvaluations.value = await ethereumService.getHistoricalReviews(scenicSpotDate.value.scenicId);    
    allEvaluations.value.forEach(item => {
      item.name = list.find(spot => spot.scenicId === item.scenicId)?.name || 'Unknown Attraction';
    });
    
    total.value = await ethereumService.getHistoricalReviewsCount(scenicSpotDate.value.scenicId);
    allEvaluations.value.reverse()
  }
  paginateData(1)
};

// Compare attractions
const compareAttractions = () => {
  router.push({
    path:'/comparison',
    query: {
      id: scenicSpotDate.value.scenicId
    }
  });
};
// Navigate to review
const submitEvaluation = () => {
  router.push({
    path: '/review',
    query: {
      id: scenicSpotDate.value.scenicId
    }
  });
};
</script>
<style scoped>
  .trustworthy-feedback-section {
    background: #f9f9f9;
    padding: 20px;
    border-radius: 8px;
    margin: 20px 0;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  }
  
  .feedback-header {
    background: #1890ff;
    color: white;
    padding: 15px 20px;
    border-radius: 8px;
    margin-bottom: 15px;
  }
  .feedback-header-content{
    display: flex;
    align-items: center;
    gap: 10px;
  }
  .header-icon {
    width: 24px;
    height: 24px;
  }
  
  .feedback-header h2 {
    margin: 0;
    font-size: 18px;
    font-weight: 900;
  }
  
  .feedback-description {
    color: #fff;
    margin-bottom: 15px;
  }
  
  .welcome-box {
    background: white;
    border: 1px solid #e8e8e8;
    border-radius: 10px;
    padding: 15px;
    margin-bottom: 20px;
    border-left: 4px solid #1890ff;
  }
  
  .token-highlight {
    color: #1890ff;
    font-weight: 500;
  }
  
  .reward-explanation p {
    margin: 8px 0;
    color: #333;
  }
  
  .level-cards {
    display: flex;
    gap: 15px;
    margin: 15px 0;
  }
  
  .level-card {
    background: #e6e4ff;
    padding: 15px;
    border-radius: 4px;
    text-align: center;
    margin-right: 20px;
  }
  
  .level-card h3 {
    margin: 0 0 10px 0;
    font-size: 20px;
  }
  
  .level-card p {
    margin: 0;
    color: #666;
  }
  .level-card p span{
    font-weight: 900;
    color:#1890ff
  }
  
  
  .level-card.v1 h3 {
    color: #52c41a;
  }
  

  
  .level-card.v2 h3 {
    color: #fa8c16;
  }
  

  
  .level-card.v3 h3 {
    color: #1890ff;
  }
  
  .authentication-box {
    background: #f6ffed;
    border: 1px solid #b7eb8f;
    border-radius: 10px;
    padding: 15px;
    margin: 20px 0;
  }
  
  .auth-content {
    display: flex;
    align-items: center;
    gap: 10px;
  }
  
  .auth-icon {
    flex-shrink: 0;
    margin-top: 2px;
    color: #52c41a;
    font-size: 30px;
  }
  
  .auth-text p {
    margin: 5px 0;
    color: #52c41a;
  }
  
  .auth-highlight {
    color: #52c41a !important;
    font-weight: 500;
  }
  
  .feedback-actions {
    display: flex;
    gap: 15px;
    margin-top: 20px;
  }
  
  .feedback-btn {
    flex: 1;
  }
</style>
<style scoped>
.docs-container {
  max-width: 1440px;
  margin: 0 auto;
  padding-bottom: 20px;
  background-color: #f5f5f5;
}
.section-title{
  font-size: 20px;
  font-weight: bold;
  color: #263238;
  margin-bottom: 20px;
  border-left: 4px solid #1677ff;
  padding-left: 12px;
}
/* Attraction details styles */
.destination-details {
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 16px 20px;
  margin-bottom: 20px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  /* flex-wrap: wrap; */
}
.destination-content{
  width: 70%;
}
.destination-header .destination-name {
  color: #1677ff;
  font-size: 24px;
  font-weight: bold;
  margin: 0 0 8px 0;
}
.evaluation-time{
  display: flex;
  align-items: center;
  gap: 8px;
}
.destination-comment{
  font-size: 14px;
  color: #999;
  line-height: 1.6;
  margin-bottom: 16px;
}
.user-name{
  width: 150px;
  display: inline-block;
  padding: 4px 20px;
  background-color: #f2f2f2;
  border-radius: 14px;
  font-size: 12px;
  color: #333;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  margin-right: 8px;
}
.destination-info {
  width: 60%;
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 24px;
  flex: 1;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  font-size: 14px;
  color: #666;
}

.info-value {
  font-size: 14px;
  color: #333;
}

/* Modify padding to percentage values to make it follow parent div height changes */
.destination-rating {
  /* width: 20%; */
  height: 100%;
  background-color: #e6f7ff;
  border-radius: 4px;
  padding: 7% 4%; /* Use percentage values instead of fixed pixel values */
  text-align: center;
  min-width: 100px;
  box-sizing: border-box;
}

.rating-score {
  font-size: 36px;
  font-weight: bold;
  color: #1677ff;
  display: block;
}

.rating-label {
  font-size: 12px;
  color: #666;
  margin-top: 4px;
}

/* Data display area styles */
.data-section {
  padding: 20px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
}

/* Hash section */
.hash-section {
  display: inline-block;
  padding: 4px 20px;
  margin-bottom: 16px;
  color: #666;
  font-size: 14px;
  color: #1677ff;
  border-radius: 10px;
  background-color: #e6f4ff;
}

.hash-label {
  font-weight: 500;
  margin-right: 8px;
}

.hash-value {
  font-family: monospace;
}

/* Attraction review card */
.evaluation-card {
  border: 1px solid #d9d9d9;
  border-radius: 6px;
  margin-bottom: 20px;
}

.evaluation-content1 {
  padding: 16px;
  line-height: 1.6;
  color: #333;
  font-size: 14px;
  border-left: 3px solid #40a9ff;
}

/* Statistics data cards */
.stats-cards {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

.stat-card {
  background-color: #e6f4ff;
  border-radius: 6px;
  padding: 16px;
  text-align: center;
}

.stat-number {
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 4px;
}

.stat-number.blue {
  color: #40a9ff;
}

.stat-number.orange {
  color: #fa8c16;
}

.stat-number.red {
  color: #ff4d4f;
}

.stat-label {
  font-size: 14px;
  color: #666;
}

/* Popular tags area */
.tags-section {
  margin-bottom: 20px;
}

.section-title-sm {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin-bottom: 12px;
  color: #1677ff;
}

.tags-list {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tags-list .tag {
  background-color: #f0f0f0;
  color: #666;
  padding: 4px 12px;
  border-radius: 16px;
  font-size: 13px;
  transition: all 0.2s;
}
.tags-list .tag:hover {
  background-color: #1677ff;
  color: white;
}

.destination-tags .tag {
  margin-right: 8px;
  border-radius: 16px;
}

/* Detailed analysis table */
.analysis-table {
  border-radius: 6px;
  overflow: hidden;
}

.table-header {
  padding: 12px 16px;
  border-bottom: 1px solid #f0f0f0;
}

.table-content {
  border: 1px solid #f0f0f0;
  padding: 0;
}

.table-row {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr 1fr;
  border-bottom: 1px solid #f0f0f0;
}

.table-row:last-child {
  border-bottom: none;
}

.table-cell {
  padding: 12px 16px;
  font-size: 14px;
  border-right: 1px solid #f0f0f0;
  color: #666;
}

.table-cell.title {
  font-weight: 500;
  color: #1677ff;
}
.action-buttons{
  margin-top: 30px;
}
.action-btn{
  margin: 0 10px;
}
/* Responsive design */
@media (max-width: 768px) {
  .stats-cards {
    grid-template-columns: 1fr;
  }
  
  .table-row {
    grid-template-columns: 1fr 1fr;
  }
  
  .destination-details {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .destination-rating {
    margin-top: 16px;
    width: 100%;
  }
}

@media (max-width: 480px) {
  .table-row {
    grid-template-columns: 1fr;
  }
  
  .destination-info {
    flex-direction: column;
    gap: 12px;
  }
}
/* Modal related styles */
.payment-content {
  text-align: center;
}
.payment-question {
  margin-bottom: 12px;
  color: #333;
}

/* History records module styles */
.tabs {
  display: flex;
  gap: 16px;
  margin-bottom: 16px;
}

.tab {
  padding: 4px 12px;
  background-color: #f5f5f5;
  border-radius: 16px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.2s;
}

.tab:hover {
  background-color: #e6f7ff;
}

.tab.active {
  background-color: #1677ff;
  color: white;
}

.history-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 16px;
}

.history-item {
  padding: 16px;
  background-color: white;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
  cursor: pointer;
}

.history-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.history-name {
  color: #1677ff;
  font-size: 16px;
  font-weight: 700;
  text-decoration: none;
  flex-shrink: 0;
}

.history-time {
  font-size: 13px;
  color: #999;
  flex-shrink: 0;
}

.history-item .hash-section {
  display: inline-block;
  padding: 8px 16px;
  margin-bottom: 0;
  text-align: left;
  border-radius: 4px;
  background-color: #86909c19;
}

.pagination {
  display: flex;
  justify-content: flex-end;
}

.page-info {
  font-size: 13px;
  color: #666;
}

.page-number {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  font-size: 13px;
  cursor: pointer;
}

.page-number.active {
  background-color: #1677ff;
  color: white;
}

.page-more {
  font-size: 16px;
  color: #999;
  cursor: pointer;
}

.page-size {
  padding: 4px 8px;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  font-size: 13px;
  background-color: white;
}


.tab-content {
  margin: 12px 0 24px 0;
  padding: 24px;
  background-color: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

/* Filter tags styles */
.filter-tags {
  padding: 24px;
  display: flex;
  gap: 12px;
}

.filter-tag {
  padding: 6px 16px;
  border-radius: 16px;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s;
  background-color: #f0f0f0;
  color: #666;
}

.filter-tag.active {
  background-color: #1890ff;
  color: white;
}

.filter-tag:hover:not(.active) {
  background-color: #e6f7ff;
  color: #1890ff;
}

/* Review list styles */
.evaluation-list {
  padding: 0 24px;
}

.evaluation-item {
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 16px;
  margin-bottom: 16px;
  cursor: pointer;
}
.evaluation-item:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
.evaluation-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.destination-name {
  font-size: 16px;
  font-weight: 600;
  color: #1890ff;
  margin: 0;
}

.evaluation-time {
  font-size: 12px;
  color: #999;
}

.evaluation-content {
  background-color: #f9fafb;
  border-radius: 10px;
  padding: 12px;
  margin-bottom: 12px;
  font-size: 14px;
  line-height: 1.6;
  color: #666;
  border: 1px solid #e6f7ff;
  border-left: 3px solid #d7d7d7;
}

.evaluation-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
}

.status-badge.accepted {
  background-color: #f6ffed;
  color: #52c41a;
}

.status-badge.pending {
  background-color: #e6f7ff;
  color: #1890ff;
}

.status-badge.rejected {
  background-color: #fff2f0;
  color: #ff4d4f;
}

.token-reward {
  color: #52c41a;
  font-weight: 600;
  font-size: 14px;
}
.history-content{
  overflow: auto;
  height: 700px;
}
.history-content .destination-details .destination-content{
  width: 50%;
}
.evaluationModalContent{
  height: 650px;
  overflow: auto;
}
.form-section{
  margin-bottom: 20px;
}
.section-label {
  font-size: 16px;
  margin-bottom: 8px;
  font-weight: bold;
  color: #1677ff;
}

.tags-container {
  margin-top: 12px;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.tags-container :deep(.arco-tag) {
  cursor: pointer;
  transition: all 0.2s ease;
}

.tags-container :deep(.arco-tag:hover) {
  transform: translateY(-1px);
}
</style>

<style lang="less" scoped>
/deep/.arco-input[disabled] {
    background-color: #f5f5f5;
    cursor: not-allowed;
    color: #000;
    -webkit-text-fill-color: #000;
  }
  /deep/.arco-textarea[disabled]{
    background-color: #f5f5f5;
    cursor: not-allowed;
    color: #000;
    -webkit-text-fill-color: #000;
  }
</style>