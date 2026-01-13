<template>
  <div class="docs-container">
    <!-- Hero Section -->
    <div class="hero-section">
      <h1 class="hero-title">Trusted Attractions AI Summary Data API</h1>
      <div class="hero-subtitle">
        Access blockchain-verified AI attraction summary data through Oracle services, enhancing your application with trusted travel intelligence
      </div>
      <div class="hero-actions">
        <button class="action-btn primary-btn">View Integration Documentation</button>
      </div>
    </div>

    <!-- Features Section -->
    <div class="features-section">
      <div class="feature-card">
        <div class="feature-icon shield-icon"><icon-common /></div>
        <h3 class="feature-title">Blockchain Trust Verification</h3>
        <p class="feature-description">
          All AI summaries are stored on-chain through Oracle services, ensuring data immutability and verifiability.
        </p>
      </div>

      <div class="feature-card">
        <div class="feature-icon brain-icon"><icon-bug /></div>
        <h3 class="feature-title">AI Intelligent Summaries</h3>
        <p class="feature-description">
          Extract core insights from massive reviews, generating concise and trustworthy summaries to save your valuable time.
        </p>
      </div>

      <div class="feature-card">
        <div class="feature-icon token-icon"><icon-sun-fill /></div>
        <h3 class="feature-title">Token Economic Incentives</h3>
        <p class="feature-description">
          Contribute high-quality reviews to earn Token rewards, consume Tokens to unlock premium features and level up.
        </p>
      </div>
    </div>

    <!-- Data Display Area -->
    <div class="data-section">
      <!-- Hash Section -->
      <div class="hash-section">
        <span class="hash-label">Hash:</span>
        <span class="hash-value">0z31D1X831D1X831D1X831D1X8</span>
      </div>
      
      <!-- Attraction Review Example -->
      <div class="evaluation-card">
        <div class="evaluation-content">
          Recent visitors widely report that Huangshan Mountain offers stunning scenery, with particularly magnificent cloud sea views. However, wait times are longer on weekends, so weekdays are recommended. Some sections of the Xihai Grand Canyon trail are steep, so caution is advised.
        </div>
      </div>
      
      <!-- Statistics Cards -->
      <div class="stats-cards">
        <div class="stat-card">
          <div class="stat-number blue">32</div>
          <div class="stat-label">Positive Reviews</div>
        </div>
        <div class="stat-card">
          <div class="stat-number orange">21</div>
          <div class="stat-label">Neutral Reviews</div>
        </div>
        <div class="stat-card">
          <div class="stat-number red">4</div>
          <div class="stat-label">Negative Reviews</div>
        </div>
      </div>
      
      <!-- Popular Tags -->
      <div class="tags-section">
        <div class="section-title-sm">Popular Tags</div>
        <div class="tags-list">
          <div class="tag">Beautiful Scenery</div>
          <div class="tag">Convenient Transportation</div>
          <div class="tag">Reasonable Price</div>
          <div class="tag">Well-equipped Facilities</div>
          <div class="tag">Short Queue Times</div>
          <div class="tag">Warm Service</div>
        </div>
      </div>
      
      <!-- Detailed Analysis Table -->
      <div class="analysis-table">
        <div class="section-title-sm">Detailed Analysis</div>
        <div class="table-content">
          <div class="table-row">
            <div class="table-cell title">Overall Rating</div>
            <div class="table-cell">8.0 / 10.0</div>
            <div class="table-cell title">Location</div>
            <div class="table-cell">Anhui, China</div>
          </div>
          <div class="table-row">
            <div class="table-cell title">Crowdedness Level</div>
            <div class="table-cell">Medium</div>
            <div class="table-cell title">Best Season</div>
            <div class="table-cell">Spring and Autumn</div>
          </div>
          <div class="table-row">
            <div class="table-cell title">Suitable For</div>
            <div class="table-cell">Nature Lovers, Photographers, Hiking Enthusiasts</div>
            <div class="table-cell title">Price Level</div>
            <div class="table-cell">Medium</div>
          </div>
          <div class="table-row">
            <div class="table-cell title">Recommended Duration</div>
            <div class="table-cell">2-3 Days</div>
            <div class="table-cell title">Transportation Convenience</div>
            <div class="table-cell">Medium</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Call to Action Section -->
    <div class="cta-section">
      <div class="cta-content">
        <h2 class="cta-title">Start Building Trusted Travel Applications</h2>
        <p class="cta-description">Join hundreds of developers using our blockchain-verified attraction data,<br>providing your users with smarter, more trustworthy travel experiences.</p>
        <button class="cta-button">Contact Us</button>
      </div>
    </div>
  </div>
</template>

<script setup>

</script>

<style scoped>
.docs-container {
  max-width: 1440px;
  margin: 0 auto;
  padding: 0 20px 20px 20px;
  background-color: #f5f5f5;
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

/* Features Styles */
.features-section {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 24px;
  margin-bottom: 60px;
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

/* Data Display Area Styles */
.data-section {
  padding: 20px;
  background-color: #ffffff;
  border-radius: 8px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  margin-bottom: 60px;
}

/* Hash Section */
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

/* Attraction Review Card */
.evaluation-card {
  border: 1px solid #d9d9d9;
  border-radius: 6px;
  margin-bottom: 20px;
}

.evaluation-content {
  padding: 16px;
  line-height: 1.6;
  color: #333;
  font-size: 14px;
  border-left: 3px solid #40a9ff;
}

/* Statistics Cards */
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

/* Popular Tags Area */
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

.tag {
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
/* Detailed Analysis Table */
.analysis-table {
  border-radius: 6px;
  overflow: hidden;
}

.table-header {
  padding: 12px 16px;
  border-bottom: 1px solid #f0f0f0;
}

.table-content {
  padding: 0;
  border: 1px solid #f0f0f0;
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
  color: #666;
  border-right: 1px solid #f0f0f0;
}

.table-cell.title {
  font-weight: 500;
  color: #1677ff;
  font-weight: bold;
}

/* Call to Action Section */
.cta-section {
  background: linear-gradient(135deg, #40a9ff 0%, #1890ff 100%);
  padding: 60px 0;
  text-align: center;
  color: white;
  border-radius: 12px;
}

.cta-content {
  max-width: 960px;
  margin: 0 auto;
  padding: 0 20px;
}

.cta-title {
  font-size: 28px;
  font-weight: 600;
  margin: 0 0 16px 0;
}

.cta-description {
  font-size: 16px;
  line-height: 1.8;
  margin: 0 0 24px 0;
  opacity: 0.9;
}

.cta-button {
  background-color: white;
  color: #1890ff;
  border: none;
  padding: 12px 32px;
  border-radius: 4px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.cta-button:hover {
  background-color: #f0f0f0;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

/* Responsive Design */
@media (max-width: 768px) {
  .stats-cards {
    grid-template-columns: 1fr;
  }
  
  .table-row {
    grid-template-columns: 1fr 1fr;
  }
  
  .hero-title {
    font-size: 24px;
  }
  
  .features-section {
    padding: 40px 20px;
  }
  
  .cta-title {
    font-size: 24px;
  }
}

@media (max-width: 480px) {
  .table-row {
    grid-template-columns: 1fr;
  }
  
  .cta-button {
    width: 100%;
  }
}
</style>