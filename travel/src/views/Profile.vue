<template>
  <div class="profile-container">
    <p class="page-title">Profile</p>
    
    <div v-if="isLoggedIn" class="profile-content">
      <!-- User Information Section -->
      <div class="user-info-section">
        <div class="user-header">
          <div class="avatar-container">
            <div class="avatar-circle">{{ walletAddress.slice(0, 2) }}</div>
          </div>
          <div class="user-details">
            <h2 class="user-name">User: {{ walletAddress }}</h2>
            <span class="user-level" @click="openLevelUpModal">LV {{ userLevel.level }} <span v-if="userLevel.level < 3" class="level-tip">(Click to upgrade)</span></span>
            <div class="wallet-address">Wallet Address: {{ walletAddress }}</div>
            <div class="register-time">Upgrade Time: {{ userLevel.points }}</div>
          </div>
          <div class="user-stats">
            <div class="stat-card green-bg">
              <div class="stat-number">{{ evaluationCount }} entries</div>
              <div class="stat-label">Total Reviews</div>
            </div>
            <div class="stat-card blue-bg">
              <div class="stat-number">{{ tokenBalance }} Token</div>
              <div class="stat-label">Current Token Balance</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Tab Switching - Using Arco UI's Tabs Component -->
      <div class="tab-section">
        <a-tabs v-model:active-key="activeTab" class="profile-tabs">
          <a-tab-pane key="evaluation">
            <template #title>
              <div class="tab-title">
                <icon-calendar/>Review History
              </div>
            </template>
            <!-- Review History Content -->
            <div class="tab-content">
              <!-- Filter Tags -->
              <div class="filter-tags">
                <span class="filter-tag" :class="{'active': activeFilter === 'all'}" @click="reviewReward('all')">All</span>
                <span class="filter-tag" :class="{'active': activeFilter === 'accepted'}" @click="reviewReward('accepted')">Accepted</span>
                <span class="filter-tag" :class="{'active': activeFilter === 'pending'}" @click="reviewReward('pending')">Pending</span>
                <span class="filter-tag" :class="{'active': activeFilter === 'rejected'}" @click="reviewReward('rejected')">Rejected</span>
              </div>

              <!-- Review List -->
              <div class="evaluation-list">
                <div v-for="evaluation in evaluations" :key="evaluation.id" @click="openEvaluationModal(evaluation)" class="evaluation-item">
                  <div class="evaluation-header">
                    <h4 class="destination-name">{{ evaluation.name }}</h4>
                    <div class="evaluation-time">{{ evaluation.formattedTimestamp }}</div>
                  </div>
                  <div class="hash-section" v-if="evaluation.status != 0 && !evaluation.txHash.includes('0x00000000000')">
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

              <!-- Pagination Controls - Using Arco UI's Pagination Component -->
              <div class="pagination-container">
                <a-pagination 
                  :total="total" 
                  :current="current" 
                  :page-size="pageSize" 
                  show-total
                  @change="handlePageChange"
                />
              </div>
            </div>
          </a-tab-pane>
          <a-tab-pane key="token">
            <template #title>
              <div class="tab-title">
                <icon-clock-circle/>Token Records
              </div>
            </template>
            <!-- Token Records Content -->
            <div class="tab-content">
              <!-- Filter Tags -->
              <div class="filter-tags">
                <span class="filter-tag" :class="{'active': activeTokenFilter === 'all'}" @click="reviewToken('all')">All</span>
                <span class="filter-tag" :class="{'active': activeTokenFilter === 'WITHDRAW'}" @click="reviewToken('WITHDRAW')">Income</span>
                <span class="filter-tag" :class="{'active': activeTokenFilter === 'CONSUME'}" @click="reviewToken('CONSUME')">Expense</span>
              </div>

              <!-- Token Records List -->
              <div class="token-list">
                <div v-for="token in tokens" :key="token.id" class="token-item">
                  <div class="token-icon" :class="{'green-icon': token.action == 'WITHDRAW', 'orange-icon': token.action != 'WITHDRAW'}">
                    <!-- Income Icon -->
                    <template v-if="token.action === 'WITHDRAW'">
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 2L2 7V17L12 22L22 17V7L12 2Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M5 12H12V19L19 14" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M16 6V4C16 3.46957 15.7893 2.96086 15.4142 2.58579C15.0391 2.21071 14.5304 2 14 2H10C9.46957 2 8.96086 2.21071 8.58579 2.58579C8.21071 2.96086 8 3.46957 8 4V6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                      </svg>
                    </template>
                    <!-- Expense Icon -->
                    <template v-else>
                      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M12 1L2 6V16L12 21L22 16V6L12 1Z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M12 17V12M12 12L9 9M12 12L15 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M5 7H19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
                      </svg>
                    </template>
                  </div>
                  <div class="token-content">
                    <div class="token-title">{{ token.description }}</div>
                    <div class="token-info">
                      <span class="token-time">{{ token.timestamp }}</span>
                      <span class="token-address">{{ token.from }}</span>
                    </div>
                  </div>
                  <div class="token-amount" :class="{'income': token.action == 'WITHDRAW', 'expense': token.action != 'WITHDRAW'}">
                    {{ token.action === 'WITHDRAW' ? '+' : '-' }}{{ token.amount }}
                  </div>
                </div>
              </div>
              <!-- Pagination Controls - Using Arco UI's Pagination Component -->
              <div class="pagination-container">
                <a-pagination 
                  :total="total" 
                  :current="current" 
                  :page-size="pageSize" 
                  show-total 
                  @change="handlePageChange"
                />
              </div>
            </div>
          </a-tab-pane>
        </a-tabs>
      </div>
    </div>

    <!-- Not Logged In Prompt -->
    <div v-else class="login-prompt">
      <p>Please connect your wallet to access profile features.</p>
    </div>
  </div>
    
    <!-- Level Upgrade Modal - Using Arco UI's Modal Component -->
    <a-modal
      v-model:visible="showLevelUpModal"
      title="Level Upgrade"
      width="720px"
      class="level-up-modal"
      :footer="null"
    >
      <div class="level-up-content">
        <div class="level-comparison">
          <div class="level-card current-level">
            <div class="level-badge">{{ userLevel.level }}</div>
            <div class="level-title">Current Level</div>
            <div class="reward-info">Reward per review: <span class="reward-value">{{ userReviewReward }} Token</span></div>
          </div>
          
          <div class="arrow">→</div>
          
          <div class="level-card next-level">
            <div class="level-badge">{{ userLevel.nextLevel }}</div>
            <div class="level-title">Next Level</div>
            <div class="reward-info">Reward per review: <span class="reward-value">{{ requiredToken.reviewReward }} Token</span></div>
          </div>
        </div>
        
        <div class="upgrade-requirements">
          <div class="token-requirement">
            <p class="requirements-title">Upgrade Cost</p>
            <div class="required-tokens-amount">{{ requiredToken.requiredToken }} Token</div>
            <div class="current-tokens-info">Current Balance: {{ tokenBalance }} Token</div>
          </div>
        </div>
      </div>
      
      <div class="modal-footer-buttons">
        <a-button size="large" :loading="subloading" long shape="round" type="primary" @click="confirmUpgrade">Confirm Upgrade</a-button>
        <a-button size="large" :disabled="subloading" long shape="round" @click="closeLevelUpModal">Cancel</a-button>
      </div>
    </a-modal>

     <!-- Review Detail Modal -->
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
          <a-input v-model="walletAddress" disabled />
        </div>
        <div class="form-section" v-if="userData.status != 0 && userData.txHash && !userData.txHash.includes('0x00000000000')">
          <div class="section-label">hash:</div>
          <a-input v-model="userData.txHash" disabled />
        </div>
        <div class="form-section">
          <div class="section-label">Destination:</div>
          <a-input v-model="userData.name" disabled />
        </div>
        <div class="form-section">
          <div class="section-label">Review Content:</div>
          <a-textarea v-model="userData.content" disabled max-length="200"/>
        </div>
        <div class="form-section">
          <div class="section-label">Rating:</div>
          <a-rate v-model="userData.rating" allow-half readonly/>
        </div>
        <div class="form-section">
          <div class="section-label">Review Tags:</div>
          <div class="tags-container">
            <a-tag
              v-for="tag in userData.tags"
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
          <a-input v-model="userData.formattedTimestamp" disabled />
        </div>
         <div class="form-section">
          <div class="section-label">Review Status:</div>
          <a-tag :color="userData.statusTagsColor">{{ userData.statusText }}</a-tag>
          <span v-if="userData.status === 1" class="token-reward">💰 +{{ userData.rewardAmount }}</span>
        </div>
      </div>
    </a-modal>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import { useWalletStore } from '../stores/wallet';
