<template>
  <div class="exchange-container" v-if="isWalletConnected">
    <!-- Token Exchange Center Header -->
    <div class="token-header">
      <div class="token-header-content">
        <h2 class="token-title">Token Exchange Center</h2>
        <p class="token-desc">Use the Tokens you earned on the platform to exchange for various travel benefits and rewards. All exchange records are verified through blockchain to ensure transparency and trustworthiness.</p>
        <p class="token-desc">Your Tokens were earned through authentic high-quality reviews and can now be exchanged for tangible travel benefits!</p>
      </div>
      <a-button type="primary" size="large" class="token-earn-btn" @click="showEarnTokenModal">Earn Tokens by Reviewing</a-button>
    </div>

    <!-- Token Statistics Area -->
    <div class="token-stats">
      <div class="stat-item">
        <div class="stat-value blue-text">{{ tokenBalance }}</div>
        <div class="stat-label">Current Token Balance</div>
      </div>
      <div class="stat-item-container">
        <div class="stat-item">
          <div class="stat-value green-text">{{ totalEarned }}</div>
          <div class="stat-label">Total Earned</div>
        </div>
        <div class="stat-item">
          <div class="stat-value green-text">{{ totalSpent }}</div>
          <div class="stat-label">Total Spent</div>
        </div>
        <div class="stat-item">
          <div class="stat-value green-text">{{ exchangeCount }}</div>
          <div class="stat-label">Exchange Count</div>
        </div>
      </div>
    </div>

    <!-- My Coupons Section -->
    <div class="my-coupons-section" v-if="couponItems.length > 0">
      <h3 class="section-title">My Coupons</h3>
      <div class="coupons-grid">
        <!-- Use v-for to render coupon cards -->
        <div v-for="coupon in couponItems" :key="coupon.id" class="coupon-card">
          <div class="coupon-header">
            <h4 class="coupon-name">{{ coupon.name }}</h4>
            <span class="coupon-status">{{ coupon.status }}</span>
          </div>
          <p class="coupon-desc">{{ coupon.description }}</p>
          <div class="coupon-footer">
            <span class="coupon-expiry">Valid until: {{ coupon.expiryDate }}</span>
          </div>
          <a-button type="success" class="coupon-use-btn" @click="showCouponModal(coupon)">Use</a-button>
        </div>
      </div>
    </div>
    
    <!-- Exchange Center Section -->
    <div class="section-header">
      <div class="title-tabs-container">
        <h3 class="section-title">Exchange Center</h3>
        <div class="category-tabs">
          <a-tag color="tab-box" :class="{'active-tab': activeTab === 'all'}" @click="activeTab = 'all'">All</a-tag>
          <a-tag color="tab-box" :class="{'active-tab': activeTab === 'tickets'}" @click="activeTab = 'tickets'">Tickets</a-tag>
          <a-tag color="tab-box" :class="{'active-tab': activeTab === 'hotel'}" @click="activeTab = 'hotel'">Hotels</a-tag>
          <a-tag color="tab-box" :class="{'active-tab': activeTab === 'transportation'}" @click="activeTab = 'transportation'">Transportation</a-tag>
        </div>
      </div>
      <a-input-search
      v-model="searchKeyword"
      :style="{width:'280px',backgroundColor:'rgba(134, 144, 156, 0.2)',borderRadius:'20px'}"
      placeholder="Search by keyword"
      @search="fetchExchangeData"
      />
    </div>
    <div class="exchange-center-section">
      <div class="exchange-items-grid">
        <div v-for="item in exchangeItems" :key="item.id" class="exchange-item-card">
          <div class="exchange-header">
            <h4 class="exchange-name">{{ item.name }}</h4>
            <span class="limited-tag">Limited</span>
          </div>
          <p class="exchange-desc">{{ item.description }}</p>
          <div class="exchange-footer">
            <div class="token-price">
              <span class="price-text"><icon-fire /> {{ item.price }} Token</span>
            </div>
            <div class="item-info">
              <span class="stock-info">Stock: {{ item.soldCount }} / {{ item.maxSupply }}</span>
              <span class="expiry-info">Validity: {{ item.validityDays }} days</span>
            </div>
          </div>
          <a-button type="primary" class="exchange-btn" @click="showPaymentModal(item)">Exchange Now</a-button>
        </div>
      </div>
      
      <!-- Pagination Controls -->
      <div class="pagination-container">
        <a-pagination :current="currentPage" :total="total" show-total :page-size="8" @change="fetchPaginationData"/>
      </div>
    </div>
    
    <!-- Coupon Modal -->
    <coupon-modal
      v-model="showCouponModalVisible"
      :coupon-data="selectedCoupon"
      @confirm="handleCouponConfirm"
      @cancel="handleCouponCancel"
    />
    
    <!-- Payment Confirmation Modal -->
    <a-modal
      v-model:visible="showPaymentConfirm"
      :title="'Confirm Payment'"
      :width="400"
      :mask-closable="false"
      :footer="null"
    >
      <div class="payment-modal-content">
        <p class="payment-confirm-text">Are you sure you want to pay {{ selectedExchangeItem?.price || 80 }} Token to purchase this coupon?</p>
        <div class="payment-buttons">
          <a-button type="primary" :loading="subloading" shape="round" @click="handlePaymentConfirm">Confirm Payment</a-button>
          <a-button shape="round" :disabled="subloading" style="margin-left: 12px;" @click="handlePaymentCancel">Cancel</a-button>
        </div>
      </div>
    </a-modal>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue';
