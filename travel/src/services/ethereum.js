import { ethers, formatEther, parseEther } from 'ethers';
const SCENIC_REVIEW_SYSTEM_ABI = [
  "function getScenicSpot(uint256 scenicId) view returns ((uint256 scenicId, string name, string location, string description, string tags, uint256 reviewCount, uint256 averageRating, bool active), (uint256 scenicId, string content, uint256[] reviewIds, uint256 timestamp, uint256 lastReviewIndex, uint256 version, bytes32 txHash))",
  "function getHistoricalSummaries(uint256 scenicId) view returns (tuple(uint256 scenicId, string content, uint256[] reviewIds, uint256 timestamp, uint256 lastReviewIndex, uint256 version, bytes32 txHash)[])",
  "function userSubmitReview(uint256, string, uint256) returns (bool)",
  'function getScenicSpotList() view returns (uint256[])',
  "function getHistoricalReviewsCount(uint256 scenicId) view returns (uint256)",
  'function getHistoricalReviews(uint256 scenicId) view returns (tuple(address user, uint256 scenicId, string content, uint256 rating, uint8 status, bool rewarded, uint256 rewardAmount, uint256 timestamp, uint256 version, bytes32 txHash)[])',
  "function getUserReviews(address user) view returns (tuple(address user, uint256 scenicId, string content, uint256 rating, uint256 status, bool rewarded, uint256 rewardAmount, uint256 timestamp, uint256 version, bytes32 txHash)[])",
]
const COUPON_SYSTEM_ABI = [
  "function verifyCoupon(string couponCode) returns (bool)",
  "function getAllCoupons() view returns (tuple(uint256 couponId, string name,string description, string tag,  uint256 price, uint256 maxSupply, uint256 validityDays, uint256 soldCount, bool active, string nftName)[])",
  "function getUserActiveCoupons(address user) view returns (tuple(uint256 couponId,string couponCode, string name, string description,string tag, uint256 price, uint256 validityDays, uint256 purchaseDate, uint256 expiryDate, uint8 status)[])",
  "function purchaseCoupon(uint256 couponId) returns (bool)"
]
const TRAVEL_TOKEN_ABI = [
  "function balanceOf(address account) view returns (uint256)",
  "function getUserTransactions(address user, uint256 start, uint256 end) view returns (tuple(uint256 id, address from, address to, uint256 amount, string action, string description, uint256 timestamp)[])",
  "function approve(address spender, uint256 value) returns (bool)",
  "function getUserTransactionCount(address user) view returns (uint256)"
]
const USER_LEVEL_ABI = [
  "function getUserLevelInfo(address user) view returns (tuple(uint256 level, uint256 lastUpgrade))",
  "function getUserLevel(address user) view returns (uint256)",
  "function getUserReviewReward(address user) view returns (uint256)",
  "function levelRules(uint256) view returns (tuple(uint256 requiredToken, uint256 reviewReward))",
  "function maxLevel() view returns (uint256)",
  "function upgrade() returns (bool)"
]

const TRAVEL_TOKEN = '0xa8***********************5543';
const SCENIC_REVIEW_SYSTEM = '0xc0***********************28ad';
const COUPON_SYSTEM = '0x0c***********************9374';
const USER_LEVEL = '0x95***********************7213';

// Get travel token contract instance
const getTravelTokenContract = async() =>{
  if (!window.ethereum) {
    throw new Error('Please install MetaMask or another Ethereum wallet first');
  }
    
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  return new ethers.Contract(TRAVEL_TOKEN, TRAVEL_TOKEN_ABI, signer);
}

// Get scenic review system contract instance
const getScenicReviewSystemContract = async() =>{
  if (!window.ethereum) {
    throw new Error('Please install MetaMask or another Ethereum wallet first');
  }
    
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  return new ethers.Contract(SCENIC_REVIEW_SYSTEM, SCENIC_REVIEW_SYSTEM_ABI, signer);
}