import { EthereumService } from '../services/ethereum';
import { Message } from '@arco-design/web-vue';

const ethereumService = new EthereumService()
const walletStore = useWalletStore()
const activeTokenFilter = ref('all')
// Currently active tab
const activeTab = ref('evaluation')
// Currently active filter criteria
const activeFilter = ref('all')
// Pagination related state
const current = ref(1)
const pageSize = ref(8)
const total = ref(0)
const evaluationCount = ref(0)
const userData = ref({})
const userLevel = ref({})
const requiredToken = ref(0)
const evaluationModalVisible = ref(false)
const subloading = ref(false)
// Review data array
const evaluations = ref([])
const evaluationsList = ref([])
const tokenBalance = ref(0)
// Token record data array
const tokens = ref([])
const tokensList = ref([])
const userReviewReward = ref(0)
// Level upgrade modal related state
const showLevelUpModal = ref(false)

// Login status
const isLoggedIn = computed(() => {
  // Get data through contract
  getHistoricalReviews();
  getTokenBalance();
  getUserLevelInfo();
 
  return walletStore.ethereumAddress
})
// Get review records
const getHistoricalReviews = async () => {
  try {
    const list = await ethereumService.getScenicSpotList(); 

    // Use ethereumService encapsulated method to get review records
    evaluationsList.value = await ethereumService.getUserReviews(walletStore.ethereumAddress);
    
    evaluationsList.value.forEach(item => {
      item.name = list.find(spot => spot.scenicId === item.scenicId)?.name || '';
    });
    evaluationsList.value.reverse()
    evaluationCount.value = evaluationsList.value.length;
    handlePageChange(1,evaluationsList.value)
  } catch (error) {
    console.error(error);
    throw error;
  }
}
// Get user token transaction records
const getUserTransactions = async () => {
  try {    
    if (walletStore.ethereumAddress) {
      // Use ethereumService encapsulated method to get transaction records
      const userAddress = walletStore.ethereumAddress;
      const start = 0;
      const end = 100;
      tokensList.value = await ethereumService.getUserTransactions(userAddress, start, end);
      tokensList.value.reverse()
    }
    handlePageChange(1,tokensList.value)
  } catch (error) {
    console.error(error)
  }
};