import CouponModal from '../components/CouponModal.vue';
import { useRouter } from 'vue-router';
import { useWalletStore } from '../stores/wallet';
import { EthereumService } from '../services/ethereum';
import { Message } from '@arco-design/web-vue';
import { ethers } from 'ethers';
const walletStore = useWalletStore();
const router = useRouter();
const ethereumService = new EthereumService()
const totalEarned = ref(0);
const totalSpent = ref(0);
const exchangeCount = ref(0);
const tokenBalance = ref(0);
// Current Page Number
const currentPage = ref(1);
const total = ref(0);
const subloading = ref(false)

// Control Coupon Modal Display
const showCouponModalVisible = ref(false);

// Currently Selected Coupon Data
const selectedCoupon = ref({});

const activeTab = ref('all');

// Search Keyword
const searchKeyword = ref('');


// Control Payment Confirmation Modal Display
const showPaymentConfirm = ref(false);

// Currently Selected Exchange Item
const selectedExchangeItem = ref(null);

// Coupon Data
const exchangeItems = ref([]);
const couponItems = ref([]);
const list = ref([])

// Computed Property: Check if Wallet is Connected
const isWalletConnected = computed(() => {  
  if(walletStore.ethereumConnected){    
    fetchData();
  }

  return walletStore.ethereumConnected
})


// Get All Data
const fetchData = async () => {  
  try {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();
   
    // Get All Exchangeable Coupons    
    list.value = await ethereumService.getAllCoupons();    

    fetchPaginationData(list.value);
    // Get User's Active Coupons
    const userAddress = await signer.getAddress();
    couponItems.value = await ethereumService.getUserActiveCoupons(userAddress);  
    
    // Get User Token Balance
    const balance = await ethereumService.getTokenBalance(userAddress);
    tokenBalance.value = balance;
    let tokensList = await ethereumService.getUserTransactions(userAddress, 0, 100);

    // Calculate Total Earned, Spent, and Exchange Count
    let earned = 0;
    let spent = 0;
    let exchangeTimes = 0;
    
    tokensList.forEach(transaction => {      
      const amount = parseFloat(transaction.amount);
      if (transaction.action === 'WITHDRAW' && (transaction.description.includes('accepted'))) {
        earned += amount;
      }
      if (transaction.action === 'CONSUME') {
        spent += amount;
      }
      if (transaction.action === 'CONSUME' && transaction.description.includes('Exchange')) {
        exchangeTimes += 1;
      }
    });
    
    totalEarned.value = earned;
    totalSpent.value = spent;
    exchangeCount.value = exchangeTimes;
  } catch (error) {
    console.error(error);
  }
};