// Get coupon system contract instance
const getCouponSystemContract = async() =>{
  if (!window.ethereum) {
    throw new Error('Please install MetaMask or another Ethereum wallet first');
  }
    
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  return new ethers.Contract(COUPON_SYSTEM, COUPON_SYSTEM_ABI, signer);
}

// Get user level contract instance
const getUserLevelContract = async() =>{
  if (!window.ethereum) {
    throw new Error('Please install MetaMask or another Ethereum wallet first');
  }
    
  const provider = new ethers.BrowserProvider(window.ethereum);
  const signer = await provider.getSigner();
  return new ethers.Contract(USER_LEVEL, USER_LEVEL_ABI, signer);
}

/**
 * Ethereum Service Class
 * Provides common methods for Ethereum blockchain interaction
 */
class EthereumService {

  /**
   * Get all coupons
   * @returns {Promise<Array>} Coupon list
   */
  async getAllCoupons() {    
    const couponSystemContract = await getCouponSystemContract();
    const coupons = await couponSystemContract.getAllCoupons();  
      
    // Format coupon data
    return coupons.map(coupon => ({
      id: coupon.couponId.toString(),
      name: coupon.name,
      tag: coupon.description,
      description: coupon.description,
      price: formatEther(coupon.price),
      maxSupply: coupon.maxSupply.toString(),
      soldCount: (coupon.maxSupply - coupon.soldCount).toString(),
      validityDays: coupon.validityDays.toString(),
      nftName: coupon.nftName,
      active: coupon.active
    }));
  }

  /**
   * Purchase coupon
   * @param {number} couponId - Coupon ID
   * @param {number} tokenAmount - Authorized token amount (optional)
   * @returns {Promise<string>} Transaction hash
   */
  async purchaseCoupon(couponId, tokenAmount = 100) {
    const travelTokenContract = await getTravelTokenContract();
    const couponSystemContract = await getCouponSystemContract();
    
    // First authorize CouponSystem to use user's TRT
    const approveAmount = tokenAmount;
    const approveTx = await travelTokenContract.approve(COUPON_SYSTEM, parseEther(approveAmount.toString()));
    await approveTx.wait();
    
    // Then purchase coupon
    const purchaseTx = await couponSystemContract.purchaseCoupon(couponId);
    await purchaseTx.wait();
    
    return purchaseTx.hash;
  }

  /**
   * Verify coupon
   * @param {number} couponCode - Coupon code
   * @returns {Promise<string>} Transaction hash
   */
  async verifyCoupon(couponCode) {
    try {
      const couponSystemContract = await getCouponSystemContract();
      const verifyTx = await couponSystemContract.verifyCoupon(couponCode);
      const receipt = await verifyTx.wait();
      
      return receipt;
    } catch (error) {
      console.error('Verify coupon failed:', error);
      throw error;
    }
  }

  /**
   * Get user's active coupons (unused, not expired)
   * @param {string} userAddress - User address
   * @returns {Promise<Array>} Active coupon list
   */
  async getUserActiveCoupons(userAddress) {
    const couponSystemContract = await getCouponSystemContract();
    const coupons = await couponSystemContract.getUserActiveCoupons(userAddress); 
    // Format coupon data
    return coupons.map(coupon => ({
      id: coupon.couponId.toString(),
      couponCode: coupon.couponCode,
      name: coupon.name,
      description: coupon.description,
      price: coupon.price,
      validityDays: coupon.validityDays.toString(),
      purchaseDate: new Date(Number(coupon.purchaseDate) * 1000).toLocaleString(),
      expiryDate: new Date((Number(coupon.expiryDate) * 1000) + (Number(coupon.validityDays) * 24 * 60 * 60 * 1000)).toLocaleString(),
      status: this._getStatusText(coupon.status),
      statusCode: coupon.status
    }));
  }