// Get current token balance
const getTokenBalance = async () => {
  try {
    // Call getTokenBalance method to get token balance
    const balance = await ethereumService.getTokenBalance(walletStore.ethereumAddress);
    tokenBalance.value = balance;
  } catch (error) {
    console.error(error);
    throw error;
  }
};
// Get user level information
const getUserLevelInfo = async () => {
  try {
    // Call getUserLevelInfo method to get user level information
    const levelInfo = await ethereumService.getUserLevelInfo(walletStore.ethereumAddress);    
    userLevel.value = levelInfo;
    
  } catch (error) {
    console.error(error);
    throw error;
  }
};
// Open review details modal
const openEvaluationModal = (evaluation) => {
  evaluationModalVisible.value = true
  userData.value = evaluation
}
// Close review details modal
const closeEvaluationModal = () => {
  evaluationModalVisible.value = false
}
// Wallet address, show first 8 and last 4 characters
const walletAddress = computed(() => {
  const address = walletStore.ethereumAddress || walletStore.solanaAddress || ''
  if (address.length > 12) {
    return address.substring(0, 8) + '...' + address.substring(address.length - 4)
  }
  return address
})

// Listen for activeTab changes
watch(activeTab, async(newVal, oldVal) => {
  if (newVal !== oldVal) {
    current.value = 1
    activeFilter.value = 'all'
    activeTokenFilter.value = 'all'
    // When switching to review records, get review records
    if (newVal === 'evaluation' && walletStore.ethereumConnected) {
      getHistoricalReviews()
    }
    // When switching to Token records, get Token records
    if (newVal === 'token' && walletStore.ethereumConnected) {
      getUserTransactions()
    }
  }
})
const reviewReward = (value)=>{
  if (activeFilter.value !== value) {
    activeFilter.value = value
    current.value = 1
    let data = []
    // Filter review records
    if (value === 'all') {
      data = evaluationsList.value;
    } else {
      data = evaluationsList.value.filter(item => item.statusTab === value);
    }
    handlePageChange(1,data)
  }
}