// Search
const fetchExchangeData = async () => {
  if(activeTab.value === 'all'){
    let data = list.value.filter(item => item.name.includes(searchKeyword.value));
    fetchPaginationData(data)
  }else{
    let data = list.value.filter(item => item.name.includes(searchKeyword.value) && item.tag.includes(activeTab.value));
    fetchPaginationData(data)
  }
};
// Pagination
const fetchPaginationData = async (data = null) => {
  const start = (currentPage.value - 1) * 8;
  const end = start + 8;
  
  if(data){
    exchangeItems.value = data.slice(start, end);
  }else{
    exchangeItems.value = list.value.slice(start, end);
  }
  total.value = data === null ? list.value.length : data.length
};

// Listen for activeTab Changes and Request Corresponding Data
watch(activeTab, (newTab) => {    
  let data
  // Request Different Data Based on Selected Tab
  if (newTab === 'all') {    
    data = list.value
  } else {
    // Filter Coupons by Type
    data = list.value.filter(item => item.tag.includes(newTab));
  }
  // Reset Pagination
  currentPage.value = 1;
  fetchPaginationData(data);
}, { immediate: true });

// Show Coupon Modal
const showCouponModal = (coupon) => {  
  selectedCoupon.value = coupon;
  showCouponModalVisible.value = true;
};

// Handle Coupon Confirmation
const handleCouponConfirm = () => {
  showCouponModalVisible.value = false;
  fetchData();
};

// Handle Coupon Cancellation
const handleCouponCancel = () => {
  showCouponModalVisible.value = false;
};

// Show Payment Confirmation Modal
const showPaymentModal = (item) => {
  selectedExchangeItem.value = item;
  showPaymentConfirm.value = true;
};

// Purchase Coupon
const handlePaymentConfirm = async () => {
  if (!selectedExchangeItem.value) {
    return;
  }
  subloading.value = true
  try {    
    // Call purchaseCoupon method to buy coupon
    await ethereumService.purchaseCoupon(
      parseInt(selectedExchangeItem.value.id),
      selectedExchangeItem.value.price
    );
    
    // Refresh data
    await fetchData();
    // Close modal
    Message.success('Purchase successful');
    showPaymentConfirm.value = false;
    subloading.value = false
  } catch (error) {
    subloading.value = false
    Message.error('Purchase failed, please try again later');
  }
};

// Handle payment cancellation
const handlePaymentCancel = () => {
  showPaymentConfirm.value = false;
};

// Navigate to Review Page
const showEarnTokenModal = ()=>{
  router.push('/review')
}

</script>

<style scoped>
.exchange-container {
  max-width: 1440px;
  padding-bottom:24px;
  margin: 0 auto;
}