  /**
   * Get user's specific coupon
   * @param {string} userAddress - User address
   * @param {number} couponId - Coupon ID
   * @param {number} index - Index
   * @returns {Promise<Object>} Coupon details
   */
  async getUserCoupon(userAddress, couponId, index) {
    const couponSystemContract = await getCouponSystemContract();
    const coupon = await couponSystemContract.getUserCoupon(userAddress, couponId, index);
    
    // Format coupon data
    return {
      id: coupon.couponId.toString(),
      name: coupon.name,
      description: coupon.description,
      price: coupon.price,
      validityDays: coupon.validityDays.toString(),
      purchaseDate: new Date(Number(coupon.purchaseDate) * 1000),
      expiryDate: new Date(Number(coupon.expiryDate) * 1000),
      status: this._getStatusText(coupon.status),
      statusCode: coupon.status
    };
  }
  
  /**
   * Get user TRT token balance
   * @param {string} userAddress - User address
   * @returns {Promise<number>} TRT balance
   */
  async getTokenBalance(userAddress) {
    const travelTokenContract = await getTravelTokenContract();
    const balance = await travelTokenContract.balanceOf(userAddress);
    return Number(formatEther(balance));
  }



  /**
   * Convert status code to status text
   * @private
   * @param {number} statusCode - Status code
   * @returns {string} Status text
   */
  _getStatusText(statusCode) {    
    const statusMap = {
      1: 'Used',
      2: 'Expired'
    };
    return statusMap[statusCode] || 'Unused';
  }



  /**
   * Get user transaction records
   * @param {string} userAddress - User address
   * @param {number} start - Start index
   * @param {number} end - End index
   * @returns {Promise<Array>} Transaction records list
   */
  async getUserTransactions(userAddress, start = 0, end = 100) {
    try {
      const travelTokenContract = await getTravelTokenContract();
      let transactions = await travelTokenContract.getUserTransactions(userAddress, start, end);       
      transactions = transactions.filter(tx => tx.description);      
      return transactions.map(tx => ({
        id: tx.id.toString(),
        from: tx.from,
        to: tx.to,
        amount: formatEther(tx.amount),
        action: tx.action === 'REWARD' || tx.action === 'WITHDRAW' ? 'WITHDRAW' : 'CONSUME',
        description: tx.description || 'No description',
        timestamp: new Date(Number(tx.timestamp) * 1000).toLocaleString()
      }));
    } catch (error) {
      console.error('Failed to get user transaction records:', error);
      throw error;
    }
  }

  /**
   * Get user's historical review records
   * @param {string} userAddress - User address
   * @returns {Promise<Array>} Historical reviews list
   */
  async getUserReviews(userAddress) {
    try {
      const scenicReviewSystemContract = await getScenicReviewSystemContract();
      const reviews = await scenicReviewSystemContract.getUserReviews(userAddress);
      // Format review data to match new data structure
      return reviews.map(review => ({
        scenicId: review.scenicId ? Number(review.scenicId) : '',
        content: review.content.includes('{') ? JSON.parse(review.content).content : review.content,
        tags: review.content.includes('{') ? JSON.parse(review.content).tags.split(',') : [],
        rating: review.rating ? Number(review.rating) / 2 : 0,
        status: Number(review.status),
        statusTab: Number(review.status) == 0 ? 'pending' : Number(review.status) == 1 ? 'accepted' : 'rejected',
        statusTagsColor: Number(review.status) == 0 ? 'orange' : Number(review.status) == 1 ? 'green' : 'red',
        statusText: Number(review.status) == 0 ? 'Pending' : Number(review.status) == 1 ? 'Accepted' : 'Rejected',
        timestamp: new Date(Number(review.timestamp.toString()) * 1000),
        formattedTimestamp: new Date(Number(review.timestamp.toString()) * 1000).toLocaleString(),
        rewarded: review.rewarded,
        rewardAmount: review.rewardAmount ? Number(formatEther(review.rewardAmount)) : 0,
        txHash: review.txHash || ''
      }));
    } catch (error) {
      console.error('Failed to get historical review list:', error);
      throw error;
    }
  }