const reviewToken = (value)=>{
  if (activeTokenFilter.value !== value) {
    activeTokenFilter.value = value
    current.value = 1
    // Filter Token records
    let data = []
    if (value === 'all') {
      data = tokensList.value;
    }else {
      data = tokensList.value.filter(item => item.action === value);
    }
    handlePageChange(1,data)
  }
}

// Pagination related methods
const handlePageChange = (e,data = null) => {
  current.value = e
  // Loading data logic can be added here
  if(activeTab.value === 'evaluation') {
    // Pagination: Extract evaluations list based on current page and page size
    const start = (current.value - 1) * pageSize.value;
    const end = start + pageSize.value;
    if(data){
      evaluations.value = data.slice(start, end);
      total.value = data.length
    }else if(activeFilter.value !== 'all'){
      evaluations.value = evaluationsList.value.filter(item => item.statusTab === activeFilter.value).slice(start, end);
      total.value = evaluationsList.value.filter(item => item.statusTab === activeFilter.value).length
    }else{
      evaluations.value = evaluationsList.value.slice(start, end);
      total.value = evaluationsList.value.length
    }

  } else if (activeTab.value === 'token') {
    // Filter Token records
    // Pagination: Extract tokens list based on current page and page size
    const start = (current.value - 1) * pageSize.value;
    const end = start + pageSize.value;
    if(data){
      tokens.value = data.slice(start, end);
      total.value = data.length
    }else if(activeTokenFilter.value !== 'all'){
      tokens.value = tokensList.value.filter(item => item.action === activeTokenFilter.value).slice(start, end);
      total.value = tokensList.value.filter(item => item.action === activeTokenFilter.value).length
    }else{      
      tokens.value = tokensList.value.slice(start, end);      
      total.value = tokensList.value.length
    }
  }
}

// Open level upgrade modal
const openLevelUpModal = async() => {
  if(userLevel.value.level > 2) return
  showLevelUpModal.value = true;
  if(walletStore.ethereumConnected){
    try {
      userReviewReward.value = await ethereumService.getUserReviewReward(walletStore.ethereumAddress);
      requiredToken.value = await ethereumService.getUpgradeCost(userLevel.value.nextLevel);
    } catch (error) {
      console.error(error);
      throw error;
    }
  }
}

// Close level upgrade modal
const closeLevelUpModal = () => {
  showLevelUpModal.value = false;
}

// Confirm upgrade
const confirmUpgrade = async () => {
  try {
    // Create contract instance directly using ethers
    // Ensure window.ethereum exists
    if (!window.ethereum) {
      throw new Error('Please install MetaMask or another Ethereum wallet first');
    }
    subloading.value = true
    
    // Call upgrade method
    await ethereumService.upgradeUserLevel(requiredToken.value.requiredToken);
    Message.success('Upgrade successful');
    subloading.value = false
    // Close modal
    closeLevelUpModal();
    // Refresh user token balance
    getTokenBalance()
    // Refresh user review records
    getHistoricalReviews()
    // Refresh user level information
    getUserLevelInfo()
  } catch (error) {
    Message.error('Upgrade failed, please try again later');
    console.error(error);
    subloading.value = false
  }
}
</script>

