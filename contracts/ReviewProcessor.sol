// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IScenicReviewCore} from './interfaces/IScenicReviewCore.sol';
import {IReviewProcessor} from './interfaces/IReviewProcessor.sol';
import {IScenicStorage} from './interfaces/IScenicStorage.sol';
import './interfaces/ITravelDApp.sol';

/**
 * @title ReviewProcessor
 * @dev Review processing contract
 * @notice Responsible for managing review submission, approval, rewards and other functions
 */
contract ReviewProcessor is Ownable, ReentrancyGuard, IReviewProcessor {
    // Core contract address
    address public scenicReviewCoreAddr;
    
    // Permission check modifier
    modifier onlyCore() {
        require(msg.sender == scenicReviewCoreAddr, "ReviewProcessor: Only core contract can call this method");
        _;
    }
    // Subcontract addresses
    address public scenicStorageAddr;
    
    // Oracle address
    address public oracleAddress;
    
    // Token and other contract addresses
    IExtendedERC20 public travelToken;
    IUserLevel public userLevel;
    IFundPool public fundPool;
    
    // Review mapping (ID => review info)
    mapping(uint256 => IScenicReviewCore.Review) private _reviews;
    
    // Scenic spot review list mapping (scenicId => review ID list)
    mapping(uint256 => uint256[]) private _scenicReviews;
    
    // User review list mapping (user address => review ID list)
    mapping(address => uint256[]) private _userReviews;
    
    // Next review ID
    uint256 private _nextReviewId;
    
    // Event definitions
    event ReviewSubmitted(uint256 indexed reviewId, address indexed user, uint256 indexed scenicId);
    event ReviewApproved(uint256 indexed reviewId, bool approved);
    event ReviewRewarded(uint256 indexed reviewId, address indexed user, uint256 amount);
    event SummaryUpdateRequired(uint256 indexed scenicId, uint256 fromReviewIndex, uint256 toReviewIndex, uint256 currentLastReviewIndex);
    
    /**
     * @dev Constructor
     */
    constructor() Ownable(msg.sender) {
        // Initialize parameters
        _nextReviewId = 1;
    }
    
    /**
     * @dev Set external dependency addresses
     * @param tokenAddress TravelToken contract address
     * @param fundPoolAddress FundPool contract address
     * @param userLevelAddress UserLevel contract address
     */
    function setExternalDependencies(
        address tokenAddress,
        address fundPoolAddress,
        address userLevelAddress
    ) external onlyOwner {
        if (tokenAddress != address(0)) {
            travelToken = IExtendedERC20(tokenAddress);
        }
        if (fundPoolAddress != address(0)) {
            fundPool = IFundPool(fundPoolAddress);
        }
        if (userLevelAddress != address(0)) {
            userLevel = IUserLevel(userLevelAddress);
        }
    }
    
    /**
     * @dev Set subcontract addresses
     * @param _scenicStorageAddr Scenic spot storage contract address
     * @param _scenicReviewCoreAddr Core contract address
     */
    function setSubContractAddresses(address _scenicStorageAddr, address _scenicReviewCoreAddr) external onlyOwner {
        require(_scenicStorageAddr != address(0), "ReviewProcessor: ScenicStorage address cannot be zero");
        require(_scenicReviewCoreAddr != address(0), "ReviewProcessor: ScenicReviewCore address cannot be zero");
        
        scenicStorageAddr = _scenicStorageAddr;
        scenicReviewCoreAddr = _scenicReviewCoreAddr;
    }
    
    /**
     * @dev Set Oracle address
     * @param _oracleAddress Oracle contract address
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "ReviewProcessor: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }
    
    /**
     * @dev Validate if a string is valid JSON format, containing tags and content fields with non-empty values, and no other invalid fields
     * @param jsonStr JSON string to validate
     * @return bool Whether it's valid JSON format
     */
    function validateReviewJson(string memory jsonStr) external pure override returns (bool) {
        bytes memory jsonBytes = bytes(jsonStr);
        
        // Check if starts with { and ends with }
        if (jsonBytes.length < 15 || jsonBytes[0] != '{' || jsonBytes[jsonBytes.length - 1] != '}') {
            return false;
        }
        
        bool hasTags = false;
        bool hasContent = false;
        bool tagsValueEmpty = true;
        bool contentValueEmpty = true;
        uint braceCount = 0;
        
        // Iterate through the JSON string, only look for fields in the top-level object
        for (uint i = 0; i < jsonBytes.length; i++) {
            // Track brace depth, only look for fields in top-level object (braceCount == 1)
            if (jsonBytes[i] == '{') {
                braceCount++;
            } else if (jsonBytes[i] == '}') {
                braceCount--;
            }
            
            // Only look for fields in the top-level object
            if (braceCount == 1) {
                // Find the start of the field name
                if (jsonBytes[i] == '"') {
                    // Check if it's the tags field
                    if (!hasTags && i <= jsonBytes.length - 7) {
                        bool isTagsField = true;
                        
                        // Check if the previous character is a separator or left brace
                        if (i > 0) {
                            bytes1 prevChar = jsonBytes[i-1];
                            if (prevChar != '{' && prevChar != ',' && prevChar != ' ') {
                                isTagsField = false;
                            }
                        }
                        
                        if (isTagsField) {
                            // Check for "tags": or "tags" : pattern
                            if (jsonBytes[i+1] == 't' && 
                                jsonBytes[i+2] == 'a' && 
                                jsonBytes[i+3] == 'g' && 
                                jsonBytes[i+4] == 's' && 
                                jsonBytes[i+5] == '"') {
                                
                                uint colonPos = i + 6;
                                // Skip spaces
                                while (colonPos < jsonBytes.length && jsonBytes[colonPos] == ' ') {
                                    colonPos++;
                                }
                                // Check if there's a colon
                                if (colonPos < jsonBytes.length && jsonBytes[colonPos] == ':') {
                                    hasTags = true;
                                    
                                    // Find the start of the tags field value
                                    uint valueStart = colonPos + 1;
                                    // Skip spaces
                                    while (valueStart < jsonBytes.length && jsonBytes[valueStart] == ' ') {
                                        valueStart++;
                                    }
                                    
                                    // Check if value is string type
                                    if (valueStart < jsonBytes.length && jsonBytes[valueStart] == '"') {
                                        uint valueEnd = valueStart + 1;
                                        // Find closing quote of value
                                        while (valueEnd < jsonBytes.length && jsonBytes[valueEnd] != '"') {
                                            valueEnd++;
                                        }
                                        // Check if the value is not an empty string
                                        if (valueEnd > valueStart + 1) {
                                            tagsValueEmpty = false;
                                        }
                                        
                                        // Skip to end of value
                                        i = valueEnd;
                                    } else {
                                        // Non-string type, considered invalid
                                        return false;
                                    }
                                }
                            }
                        }
                    }
                    // Check if it's the content field
                    else if (!hasContent && i <= jsonBytes.length - 10) {
                        bool isContentField = true;
                        
                        // Check if previous character is separator or left brace
                        if (i > 0) {
                            bytes1 prevChar = jsonBytes[i-1];
                            if (prevChar != '{' && prevChar != ',' && prevChar != ' ') {
                                isContentField = false;
                            }
                        }
                        
                        if (isContentField) {
                            // Check for "content": or "content" : pattern
                            if (jsonBytes[i+1] == 'c' && 
                                jsonBytes[i+2] == 'o' && 
                                jsonBytes[i+3] == 'n' && 
                                jsonBytes[i+4] == 't' && 
                                jsonBytes[i+5] == 'e' && 
                                jsonBytes[i+6] == 'n' && 
                                jsonBytes[i+7] == 't' && 
                                jsonBytes[i+8] == '"') {
                                
                                uint colonPos = i + 9;
                                // Skip spaces
                                while (colonPos < jsonBytes.length && jsonBytes[colonPos] == ' ') {
                                    colonPos++;
                                }
                                // Check if there's a colon
                                if (colonPos < jsonBytes.length && jsonBytes[colonPos] == ':') {
                                    hasContent = true;
                                    
                                    // Find the start of the content field value
                                    uint valueStart = colonPos + 1;
                                    // Skip spaces
                                    while (valueStart < jsonBytes.length && jsonBytes[valueStart] == ' ') {
                                        valueStart++;
                                    }
                                    
                                    // Check if value is string type
                                    if (valueStart < jsonBytes.length && jsonBytes[valueStart] == '"') {
                                        uint valueEnd = valueStart + 1;
                                        // Find closing quote of value
                                        while (valueEnd < jsonBytes.length && jsonBytes[valueEnd] != '"') {
                                            valueEnd++;
                                        }
                                        // Check if the value is not an empty string
                                        if (valueEnd > valueStart + 1) {
                                            contentValueEmpty = false;
                                        }
                                        
                                        // Skip to end of value
                                        i = valueEnd;
                                    } else {
                                        // Non-string type, considered invalid
                                        return false;
                                    }
                                }
                            }
                        }
                    }
                    // Check if it's another invalid field
                    else {
                        // Found unknown field, return false
                        return false;
                    }
                }
            }
        }
        
        // Check if both tags and content fields are present, and their values are not empty strings
        return hasTags && hasContent && !tagsValueEmpty && !contentValueEmpty;
    }
    
    /**
     * @dev User submits review
     * @param scenicId Scenic spot ID
     * @param content Review content (JSON format)
     * @param rating Rating (integer between 1-10)
     * @param _user User address
     */
    function submitReview(
        uint256 scenicId,
        string memory content,
        uint256 rating,
        address _user
    ) external override nonReentrant onlyCore {
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "ReviewProcessor: Scenic spot does not exist or is inactive");
        require(rating >= 1 && rating <= 10, "ReviewProcessor: Rating must be an integer between 1-10");
        require(bytes(content).length <= 400, "ReviewProcessor: Review content is too long");
        require(this.validateReviewJson(content), "ReviewProcessor: Content must be valid JSON with non-empty tags and content fields, and no other invalid fields");
        
        // Generate review ID
        uint256 reviewId = _nextReviewId;
        _reviews[reviewId] = IScenicReviewCore.Review({
            user: _user,
            scenicId: scenicId,
            content: content,
            rating: rating,
            status: IScenicReviewCore.ReviewStatus.Pending, // Initialize status as pending review
            rewarded: false,
            rewardAmount: 0,
            timestamp: block.timestamp,
            submitTxHash: bytes32(0), // Initialize to 0, Oracle will update with actual transaction hash
            approveTxHash: bytes32(0) // Initialize to 0, Oracle will update with actual transaction hash
        });
        
        // Add to user review list
        _userReviews[_user].push(reviewId);
        
        _nextReviewId++;
        
        emit ReviewSubmitted(reviewId, _user, scenicId);
    }
    
    /**
     * @dev Update review status
     * @param reviewId Review ID
     * @param isApproved Whether it's approved
     */
    function updateReviewStatus(uint256 reviewId, bool isApproved) external override nonReentrant {
        require(msg.sender == oracleAddress || msg.sender == owner(), "ReviewProcessor: Only Oracle or owner can update review status");
        
        IScenicReviewCore.Review storage review = _reviews[reviewId];
        require(review.user != address(0), "ReviewProcessor: Review does not exist");
        require(review.status == IScenicReviewCore.ReviewStatus.Pending, "ReviewProcessor: Review must be in pending status");
        
        // Update status based on review result
        if (isApproved) {
            _processApprovedReview(reviewId);
        } else {
            review.status = IScenicReviewCore.ReviewStatus.Rejected;
        }
        
        // Send review status update event
        emit ReviewApproved(reviewId, isApproved);
    }
    
    /**
     * @dev Internal function: Process approved review
     * @param reviewId Review ID
     */
    function _processApprovedReview(uint256 reviewId) internal {
        IScenicReviewCore.Review storage review = _reviews[reviewId];
        require(review.user != address(0), "ReviewProcessor: Review does not exist");
        require(review.status == IScenicReviewCore.ReviewStatus.Pending, "ReviewProcessor: Review must be in pending status");
        require(review.scenicId > 0, "ReviewProcessor: Invalid scenic spot ID");
        
        // Update review status to approved
        review.status = IScenicReviewCore.ReviewStatus.Approved;
        
        // Add to scenic spot review list (only keeps approved reviews)
        _scenicReviews[review.scenicId].push(reviewId);
        
        // Update scenic spot average rating and review count
        IScenicStorage(scenicStorageAddr).updateScenicRating(review.scenicId, review.rating);
        
        // Distribute reward
        rewardReview(reviewId);
        
        // Check if new summary is needed (every 20 approved reviews)
        uint256 totalReviews = _scenicReviews[review.scenicId].length;
        if (totalReviews % 20 == 0) {
            // Calculate which review index to start generating summary from
            uint256 fromIndex = totalReviews - 20;
            uint256 toIndex = totalReviews - 1;
            
            emit SummaryUpdateRequired(review.scenicId, fromIndex, toIndex, 0);
        }
    }
    
    /**
     * @dev Distribute reward for review
     * @param reviewId Review ID
     */
    function rewardReview(uint256 reviewId) public override {
        IScenicReviewCore.Review storage review = _reviews[reviewId];
        require(review.user != address(0), "ReviewProcessor: Review does not exist");
        require(review.status == IScenicReviewCore.ReviewStatus.Approved, "ReviewProcessor: Review not approved");
        require(!review.rewarded, "ReviewProcessor: Reward already issued");
        
        // Get review reward corresponding to user's current level
        uint256 rewardAmount = userLevel.getUserReviewReward(review.user);
        
        // Distribute reward from fund pool
        // Use reward method with description
        (bool success, ) = address(travelToken).call(abi.encodeWithSignature(
            "reward(address,uint256,string)",
            review.user,
            rewardAmount,
            string(abi.encodePacked(IScenicStorage(scenicStorageAddr).getScenicSpot(review.scenicId).name, " evaluation accepted"))
        ));
        require(success, "ReviewProcessor: Reward issuance failed");
        
        review.rewarded = true;
        review.rewardAmount = rewardAmount;
        emit ReviewRewarded(reviewId, review.user, rewardAmount);
    }
    
    /**
     * @dev Get review information
     * @param reviewId Review ID
     * @return Review Review information
     */
    function getReview(uint256 reviewId) external view override returns (IScenicReviewCore.Review memory) {
        return _reviews[reviewId];
    }
    
    /**
     * @dev Get user's review list
     * @param user User address
     * @return Review[] User's review list
     */
    function getUserReviews(address user) external view override returns (IScenicReviewCore.Review[] memory) {
        // Only user themselves or core contract can view all user reviews
        require(msg.sender == user || msg.sender == scenicReviewCoreAddr, "ReviewProcessor: Can only view your own review list or be called by core contract");
        
        uint256[] storage reviewIds = _userReviews[user];
        uint256 totalCount = reviewIds.length;
        
        IScenicReviewCore.Review[] memory result = new IScenicReviewCore.Review[](totalCount);
        
        for (uint256 i = 0; i < totalCount; i++) {
            result[i] = _reviews[reviewIds[i]];
        }
        
        return result;
    }
    
    /**
     * @dev Get user's review list (paged)
     * @param user User address
     * @param start Start index
     * @param end End index
     * @return Review[] User's review list
     */
    function getUserReviews(address user, uint256 start, uint256 end) external view override returns (IScenicReviewCore.Review[] memory) {
        // Only user themselves or core contract can view all user reviews
        require(msg.sender == user || msg.sender == scenicReviewCoreAddr, "ReviewProcessor: Can only view your own review list or be called by core contract");
        
        uint256[] storage reviewIds = _userReviews[user];
        
        // Ensure requested indices are within valid range
        if (start >= reviewIds.length) {
            return new IScenicReviewCore.Review[](0);
        }
        
        uint256 actualEnd = end < reviewIds.length ? end : reviewIds.length - 1;
        uint256 actualCount = actualEnd - start + 1;
        IScenicReviewCore.Review[] memory result = new IScenicReviewCore.Review[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            result[i] = _reviews[reviewIds[start + i]];
        }
        
        return result;
    }
    
    /**
     * @dev Get approved review list for scenic spot
     * @param scenicId Scenic spot ID
     * @param count Number of reviews to get
     * @return Review[] Latest approved review list
     * @return uint256[] Corresponding review ID list
     */
    function getReviewsForSummary(uint256 scenicId, uint256 count) external view override returns (IScenicReviewCore.Review[] memory, uint256[] memory) {
        require(msg.sender == oracleAddress, "ReviewProcessor: Only Oracle can get review range");
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "ReviewProcessor: Scenic spot does not exist or is inactive");
        
        uint256[] storage allReviewIds = _scenicReviews[scenicId];
        uint256 totalApproved = allReviewIds.length;
        
        // Calculate actual number to return (not exceeding total count)
        uint256 actualCount = count;
        if (count > totalApproved) {
            actualCount = totalApproved;
        }
        
        // Create result arrays
        IScenicReviewCore.Review[] memory requestedReviews = new IScenicReviewCore.Review[](actualCount);
        uint256[] memory requestedReviewIds = new uint256[](actualCount);
        
        // Get the latest actualCount reviews
        for (uint256 i = 0; i < actualCount; i++) {
            // Traverse from the end of the array to get the latest reviews
            uint256 reviewIndex = totalApproved - actualCount + i;
            uint256 reviewId = allReviewIds[reviewIndex];
            requestedReviews[i] = _reviews[reviewId];
            requestedReviewIds[i] = reviewId;
        }
        
        return (requestedReviews, requestedReviewIds);
    }
    
    /**
     * @dev Get total number of historical reviews for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Total number of historical reviews
     */
    function getHistoricalReviewsCount(uint256 scenicId) external view override returns (uint256) {
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "ReviewProcessor: Scenic spot does not exist or is inactive");
        return _scenicReviews[scenicId].length;
    }
    
    /**
     * @dev Get historical review records for scenic spot
     * @param scenicId Scenic spot ID
     * @return Review[] Approved review list
     */
    function getHistoricalReviews(uint256 scenicId) external view override returns (IScenicReviewCore.Review[] memory) {
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "ReviewProcessor: Scenic spot does not exist or is inactive");
        
        uint256[] storage allReviewIds = _scenicReviews[scenicId];
        uint256 totalCount = allReviewIds.length;
        
        // Create result array with size equal to number of reviews
        IScenicReviewCore.Review[] memory result = new IScenicReviewCore.Review[](totalCount);
        
        // Populate all approved reviews (scenicReviews only contains approved reviews)
        for (uint256 i = 0; i < totalCount; i++) {
            result[i] = _reviews[allReviewIds[i]];
        }
        
        return result;
    }
    
    /**
     * @dev Update transaction hashes for review
     * @param reviewId Review ID
     * @param submitHash Transaction hash of user's review submission
     * @param approveHash Transaction hash of AI review status change
     */
    function updateReviewTxHashes(uint256 reviewId, bytes32 submitHash, bytes32 approveHash) external override {
        require(msg.sender == oracleAddress, "ReviewProcessor: Only Oracle can update transaction hash");
        
        IScenicReviewCore.Review storage review = _reviews[reviewId];
        require(review.user != address(0), "ReviewProcessor: Review does not exist");
        
        // Update transaction hashes
        if (submitHash != bytes32(0)) {
            review.submitTxHash = submitHash;
        }
        if (approveHash != bytes32(0)) {
            review.approveTxHash = approveHash;
        }
    }
    
    /**
     * @dev Get next review ID
     * @return uint256 Next review ID
     */
    function getNextReviewId() external view override returns (uint256) {
        return _nextReviewId;
    }
    
    /**
     * @dev Update UserLevel contract address
     * @param userLevelAddress New UserLevel contract address
     */
    function updateUserLevelAddress(address userLevelAddress) external onlyOwner {
        require(userLevelAddress != address(0), "ReviewProcessor: UserLevel address cannot be zero");
        userLevel = IUserLevel(userLevelAddress);
    }
    
    /**
     * @dev Update FundPool contract address
     * @param fundPoolAddress New FundPool contract address
     */
    function updateFundPoolAddress(address fundPoolAddress) external onlyOwner {
        require(fundPoolAddress != address(0), "ReviewProcessor: Fund pool address cannot be zero");
        fundPool = IFundPool(fundPoolAddress);
    }
}