  /**
   * Get attraction's historical review records
   * @param {number} scenicId - Attraction ID
   * @returns {Promise<Array>} Historical reviews list
   */
  async getHistoricalReviews(scenicId) {
    try {
      const scenicReviewSystemContract = await getScenicReviewSystemContract();
      const reviews = await scenicReviewSystemContract.getHistoricalReviews(scenicId); 
      
      // Format review data
      return reviews.map(review => ({
        userName: review.user || '',
        scenicId: review.scenicId ? Number(review.scenicId) : '',
        content: review.content.includes('{') ? JSON.parse(review.content).content : review.content,
        tags: review.content.includes('{') ? JSON.parse(review.content).tags.split(',') : [],
        rating: review.rating ? Number(review.rating) / 2 : 0,
        status: Number(review.status),
        statusTab: Number(review.status) == 0 ? 'pending' : Number(review.status) == 1 ? 'accepted' : 'rejected',
        statusTagsColor: Number(review.status) == 0 ? 'orange' : Number(review.status) == 1 ? 'green' : 'red',
        statusText: Number(review.status) == 0 ? 'Pending' : Number(review.status) == 1 ? 'Accepted' : 'Rejected',
        timestamp: new Date(Number(review.timestamp.toString()) * 1000).toLocaleString(),
        formattedTimestamp: new Date(Number(review.timestamp.toString()) * 1000).toLocaleString(),
        rewarded: review.rewarded,
        txHash: review.txHash || '',
        rewardAmount: review.rewardAmount ? Number(formatEther(review.rewardAmount)) : 0
      }));
      
    } catch (error) {
      console.error('Failed to get historical review list:', error);
      throw error;
    }
  }


  /**
   * Get historical summary records
   * @param {number} scenicId - Attraction ID
   * @returns {Promise<Array>} Historical summaries list
   */
  async getHistoricalSummaries(scenicId) {
    try {
      const scenicReviewSystemContract = await getScenicReviewSystemContract();
      const summaries = await scenicReviewSystemContract.getHistoricalSummaries(scenicId);
      
      // Format summary data
      return summaries.map(summary => {
        const parsedSummary = summary.content ? JSON.parse(summary.content) : {};
        
        return {
          scenicId: summary.scenicId ? Number(summary.scenicId) : null,
          content: summary.content || '',
          reviewCount: summary.reviewIds && Array.isArray(summary.reviewIds) ? summary.reviewIds.length : 0,
          timestamp: new Date(Number(summary.timestamp.toString()) * 1000).toLocaleString(),
          lastReviewIndex: summary.lastReviewIndex ? Number(summary.lastReviewIndex.toString()) : 0,
          version: summary.version ? Number(summary.version.toString()) : 1,
          txHash: summary.txHash || '',
          positive:parsedSummary.review_count?.positive || 0,
          neutral:parsedSummary.review_count?.neutral || 0,
          negative:parsedSummary.review_count?.negative || 0,
          popular_tags:parsedSummary.popular_tags || [],
          overall_rating:parsedSummary.detailed_analysis?.overall_rating || 0,
          core_feedback_summary:parsedSummary.core_feedback_summary || '',
          positiveRating:parsedSummary.review_count?.positive ? (parsedSummary.review_count?.positive / (parsedSummary.review_count?.positive + parsedSummary.review_count?.neutral + parsedSummary.review_count?.negative) * 100).toFixed(2) + '%' : '/',
          location:parsedSummary.detailed_analysis?.location || '/',
          crowd_level:parsedSummary.detailed_analysis?.crowd_level || '/',
          best_season:parsedSummary.detailed_analysis?.best_season || '/',
          suitable_people:parsedSummary.detailed_analysis?.suitable_people || '/',
          price_level:parsedSummary.detailed_analysis?.price_level || '/',
          suggested_duration:parsedSummary.detailed_analysis?.suggested_duration || '/',
          transportation:parsedSummary.detailed_analysis?.traffic_convenience || '/',
        };
      });
    } catch (error) {
      console.error('Failed to get historical summary records:', error);
      throw error;
    }
  }