<style scoped>
.profile-container {
  max-width: 1440px;
  margin: 0 auto;
}

.page-title {
  font-size: 20px;
  font-weight: 700;
  margin: 0;
  margin-bottom: 20px;
  color: #1a1a1a;
  padding-left: 10px;
  border-left: 4px solid #1890ff;
}

/* User information area styles */
.user-info-section {
  padding: 24px;
  border-bottom: 1px solid #f0f0f0;
  background-color: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.user-header {
  display: flex;
  align-items: center;
  gap: 24px;
}

.avatar-circle {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  background-color: #1890ff;
  color: white;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 32px;
  font-weight: bold;
}

.user-details {
  flex: 1;
}

.user-name {
  font-size: 20px;
  font-weight: 600;
  color: #333;
  margin: 0 0 8px 0;
}

.user-level {
  display: inline-block;
  background-color: #ff9800;
  color: #fff;
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  margin-right: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.user-level:hover {
  background-color: #ffb74d;
  transform: translateY(-1px);
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
}

.level-tip {
  color: #fff;
  font-size: 12px;
}

.wallet-address,
.register-time {
  color: #666;
  font-size: 14px;
  margin: 6px 0;
}

.user-stats {
  display: flex;
  width: 60%;
  gap: 16px;
}

.stat-card {
  padding: 16px 32px;
  border-radius: 8px;
  color: white;
  text-align: center;
}

.green-bg {
  width: 50%;
  border: 1px solid #52c41a;
  border-left: 5px solid #52c41a;
  background-color: #fff;
  color: #52c41a;
}

.blue-bg {
  width: 50%;
  border: 1px solid #1890ff;
  border-left: 5px solid #1890ff;
  background-color: #fff;
  color: #1890ff;
}

.stat-number {
  font-size: 24px;
  font-weight: 600;
  margin-bottom: 4px;
}

.stat-label {
  color:#000;
  font-size: 14px;
}

/* Tab area styles - Arco UI Tabs customization */
.tab-section {
  margin-top: 20px;
}

.profile-tabs :deep(.arco-tabs-nav-item) {
  font-size: 16px;
  padding: 16px 24px;
}

.profile-tabs :deep(.arco-tabs-nav-item-active) {
  color: #1890ff;
}

.profile-tabs :deep(.arco-tabs-ink-bar) {
  background-color: #1890ff;
  height: 2px;
}

.tab-content {
  margin: 12px 0 24px 0;
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
  transition: box-shadow 0.3s ease;
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


.token-reward {
  color: #52c41a;
  font-weight: 600;
  font-size: 14px;
}

/* Token records styles */
.token-list {
  padding: 0 24px;
}

.token-item {
  display: flex;
  align-items: center;
  padding: 16px;
  border: 1px solid #d7d7d7;
  border-radius: 8px;
  margin: 15px 0;
}
.token-item:hover {
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}
.token-icon {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  display: flex;
  justify-content: center;
  align-items: center;
  margin-right: 16px;
  flex-shrink: 0;
}

.green-icon {
  background-color: #f6ffed;
  color: #52c41a;
}

.orange-icon {
  background-color: #fff7e6;
  color: #fa8c16;
}

.token-content {
  flex: 1;
  min-width: 0;
}

.token-title {
  font-size: 16px;
  font-weight: 500;
  color: #333;
  margin-bottom: 8px;
}

.token-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.token-time {
  font-size: 12px;
  color: #999;
}

.token-address {
  font-size: 12px;
  color: #999;
  font-family: monospace;
}

.token-amount {
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 600;
  font-size: 16px;
}

.token-amount.income {
  color: #52c41a;
}

.token-amount.expense {
  color: #fa8c16;
}

/* Pagination styles */
.pagination-container {
  padding: 24px;
  display: flex;
  justify-content: flex-end;
  border-top: 1px solid #f0f0f0;
}

/* Empty state styles */
.empty-state {
  padding: 60px 24px;
  text-align: center;
  color: #999;
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
}

.hash-label {
  font-weight: 500;
  margin-right: 8px;
}

.hash-value {
  font-family: monospace;
}

/* Not logged in prompt styles */
.login-prompt {
  background: #fff;
  border-radius: 8px;
  padding: 60px 24px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
  min-height: 400px;
}

.login-prompt p {
  font-size: 16px;
  color: #666;
  margin-bottom: 24px;
}

.login-prompt button {
  background-color: #1890ff;
  color: white;
  border: none;
  padding: 12px 24px;
  border-radius: 4px;
  font-size: 16px;
  cursor: pointer;
  transition: background-color 0.3s;
}

.login-prompt button:hover {
  background-color: #40a9ff;
}
/* Review details modal styles */
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
/* Responsive design */
@media (max-width: 768px) {
  .user-header {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .user-stats {
    width: 100%;
    justify-content: space-between;
  }
  
  .stat-card {
    flex: 1;
    padding: 12px 16px;
  }
  
  .evaluation-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }
  
  .filter-tags {
    flex-wrap: wrap;
  }
  
  .pagination-container {
    padding: 16px;
  }
}

/* Level upgrade modal styles */
.level-up-modal :deep(.arco-modal-header) {
  border-bottom: none;
}

.level-up-modal :deep(.arco-modal-footer) {
  border-top: none;
  padding-top: 0;
}

.level-up-content {
  padding: 20px 0;
}

.level-comparison {
  display: flex;
  justify-content: space-around;
  align-items: center;
  margin-bottom: 30px;
}

.level-card {
  width: 200px;
  padding: 16px;
  text-align: center;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.current-level {
  background-color: #fff7e6;
  border: 1px solid #ffc53d;
}

.next-level {
  background-color: #f6ffed;
  border: 1px solid #52c41a;
}

.level-badge {
  font-size: 36px;
  font-weight: 700;
  margin-bottom: 8px;
}

.current-level .level-badge {
  color: #ff9800;
}

.next-level .level-badge {
  color: #52c41a;
}

.level-title {
  font-size: 14px;
  color: #666;
  margin-bottom: 8px;
}

.reward-info {
  font-size: 14px;
  color: #666;
}

.reward-value {
  font-weight: 600;
  color: #1890ff;
}

.arrow {
  font-size: 32px;
  color: #d9d9d9;
}

.upgrade-requirements {
  display: flex;
  justify-content: space-around;
  align-items: center;
  text-align: center;
}

.requirements-title {
  color: #999;
}
.required-tokens-amount{
  font-size: 30px;
  font-weight: 600;
  color: #ffa940;
}
.token-requirement {
  background-color: #fafafa;
  padding: 16px;
  border-radius: 8px;
}

/* Modal button container styles */
.modal-footer-buttons {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 20px;
}

.token-progress-container {
  height: 8px;
  background-color: #e8e8e8;
  border-radius: 4px;
  margin-bottom: 12px;
  overflow: hidden;
}

.token-progress-bar {
  height: 100%;
  background-color: #52c41a;
  border-radius: 4px;
}

.token-amounts {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.current-tokens {
  font-size: 18px;
  font-weight: 600;
  color: #52c41a;
}

.separator {
  color: #999;
}

.required-tokens {
  font-size: 16px;
  color: #666;
}

.upgrade-benefits {
  margin-bottom: 20px;
}

.benefits-title {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin-bottom: 12px;
}

.benefits-list {
  list-style: none;
  padding: 0;
  margin: 0;
}

.benefits-list li {
  padding: 8px 0 8px 20px;
  position: relative;
  color: #666;
  font-size: 14px;
}

.benefits-list li::before {
  content: "✓";
  position: absolute;
  left: 0;
  color: #52c41a;
  font-weight: 600;
}
</style>

<style lang="less" scoped>
.tab-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 16px;
}
/deep/ .arco-tabs-content{
  padding: 0;
}
/deep/.arco-input[disabled] {
    background-color: #f5f5f5;
    cursor: not-allowed;
    color: #000;
    -webkit-text-fill-color: #000;
  }
</style>