/* Token Header Styles */
.token-header {
  background-color: #e1f3ff;
  border-radius: 8px;
  padding: 0 24px;
  margin-bottom: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.token-header-content {
  flex: 1;
}

.token-title {
  font-size: 24px;
  font-weight: 600;
  color: #0050b3;
  margin-bottom: 8px;
}

.token-desc {
  color: #333;
}

.token-earn-btn {
  background-color: #096dd9;
  color: white;
  border: none;
  padding: 10px 24px;
  border-radius: 4px;
  font-weight: 500;
  cursor: pointer;
}

/* Token Statistics Styles */
.token-stats {
  background-color: white;
  border-radius: 8px;
  padding: 24px;
  margin-bottom: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  font-size: 28px;
}
.stat-item-container{
  font-size: 20px;
  width: 40%;
  display: flex;
  justify-content: space-around;
  align-items: center;
}
.stat-item {
  text-align: center;
}

.stat-value {
  
  font-weight: 600;
  margin-bottom: 8px;
}

.blue-text {
  color: #1890ff;
}

.green-text {
  color: #52c41a;
}

.stat-label {
  color: #666;
  font-size: 14px;
}

/* Section Title Styles */
.section-title {
  font-size: 20px;
  font-weight: 600;
  color: #333;
  padding-left: 10px;
  border-left: 5px solid #1677ff;
}

/* Coupon Styles */
.my-coupons-section {
  margin-bottom: 32px;
}

.coupons-grid {
  height: 240px;
  overflow: auto;
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.coupon-card {
  background-color: white;
  border-radius: 8px;
  padding: 16px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  transition: box-shadow 0.3s;
}

.coupon-card:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.coupon-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.coupon-name {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin: 0;
}

.coupon-status {
  color: #52c41a;
  font-size: 12px;
  background-color: #f6ffed;
  padding: 2px 8px;
  border-radius: 4px;
}

.coupon-desc {
  color: #666;
  font-size: 14px;
  margin-bottom: 40px;
}

.coupon-footer {
  margin-bottom: 16px;
  padding-top: 40px;
  border-top: 1px solid #f0f0f0;
}

.coupon-expiry {
  color: #999;
  font-size: 12px;
  display: flex;
  align-items: center;
}

.coupon-expiry::before {
  content: "📅";
  margin-right: 4px;
}

.coupon-use-btn {
  width: 100%;
  background-color: #52c41a;
  color: white;
  border: none;
  padding: 8px;
  border-radius: 4px;
  cursor: pointer;
}

/* Exchange Center Styles */
.exchange-center-section {
  border-radius: 8px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.title-tabs-container{
  display: flex;
  align-items: center;
}
.category-tabs {
  display: flex;
  gap: 8px;
  margin: 0 24px;
}

.active-tab {
  /* width: 60px; */
  height: 28px;
  border-radius: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background-color: #e6f4ff;
  color: #1890ff;
  border: 1px solid #91d5ff;
}

.exchange-items-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.exchange-item-card {
  background-color: white;
  border: 1px solid #f0f0f0;
  border-radius: 8px;
  padding: 16px;
  transition: box-shadow 0.3s;
}

.exchange-item-card:hover {
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.1);
}

.exchange-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.exchange-name {
  font-size: 16px;
  font-weight: 600;
  color: #333;
  margin: 0;
}

.limited-tag {
  color: #fa8c16;
  font-size: 12px;
  background-color: #fff7e6;
  padding: 2px 8px;
  border-radius: 4px;
}

.exchange-desc {
  color: #666;
  font-size: 14px;
  margin-bottom: 12px;
}

.exchange-footer {
  margin-bottom: 16px;
  margin-top: 60px;
}

.token-price {
  display: flex;
  align-items: center;
  color: #fa8c16;
  font-weight: 600;
  margin-bottom: 8px;
  font-size: 20px;
}

.token-icon {
  margin-right: 4px;
}

.item-info {
  display: flex;
  gap: 16px;
}

.stock-info, .expiry-info {
  color: #999;
  font-size: 12px;
  display: flex;
  align-items: center;
}

.stock-info::before {
  content: "📦";
  margin-right: 4px;
}

.expiry-info::before {
  content: "📅";
  margin-right: 4px;
}

.exchange-btn {
  width: 100%;
  background-color: #1890ff;
  color: white;
  border: none;
  padding: 8px;
  border-radius: 4px;
  cursor: pointer;
}

/* Pagination Styles */
.pagination-container {
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 16px;
}

.page-info {
  color: #666;
  font-size: 14px;
}
.payment-modal-content{
  text-align: center;
}
/* Responsive Design */
@media (max-width: 768px) {
  .token-header {
    flex-direction: column;
    align-items: flex-start;
  }
  
  .token-earn-btn {
    margin-top: 16px;
    align-self: flex-end;
  }
  
  .token-stats {
    flex-wrap: wrap;
    gap: 16px;
  }
  
  .stat-item {
    flex: 1 1 45%;
  }
  
  .coupons-grid,
  .exchange-items-grid {
    grid-template-columns: 1fr;
  }
  
  .section-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }
  
  .category-tabs {
    margin: 0;
    flex-wrap: wrap;
  }
  
  .pagination-container {
    justify-content: center;
  }
}
</style>
<style lang="less" scoped>
  /deep/ .arco-tag.arco-tag-custom-color{
    color: #000;
  }
  /deep/ .arco-tag-size-medium{
    padding: 0 12px;
    height: 28px;
    border-radius: 28px;
    background-color: #fff;
    color: #000;
    display: flex;
    align-items: center;
    justify-content: center;
  }
  /deep/ .arco-tag-size-medium:hover{
    background-color: #e6f4ff;
    color: #1890ff;
    border: 1px solid #91d5ff;
  }
  /deep/ .arco-tag-size-medium.active-tab{
    background-color: #1677ff;
    color: #fff;
    border: 1px solid #91d5ff;
  }
</style>