  /**
   * Submit attraction review
   * @param {number} scenicId - Attraction ID
   * @param {string} content - Review content
   * @param {number} rating - Review rating (1-5)
   * @returns {Promise<Array>} Historical summaries list
   */
  async userSubmitReview(scenicId, content, rating) {
    try {      
      const scenicReviewSystemContract = await getScenicReviewSystemContract();
      const summaries = await scenicReviewSystemContract.userSubmitReview(scenicId, content, rating);
      
      // Format summary data
      return summaries
    } catch (error) {
      console.error('Failed to submit review:', error);
      throw error;
    }
  }


 /**
   * Get historical review count
   * @param {number} scenicId - Attraction ID
   * @returns {Promise<number>} Historical review count
   */
  async getHistoricalReviewsCount(scenicId) {
    try {
      const scenicReviewSystemContract = await getScenicReviewSystemContract();
      const summaries = await scenicReviewSystemContract.getHistoricalReviewsCount(scenicId);
      
      // Format summary data
      return Number(summaries)
    } catch (error) {
      console.error('Failed to get historical review count:', error);
      throw error;
    }
  }

  /**
   * Get attraction details and latest summary
   * @param {number} scenicId - Attraction ID
   * @returns {Promise<Object>} Object containing attraction info and latest summary
   */
  async getScenicSpot(scenicId) {
    try {
      const scenicReviewSystemContract = await getScenicReviewSystemContract();
      const result = await scenicReviewSystemContract.getScenicSpot(scenicId);      
      const scenicSpot = result[0];
      const latestSummary = result[1];    
      const parsedSummary = latestSummary.content ? JSON.parse(latestSummary.content) : {};
      
      return {
        scenicSpot: {
          scenicId: scenicSpot.scenicId ? Number(scenicSpot.scenicId) : null,
          name: scenicSpot.name || '',
          location: scenicSpot.location || '',
          description: scenicSpot.description || '',
          tags: scenicSpot.tags.split(',') || [],
          reviewCount: scenicSpot.reviewCount ? scenicSpot.reviewCount : 0,
          averageRating: scenicSpot.averageRating ? Number(scenicSpot.averageRating) / 10 : 0,
          active: scenicSpot.active || false
        },
        latestSummary: {
          scenicId: latestSummary.scenicId ? Number(latestSummary.scenicId) : null,
          content: latestSummary.content || '',
          reviewIds: latestSummary.reviewIds ? latestSummary.reviewIds.map(id => Number(id)) : [],
          timestamp: latestSummary.timestamp > 1000 ? new Date(Number(latestSummary.timestamp) * 1000).toLocaleString() : '',
          lastReviewIndex: latestSummary.lastReviewIndex ? Number(latestSummary.lastReviewIndex) : 0,
          version: latestSummary.version ? Number(latestSummary.version) : 1,
          txHash: latestSummary.txHash ? latestSummary.txHash : '',

          positive:parsedSummary.review_count?.positive || 0,
          neutral:parsedSummary.review_count?.neutral || 0,
          negative:parsedSummary.review_count?.negative || 0,
          popular_tags:parsedSummary.popular_tags || [],
          overall_rating:parsedSummary.detailed_analysis?.overall_rating || 0,
          core_feedback_summary:parsedSummary.core_feedback_summary || '',
          positiveRating:parsedSummary.review_count?.positive ? (parsedSummary.review_count?.positive / (parsedSummary.review_count?.positive + parsedSummary.review_count?.neutral + parsedSummary.review_count?.negative) * 100).toFixed(2) + '%' : '/',
          location:parsedSummary.detailed_analysis?.location || '/',
          crowd_level:parsedSummary.detailed_analysis?.crowd_level || '/',
          best_season:parsedSummary.detailed_analysis?.best_season || '/',
          suitable_people:parsedSummary.detailed_analysis?.suitable_people || '/',
          price_level:parsedSummary.detailed_analysis?.price_level || '/',
          suggested_duration:parsedSummary.detailed_analysis?.suggested_duration || '/',
          traffic_convenience:parsedSummary.detailed_analysis?.traffic_convenience || '/'
        }
      };
    } catch (error) {
      console.error('Failed to get attraction details:', error.message);
      throw error;
    }
  }


