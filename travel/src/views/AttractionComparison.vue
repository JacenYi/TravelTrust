<template>
  <div class="comparison-container" v-if="isWalletConnected">
    <!-- Page title -->
    <div class="page-header">
      <h1 class="page-title">Attraction Comparison</h1>
    </div>

    <!-- Select comparison attractions area -->
    <div class="selection-section">
      <div class="selection-controls">
        <select class="attraction-select" v-model="selectedAttraction1">
          <option v-for="spot in scenicSpotList" :key="spot.scenicId" :disabled="selectedAttraction2 === spot.scenicId" :value="spot.scenicId">{{ spot.name }}</option>
        </select>
        
        <span class="vs-label">VS</span>
        
        <select class="attraction-select" v-model="selectedAttraction2">
          <option v-for="spot in scenicSpotList" :key="spot.scenicId" :disabled="selectedAttraction1 === spot.scenicId" :value="spot.scenicId">{{ spot.name }}</option>
        </select>
      </div>
      <button class="compare-btn primary-btn" @click="performComparison">Compare Attractions</button>
    </div>

    <!-- Attraction details cards area -->
    <div v-if="isPayment" class="attraction-cards">
      <!-- Attraction card -->
      <div class="attraction-card">
        <div class="card-header">
          <h2 class="attraction-name">{{ spot1.name }}</h2>
          <!-- Tags Section -->
          <div class="destination-tags">
            <a-tag v-for="tag in spot1.tags" :key="tag" class="tag" type="primary" color="blue">{{ tag }}</a-tag>
          </div>
        </div>
        <!-- Description -->
        <div class="destination-text">
          <p>{{ spot1.description }}</p>
        </div>
        <div class="card-info">
          <div class="info-item">
            <span class="info-label">Location</span>
            <span class="info-value">{{ spot1.location }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Attraction Rating</span>
            <span class="info-value">{{ spot1.overall_rating ? spot1.overall_rating + '/ 10.0' : '' }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Summary Update Time</span>
            <span class="info-value">{{ spot1.timestamp }}</span>
          </div>
        </div>
        
        <!-- AI review summary -->
        <div class="ai-summary-section">
          <div class="summary-header">
            <p class="summary-title">AI Review Summary</p>
            <p class="hash-tag">Summary ID: {{ spot1.txHash }}</p>
          </div>
          <div class="destination-comment">
            {{ spot1.core_feedback_summary ? spot1.core_feedback_summary : '' }}
          </div>
        </div>
      </div>

      <!-- Second attraction card -->
      <div class="attraction-card">
        <div class="card-header">
          <h2 class="attraction-name">{{ spot2.name }}</h2>
          <!-- Tags section -->
          <div class="destination-tags">
            <a-tag v-for="tag in spot2.tags" :key="tag" class="tag" type="primary" color="blue">{{ tag }}</a-tag>
          </div>
        </div>
        <!-- Description content -->
        <div class="destination-text">
          <p>{{ spot2.description }}</p>
        </div>
        <div class="card-info">
          <div class="info-item">
            <span class="info-label">Location</span>
            <span class="info-value">{{ spot2.location }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Attraction Rating</span>
            <span class="info-value">{{ spot2.overall_rating ? spot2.overall_rating + '/ 10.0' : '' }}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Summary Update Time</span>
            <span class="info-value">{{ spot2.timestamp }}</span>
          </div>
        </div>
        
        <!-- AI review summary -->
        <div class="ai-summary-section">
          <div class="summary-header">
            <p class="summary-title">AI Review Summary</p>
            <p class="hash-tag">Summary ID: {{ spot2.txHash ? spot2.txHash : '' }}</p>
          </div>
          <div class="destination-comment">
            {{ spot2.core_feedback_summary ? spot2.core_feedback_summary : '' }}
          </div>
        </div>
      </div>

    </div>

    <!-- Comparison table area -->
    <div v-if="isPayment" class="comparison-table-section">
      <table class="comparison-table">
        <thead>
          <tr>
            <th class="table-header-cell">Comparison Item</th>
            <th class="table-header-cell attraction-header">{{ spot1.name }}</th>
            <th class="table-header-cell attraction-header">{{ spot2.name }}</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td class="table-cell">Overall Rating</td>
            <td class="table-cell">{{ spot1.overall_rating ? spot1.overall_rating + '/ 10.0' : '/' }} </td>
            <td class="table-cell">{{ spot2.overall_rating ? spot2.overall_rating + '/ 10.0' : '/' }}  </td>
          </tr>
          <tr>
            <td class="table-cell">Positive Review Rate</td>
            <td class="table-cell">{{ spot1.positiveRating }}</td>
            <td class="table-cell">{{ spot2.positiveRating }}</td>
          </tr>
          <tr>
            <td class="table-cell">Geographic Location</td>
            <td class="table-cell">{{ spot1.location_rating }}</td>
            <td class="table-cell">{{ spot2.location_rating }}</td>
          </tr>
          <tr>
            <td class="table-cell">Crowd Level</td>
            <td class="table-cell">{{ spot1.crowd_level }}</td>
            <td class="table-cell">{{ spot2.crowd_level }}</td>
          </tr>
          <tr>
            <td class="table-cell">Best Season</td>
            <td class="table-cell">{{ spot1.best_season }}</td>
            <td class="table-cell">{{ spot2.best_season }}</td>
          </tr>
          <tr>
            <td class="table-cell">Suitable For</td>
            <td class="table-cell">{{ spot1.suitable_people }}</td>
            <td class="table-cell">{{ spot2.suitable_people }}</td>
          </tr>
          <tr>
            <td class="table-cell">Price Level</td>
            <td class="table-cell">{{ spot1.price_level }}</td>
            <td class="table-cell">{{ spot2.price_level }}</td>
          </tr>
          <tr>
            <td class="table-cell">Recommended Duration</td>
            <td class="table-cell">{{ spot1.suggested_duration }}</td>
            <td class="table-cell">{{ spot2.suggested_duration }}</td>
          </tr>
          <tr>
            <td class="table-cell">Transportation Convenience</td>
            <td class="table-cell">{{ spot1.traffic_convenience }}</td>
            <td class="table-cell">{{ spot2.traffic_convenience }}</td>
          </tr>
        </tbody>
      </table>
      
      <!-- Action Buttons -->
      <div class="action-buttons">
        <button class="pdf-btn primary-btn" @click="saveAsPDF">Save as PDF</button>
        <button class="back-btn" @click="$router.back()">Back</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';
import { EthereumService } from '../services/ethereum';
import { useWalletStore } from '../stores/wallet';
import { Message } from '@arco-design/web-vue';
import { useRouter } from 'vue-router';
const router = useRouter()

const ethereumService = new EthereumService()
const walletStore = useWalletStore()
const query = router.currentRoute.value.query

// Attraction selection state
const selectedAttraction1 = ref('');
const selectedAttraction2 = ref('');
const isPayment = ref(false)
const scenicSpotList = ref([])
const spot1 = ref({
  name: '',
  location: '',
  description: '',
  tags: [],
  reviewCount: 0,
  averageRating: 0,
  active: '',
  summaryId: '',
  content: {},
  version: '',
  timestamp: '',
  reviewCount: 0,
  lastReviewIndex: '',
  txHash: ''
});
const spot2 = ref({
  name: '',
  location: '',
  description: '',
  tags: [],
  reviewCount: 0,
  averageRating: 0,
  active: '',
  summaryId: '',
  content: {},
  version: '',
  timestamp: '',
  reviewCount: 0,
  lastReviewIndex: '',
  txHash: ''

});
// Computed property: Check if wallet is connected
const isWalletConnected = computed(() => {
  if (walletStore.ethereumConnected) {
    // Get popular attractions list through contract
    getHotScenicSpots()
  }
  return walletStore.ethereumConnected
})
// Save as PDF function
const saveAsPDF = async () => {
  try {    
    // Get container to convert to PDF
    const container = document.querySelector('.comparison-container');
    
    // Get action buttons area and compare button
    const actionButtons = document.querySelector('.action-buttons');
    const compareBtn = document.querySelector('.compare-btn');
    
    // Temporarily hide action buttons and compare button
    if (actionButtons) {
      actionButtons.style.display = 'none';
    }
    if (compareBtn) {
      compareBtn.style.display = 'none';
    }
    
    // Use html2canvas to convert HTML to canvas
    const canvas = await html2canvas(container, {
      scale: 2, // Increase clarity
      useCORS: true, // Allow loading cross-origin images
      logging: false, // Disable logging
      backgroundColor: '#ffffff' // Set background color to white
    });
    
    // Restore action buttons and compare button display
    if (actionButtons) {
      actionButtons.style.display = 'flex';
    }
    if (compareBtn) {
      compareBtn.style.display = 'block';
    }
    
    // Calculate PDF width and height (A4 ratio)
    const imgWidth = 210;
    const pageHeight = 297;
    const imgHeight = (canvas.height * imgWidth) / canvas.width;
    let heightLeft = imgHeight;
    let position = 0;
    
    // Create PDF document
    const pdf = new jsPDF('p', 'mm', 'a4');
    const imgData = canvas.toDataURL('image/png');
    
    // Add first page
    pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
    heightLeft -= pageHeight;
    
    // If content exceeds one page, add new page
    while (heightLeft >= 0) {
      position = heightLeft - imgHeight;
      pdf.addPage();
      pdf.addImage(imgData, 'PNG', 0, position, imgWidth, imgHeight);
      heightLeft -= pageHeight;
    }
    
    // Save PDF file
    const filename = `${selectedAttraction1.value}_vs_${selectedAttraction2.value}_comparison.pdf`;
    pdf.save(filename);
    Message.success('PDF export successful');
  } catch (error) {
    Message.error('PDF export failed, please try again later');
  }
};

// Get popular attractions list through contract
const getHotScenicSpots =  async ()=> {
  try {    
    scenicSpotList.value = await ethereumService.getScenicSpotList();
    
    if(scenicSpotList.value.length > 0){      
      const queryId = Number(query.id)
      selectedAttraction1.value = queryId
      // Smart recommendation: Select first different attraction
      const recommendedSpot = scenicSpotList.value.find(spot => spot.scenicId !== queryId);
      
      if (recommendedSpot) {
        selectedAttraction2.value = recommendedSpot.scenicId;
      }else{
        selectedAttraction2.value = scenicSpotList.value[0].scenicId;
      }
      performComparison()
    }
  } catch (error) {
    throw error;
  }
}
// Perform attraction comparison
const performComparison = async () => {
  try {
    // Check if two attractions are selected
    if (!selectedAttraction1.value || !selectedAttraction2.value) {
      throw new Error('Please select two attractions for comparison');
    }
    // Check if same attraction is selected
    if (selectedAttraction1.value === selectedAttraction2.value) {
      throw new Error('Please select different attractions for comparison');
    }
    if(walletStore.ethereumConnected){
      const result = await ethereumService.compareScenicSpots(selectedAttraction1.value, selectedAttraction2.value);      
      spot1.value = result.spot1;
      spot2.value = result.spot2;
    }
    
    isPayment.value = true;
  } catch (error) {
    throw error;
  }
};
</script>

<style scoped>
.comparison-container {
  max-width: 1440px;
  margin: 0 auto;
  background-color: #f5f5f5;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
}

.page-header {
  margin-bottom: 24px;
}

.page-title {
  font-size: 24px;
  color: #333;
  margin: 0;
  padding-bottom: 8px;
  border-bottom: 2px solid #1677ff;
  inline-size: fit-content;
}

.selection-section {
  display: flex;
  justify-content: space-between;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 20px;
  margin-bottom: 24px;
}

.selection-controls {
  display: flex;
  align-items: center;
  gap: 16px;
  flex-wrap: wrap;
}

.attraction-select {
  padding: 8px 12px;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  font-size: 14px;
  background-color: white;
  min-width: 200px;
  cursor: pointer;
}

.vs-label {
  font-size: 18px;
  font-weight: bold;
  color: #666;
}

.compare-btn, .pdf-btn {
  padding: 8px 16px;
  border: none;
  border-radius: 4px;
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.3s ease;
}
.pdf-btn{
  width: 80%;
}

.primary-btn {
  background-color: #1677ff;
  color: white;
}

.primary-btn:hover {
  background-color: #4096ff;
}

.attraction-cards {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
}

.attraction-card {
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  padding: 20px;
}

.card-header .attraction-name {
  font-size: 20px;
  color: #1677ff;
  margin: 0 0 16px 0;
  font-weight: bold;
}

.card-info {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 16px;
  font-size: 14px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.info-label {
  color: #666;
}

.info-value {
  color: #333;
  font-weight: 500;
}

.ai-summary-section {
  border-radius: 6px;
}

.summary-header {
  border-bottom: 1px solid #e0f0ff;
  font-size: 13px;
}

.summary-title {
  margin: 5px 0;
  font-weight: 500;
  color: #1677ff;
  font-weight: bold;
}

.hash-tag {
  margin: 5px 0 20px 0;
  display: inline-block;
  color: #333;
  font-family: monospace;
  background-color: #d9d9d9;
  padding: 4px 8px;
  border-radius: 16px;
}

.summary-content {
  padding: 12px;
  font-size: 14px;
  line-height: 1.6;
  color: #333;
}

.comparison-table-section {
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  margin-bottom: 24px;
  padding-bottom: 20px;
  overflow: hidden;
}

.comparison-table {
  width: 100%;
  border-collapse: collapse;
}

.table-header-cell {
  background-color: #1677ff;
  color: white;
  font-weight: bold;
  padding: 12px 16px;
  text-align: left;
  font-size: 14px;
}

.attraction-header {
  background-color: #4096ff;
}

.table-cell {
  padding: 12px 16px;
  border-bottom: 1px solid #f0f0f0;
  border-right: 1px solid #f0f0f0;
  font-size: 14px;
  color: #333;
}

.comparison-table tbody tr:hover {
  background-color: #f5f5f5;
}

.action-buttons {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-top: 24px;
}

.back-btn {
  width: 15%;
  padding: 8px 16px;
  border: 1px solid #d9d9d9;
  border-radius: 4px;
  font-size: 14px;
  background-color: #f5f5f5;
  color: #333;
  cursor: pointer;
  transition: all 0.3s ease;
}

.back-btn:hover {
  border-color: #1677ff;
  color: #1677ff;
}

/* Responsive design */
@media (max-width: 768px) {
  .attraction-cards {
    grid-template-columns: 1fr;
  }
  
  .card-info {
    grid-template-columns: 1fr;
    gap: 12px;
  }
  
  .selection-controls {
    flex-direction: column;
    align-items: stretch;
  }
  
  .attraction-select {
    width: 100%;
  }
  
  .vs-label {
    text-align: center;
  }
  
  .action-buttons {
    flex-direction: column;
  }
}
/* Modal related styles */
.payment-dialog {
  width: 480px;
  border-radius: 8px;
}

.payment-message {
  font-size: 16px;
  margin-bottom: 12px;
  color: #333;
  text-align: center;
}

.payment-note {
  font-size: 14px;
  color: #666;
  text-align: center;
  margin-bottom: 0;
}

.modal-footer {
  display: flex;
  justify-content: center;
  gap: 16px;
  padding-top: 16px;
}
/* Tags styles */
.destination-tags {
  margin: 8px 0 12px 0;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.destination-text{
  color: #999;
}
.tag {
  font-size: 12px;
  background-color: #e6f4ff;
  color: #1677ff;
  border: 1px solid #91d5ff;
  padding: 2px 10px;
  border-radius: 16px;
}

/* Description content styles */
.destination-comment {
  font-size: 14px;
  color: #595959;
  line-height: 1.6;
  margin-bottom: 16px;
  padding: 12px;
  background-color: #f5f5f5;
  border-radius: 4px;
  border-left: 3px solid #1677ff;
}

.destination-comment p {
  margin: 0;
}

</style>