  /**
   * Get top 8 attractions by average rating
   * @returns {Promise<Array>} Array of objects containing attraction list info
   */
  async getScenicSpotList() {
    try {
      const scenicReviewSystemContract = await getScenicReviewSystemContract();
      const result = await scenicReviewSystemContract.getScenicSpotList();
      
      const scenicSpots = await Promise.all(
        result.map(async (scenicId) => {
          const spotData = await this.getScenicSpot(scenicId);
          return {
            ...spotData.scenicSpot,
            latestSummary: spotData.latestSummary || {}
          };
        })
      );
      
      return scenicSpots;
    } catch (error) {
      console.error('Failed to get attraction list:', error);
      throw error;
    }
  }



  /**
   * Get user level info
   * @param {string} userAddress - User address
   * @returns {Promise<Object>} User level info
   */
  async getUserLevelInfo(userAddress) {
    try {
      const userLevelContract = await getUserLevelContract();
      const levelInfo = await userLevelContract.getUserLevelInfo(userAddress);      
      return {
        level: levelInfo.level ? Number(levelInfo.level) : 0,
        points: levelInfo.lastUpgrade > 1000 ? new Date(Number(levelInfo.lastUpgrade) * 1000).toLocaleString() : 'No upgrade history',
        nextLevel : levelInfo.level ? Number(levelInfo.level) + 1 : 1
      };
    } catch (error) {
      console.error('Failed to get user level info:', error);
      throw error;
    }
  }

  /**
   * Get user review reward
   * @param {string} userAddress - User address
   * @returns {Promise<string>} User review reward (formatted ETH value)
   */
  async getUserReviewReward(userAddress) {
    try {
      const userLevelContract = await getUserLevelContract();
      const reward = await userLevelContract.getUserReviewReward(userAddress);
      
      return formatEther(reward);
    } catch (error) {
      console.error('Failed to get user review reward:', error);
      throw error;
    }
  }

  /**
   * Get token amount required for upgrade
   * @param {number} targetLevel - Target level
   * @returns {Promise<string>} Token amount required for upgrade (formatted ETH value)
   */
  async getUpgradeCost(targetLevel) {
    try {
      const userLevelContract = await getUserLevelContract();
      const levelRule = await userLevelContract.levelRules(targetLevel);  
      return {
        requiredToken: formatEther(levelRule.requiredToken),
        reviewReward: formatEther(levelRule.reviewReward),
      }
    } catch (error) {
      console.error('Failed to get token amount required for upgrade:', error);
      throw error;
    }
  }


  /**
   * Get current user level
   * @returns {Promise<number>} Current user level
   */
  async getCurrentUserLevel() {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const userAddress = await signer.getAddress();
      const userLevelInfo = await this.getUserLevelInfo(userAddress);
      return userLevelInfo.level;
    } catch (error) {
      console.error('Failed to get current user level:', error);
      throw error;
    }
  }
  /**
   * Get points required for next level
   * @returns {Promise<number>} Points required for next level
   */
  async getNextLevelPoints() {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const userAddress = await signer.getAddress();
      const userLevelInfo = await this.getUserLevelInfo(userAddress);
      return userLevelInfo.nextLevelPoints || 0;
    } catch (error) {
      console.error('Failed to get points required for next level:', error);
      throw error;
    }
  }
  /**
   * User upgrade using tokens
   * @param {number} tokenAmount - Authorized token amount
   * @returns {Promise<string>} Transaction hash
   */
  async upgradeUserLevel(tokenAmount) {
    try {
      const travelTokenContract = await getTravelTokenContract();
      const userLevelContract = await getUserLevelContract();
      
      // User authorizes UserLevel contract to use Token
      const approveTx = await travelTokenContract.approve(USER_LEVEL, parseEther(tokenAmount.toString()));
      await approveTx.wait();
      
      // User executes upgrade
      const upgradeTx = await userLevelContract.upgrade();
      await upgradeTx.wait();
      
      return upgradeTx.hash;
    } catch (error) {
      console.error('Failed to upgrade user:', error);
      throw error;
    }
  }

  /**
   * Get all level rules
   * @returns {Promise<Array>} Level rules list
   */
  async getAllLevelRules() {
    try {
      const userLevelContract = await getUserLevelContract();
      const rules = await userLevelContract.getAllLevelRules();
      
      return rules.map((rule, index) => ({
        level: index + 1,
        requiredPoints: rule.requiredPoints ? rule.requiredPoints.toNumber() : 0,
        requiredToken: formatEther(rule.requiredToken),
        rewardMultiplier: rule.rewardMultiplier ? rule.rewardMultiplier.toNumber() : 0
      }));
    } catch (error) {
      console.error('Failed to get level rules:', error);
      throw error;
    }
  }

  /**
   * Get coupon definition info
   * @param {number} couponId - Coupon ID
   * @returns {Promise<Object>} Coupon definition info
   */
  async getCouponDefinition(couponId) {
    try {
      const couponSystemContract = await getCouponSystemContract();
      const definition = await couponSystemContract.getCouponDefinition(couponId);
      
      return {
        couponId: definition.couponId ? definition.couponId.toNumber() : couponId,
        name: definition.name,
        tag: definition.tag,
        description: definition.description,
        price: formatEther(definition.price),
        expiryDuration: definition.expiryDuration ? definition.expiryDuration.toNumber() : 0,
        maxQuantity: definition.maxQuantity ? definition.maxQuantity.toNumber() : 0,
        soldCount: definition.soldCount ? definition.soldCount.toNumber() : 0
      };
    } catch (error) {
      console.error('Failed to get coupon definition:', error);
      throw error;
    }
  }


  /**
   * Get user coupon count
   * @param {string} userAddress - User address
   * @param {number} couponId - Coupon ID
   * @returns {Promise<number>} Coupon count
   */
  async getUserCouponCount(userAddress, couponId) {
    try {
      const couponSystemContract = await getCouponSystemContract();
      const count = await couponSystemContract.getUserCouponCount(userAddress, couponId);
      
      return count ? count.toNumber() : 0;
    } catch (error) {
      console.error('Failed to get user coupon count:', error);
      throw error;
    }
  }



  /**
   * Check if coupon is expired
   * @param {Object} coupon - Coupon details object
   * @returns {boolean} Whether it's expired
   */
  isCouponExpired(coupon) {
    const currentTime = Math.floor(Date.now() / 1000);
    return coupon.expiryAt && currentTime > coupon.expiryAt;
  }

  /**
   * Compare latest summaries of two attractions
   * @param {number} scenicId1 - First attraction ID
   * @param {number} scenicId2 - Second attraction ID
   * @returns {Promise<Object>} Comparison result
   */
  async compareScenicSpots(scenicId1, scenicId2) {
    const scenicReviewSystemContract = await getScenicReviewSystemContract();
    
    // Get details and latest summary for attraction 1
    const result1 = await scenicReviewSystemContract.getScenicSpot(scenicId1);
    const spot1Details = result1[0];
    const summary1 = result1[1];
    
    // Get details and latest summary for attraction 2
    const result2 = await scenicReviewSystemContract.getScenicSpot(scenicId2);
    const spot2Details = result2[0];
    const summary2 = result2[1];
    // Build comparison result object - two separate objects instead of array
    const parsedSummary1 = summary1.content ? JSON.parse(summary1.content) : {};
    const parsedSummary2 = summary2.content ? JSON.parse(summary2.content) : {};
    const comparisonResult = {
      spot1: {
        scenicId: spot1Details.scenicId ? Number(spot1Details.scenicId) : null,
        name: spot1Details.name || '',
        location: spot1Details.location || '',
        description: spot1Details.description || '',
        tags: spot1Details.tags.split(',') || [],
        reviewCount: spot1Details.reviewCount ? spot1Details.reviewCount : 0,
        averageRating: spot1Details.averageRating ? Number(spot1Details.averageRating) / 10 : 0,
        active: spot1Details.active || false,
        summaryId: summary1.scenicId ? Number(summary1.scenicId) : null,
        reviewIds: summary1.reviewIds ? summary1.reviewIds.map(id => Number(id)) : [],
        timestamp: summary1.timestamp > 1000 ? new Date(Number(summary1.timestamp) * 1000).toLocaleString() : '',
        lastReviewIndex: summary1.lastReviewIndex ? Number(summary1.lastReviewIndex) : 0,
        version: summary1.version ? Number(summary1.version) : 1,
        txHash: summary1.txHash != '0x0000000000000000000000000000000000000000000000000000000000000000' ? summary1.txHash : '',

        overall_rating:parsedSummary1.detailed_analysis?.overall_rating || 0,
        core_feedback_summary:parsedSummary1.core_feedback_summary || '',
        positiveRating:parsedSummary1.review_count?.positive ? (parsedSummary1.review_count?.positive / (parsedSummary1.review_count?.positive + parsedSummary1.review_count?.neutral + parsedSummary1.review_count?.negative) * 100).toFixed(2) : '/',
        location_rating:parsedSummary1.detailed_analysis?.location || '/',
        crowd_level:parsedSummary1.detailed_analysis?.crowd_level || '/',
        best_season:parsedSummary1.detailed_analysis?.best_season || '/',
        suitable_people:parsedSummary1.detailed_analysis?.suitable_people || '/',
        price_level:parsedSummary1.detailed_analysis?.price_level || '/',
        suggested_duration:parsedSummary1.detailed_analysis?.suggested_duration || '/',
        traffic_convenience:parsedSummary1.detailed_analysis?.traffic_convenience || '/',
      },
      spot2: {
        scenicId: spot2Details.scenicId ? Number(spot2Details.scenicId) : null,
        name: spot2Details.name || '',
        location: spot2Details.location || '',
        description: spot2Details.description || '',
        tags: spot2Details.tags.split(',') || [],
        reviewCount: spot2Details.reviewCount ? spot2Details.reviewCount : 0,
        averageRating: spot2Details.averageRating ? Number(spot2Details.averageRating) / 10 : 0,
        active: spot2Details.active || false,
        summaryId: summary2.scenicId ? Number(summary2.scenicId) : null,
        reviewIds: summary2.reviewIds ? summary2.reviewIds.map(id => Number(id)) : [],
        timestamp: summary2.timestamp > 1000 ? new Date(Number(summary2.timestamp) * 1000).toLocaleString() : '',
        lastReviewIndex: summary2.lastReviewIndex ? Number(summary2.lastReviewIndex) : 0,
        version: summary2.version ? Number(summary2.version) : 1,
        txHash: summary2.txHash != '0x0000000000000000000000000000000000000000000000000000000000000000' ? summary2.txHash : '',
        
        overall_rating:parsedSummary2.detailed_analysis?.overall_rating || 0,
        core_feedback_summary:parsedSummary2.core_feedback_summary || '',
        positiveRating:parsedSummary2.review_count?.positive ? (parsedSummary2.review_count?.positive / (parsedSummary2.review_count?.positive + parsedSummary2.review_count?.neutral + parsedSummary2.review_count?.negative) * 100).toFixed(2) + '%' : '/',
        location_rating:parsedSummary2.detailed_analysis?.location || '/',
        crowd_level:parsedSummary2.detailed_analysis?.crowd_level || '/',
        best_season:parsedSummary2.detailed_analysis?.best_season || '/',
        suitable_people:parsedSummary2.detailed_analysis?.suitable_people || '/',
        price_level:parsedSummary2.detailed_analysis?.price_level || '/',
        suggested_duration:parsedSummary2.detailed_analysis?.suggested_duration || '/',
        traffic_convenience:parsedSummary2.detailed_analysis?.traffic_convenience || '/',
      }
    };
    
    return comparisonResult;
  }
}


// Export singleton instance
const ethereumService = new EthereumService();

export {
  ethereumService
};
export {
  EthereumService
};