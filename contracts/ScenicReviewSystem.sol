// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Import shared interface file
import './interfaces/ITravelDApp.sol';

/**
 * @title ScenicReviewSystem
 * @dev Scenic spot, review and AI summary contract
 * @notice Manages scenic spot information, user reviews and AI-generated review summaries
 */
contract ScenicReviewSystem is Ownable, ReentrancyGuard {
    // Scenic spot struct
    struct ScenicSpot {
        uint256 scenicId;   // Scenic spot ID
        string name;        // Scenic spot name
        string location;    // Scenic spot location
        string description; // Scenic spot description
        string tags;        // Scenic spot tags
        uint256 reviewCount; // Number of approved reviews
        uint256 averageRating; // Average rating (1-10, multiplied by 10 to store one decimal place)
        bool active;        // Whether active
    }
    
    // Review status enum
    enum ReviewStatus {
        Pending,    // Pending review
        Approved,   // Approved
        Rejected    // Rejected
    }

    // Review struct
    struct Review {
        address user;       // Review user
        uint256 scenicId;   // Scenic spot ID
        string content;     // Review content
        uint256 rating;     // Rating (integer between 1-10)
        ReviewStatus status; // Review status
        bool rewarded;      // Whether rewarded
        uint256 rewardAmount; // Amount of tokens rewarded
        uint256 timestamp;  // Submission time
        bytes32 submitTxHash; // Transaction hash of user's review submission
        bytes32 approveTxHash; // Transaction hash of AI review status change
    }
    
    // Summary struct
    struct Summary {
        uint256 scenicId;   // Scenic spot ID
        string content;     // Summary content
        uint256[] reviewIds; // List of review IDs used as basis
        uint256 timestamp;  // Generation time
        uint256 lastReviewIndex; // Index of the last review used for current summary
        uint256 version;    // Summary version
        bytes32 txHash;     // Transaction hash of uploaded summary
    }
    
    // Event definitions
    event ScenicSpotAdded(uint256 indexed scenicId, string name, string location);
    event ReviewSubmitted(uint256 indexed reviewId, address indexed user, uint256 indexed scenicId);
    event ReviewApproved(uint256 indexed reviewId, bool approved);
    event ReviewRewarded(uint256 indexed reviewId, address indexed user, uint256 amount);
    event SummaryGenerated(uint256 indexed scenicId, uint256 reviewIdsCount, uint256 timestamp, uint256 version, bytes32 txHash);
    event SummaryUpdateRequired(uint256 indexed scenicId, uint256 fromReviewIndex, uint256 toReviewIndex, uint256 currentLastReviewIndex);

    event HistoricalSummaryStored(uint256 indexed scenicId, uint256 version, uint256 timestamp);

    
    // Scenic spot mapping (ID => scenic spot info)
    mapping(uint256 => ScenicSpot) public scenicSpots;
    
    // Review mapping (ID => review info)
    mapping(uint256 => Review) public reviews;
    
    // Scenic spot summary mapping (scenicId => summary info)
    mapping(uint256 => Summary) public scenicSummaries;
    
    // Scenic spot historical summary mapping (scenicId => historical summary list)
    mapping(uint256 => Summary[]) public scenicHistoricalSummaries;
    
    // Scenic spot summary version counter mapping (scenicId => version)
    mapping(uint256 => uint256) public scenicSummaryVersions;
    
    // Scenic spot review list mapping (scenicId => review ID list)
    mapping(uint256 => uint256[]) public scenicReviews;
    
    // User review list mapping (user address => review ID list)
    mapping(address => uint256[]) public userReviews;
    
    // Token contract address
    IExtendedERC20 public travelToken;
    
    // Oracle address
    address public oracleAddress;
    
    // Fund pool contract address
    IFundPool public fundPool;
    
    // UserLevel contract address
    IUserLevel public userLevel;
    
    // Next scenic spot ID
    uint256 public nextScenicId;
    
    // Next review ID
    uint256 public nextReviewId;

    /**
     * @dev Constructor
     * @param tokenAddress TravelToken contract address
     * @param fundPoolAddress FundPool contract address
     * @param userLevelAddress UserLevel contract address
     */
    constructor(address tokenAddress, address fundPoolAddress, address userLevelAddress) Ownable(msg.sender) {
        require(tokenAddress != address(0), "ScenicReviewSystem: Token address cannot be zero");
        require(fundPoolAddress != address(0), "ScenicReviewSystem: Fund pool address cannot be zero");
        require(userLevelAddress != address(0), "ScenicReviewSystem: UserLevel address cannot be zero");
        travelToken = IExtendedERC20(tokenAddress);
        fundPool = IFundPool(fundPoolAddress);
        userLevel = IUserLevel(userLevelAddress);
        
        // Initialize parameters
        nextScenicId = 1;
        nextReviewId = 1;

    }
    
    /**
     * @dev Add scenic spot (admin only)
     * @param name Scenic spot name
     * @param location Scenic spot location
     * @param description Scenic spot description
     * @param tags Scenic spot tags
     */
    function addScenicSpot(
        string memory name,
        string memory location,
        string memory description,
        string memory tags
    ) external onlyOwner {
        uint256 scenicId = nextScenicId;
        scenicSpots[scenicId] = ScenicSpot({
            scenicId: scenicId,
            name: name,
            location: location,
            description: description,
            tags: tags,
            reviewCount: 0,
            averageRating: 0,
            active: true
        });
        
        nextScenicId++;
        emit ScenicSpotAdded(scenicId, name, location);
    }
    
    /**
     * @dev Validate if a string is valid JSON format, containing tags and content fields with non-empty values, and no other invalid fields
     * @param jsonStr JSON string to validate
     * @return bool Whether it's valid JSON format
     */
    function _validateReviewJson(string memory jsonStr) internal pure returns (bool) {
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
        
        // Iterate through JSON string, only look for fields in top-level object
        for (uint i = 0; i < jsonBytes.length; i++) {
            // Track brace depth, only look for fields in top-level object (braceCount == 1)
            if (jsonBytes[i] == '{') {
                braceCount++;
            } else if (jsonBytes[i] == '}') {
                braceCount--;
            }
            
            // Only look for fields in top-level object
            if (braceCount == 1) {
                // Find start of field name
                if (jsonBytes[i] == '"') {
                    // Check if it's tags field
                    if (!hasTags && i <= jsonBytes.length - 7) {
                        bool isTagsField = true;
                        
                        // Check if previous character is separator or left brace
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
                                    
                                    // Find start of tags field value
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
                                        // Check if value is not empty string
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
                    // Check if it's content field
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
                                    
                                    // Find start of content field value
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
                                        // Check if value is not empty string
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
                    // Check if it's other invalid field
                    else {
                        // Found unknown field, return false
                        return false;
                    }
                }
            }
        }
        
        // Check if both tags and content fields are present with non-empty values
        return hasTags && hasContent && !tagsValueEmpty && !contentValueEmpty;
    }
    
    /**
     * @dev User directly submits review
     * @param scenicId Scenic spot ID
     * @param content Review content (JSON format)
     * @param rating Rating (integer between 1-10)
     */
    function userSubmitReview(
        uint256 scenicId,
        string memory content,
        uint256 rating
    ) external nonReentrant {
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        require(rating >= 1 && rating <= 10, "ScenicReviewSystem: Rating must be an integer between 1-10");
        require(bytes(content).length <= 400, "ScenicReviewSystem: Review content is too long");
        require(_validateReviewJson(content), "ScenicReviewSystem: Content must be valid JSON with non-empty tags and content fields, and no other invalid fields");
        
        // Generate review ID
        uint256 reviewId = nextReviewId;
        reviews[reviewId] = Review({
            user: _msgSender(),
            scenicId: scenicId,
            content: content,
            rating: rating,
            status: ReviewStatus.Pending, // Initialize status as pending review
            rewarded: false,
            rewardAmount: 0,
            timestamp: block.timestamp,
            submitTxHash: bytes32(0), // Initialize to 0, Oracle will update with actual transaction hash
            approveTxHash: bytes32(0) // Initialize to 0, Oracle will update with actual transaction hash
        });
        
        // Add to user review list
        userReviews[_msgSender()].push(reviewId);
        
        nextReviewId++;
        
        emit ReviewSubmitted(reviewId, _msgSender(), scenicId);
    }
       
   
    /**
     * @dev Internal function: Process approved review
     * @param reviewId Review ID
     */
    function _processApprovedReview(uint256 reviewId) internal {
        Review storage review = reviews[reviewId];
        require(review.user != address(0), "ScenicReviewSystem: Review does not exist");
        require(review.status == ReviewStatus.Pending, "ScenicReviewSystem: Review must be in pending status");
        require(review.scenicId > 0, "ScenicReviewSystem: Invalid scenic spot ID");
        
        // Update review status to approved
        review.status = ReviewStatus.Approved;
        
        // Add to scenic spot review list (only keeps approved reviews)
        scenicReviews[review.scenicId].push(reviewId);
        
        // Increase review count of scenic spot
        scenicSpots[review.scenicId].reviewCount++;
        
        // Update scenic spot average rating (calculated in real-time, multiplied by 10 to store one decimal place)
        // Formula: (current average rating * (current review count - 1) + new rating * 10) / current review count
        uint256 currentTotal = scenicSpots[review.scenicId].averageRating * (scenicSpots[review.scenicId].reviewCount - 1);
        scenicSpots[review.scenicId].averageRating = (currentTotal + (review.rating * 10)) / scenicSpots[review.scenicId].reviewCount;
        
        // Distribute reward
        _rewardReview(reviewId);
        
        // Check if new summary is needed (every 20 approved reviews)
        uint256 currentReviewCount = scenicSpots[review.scenicId].reviewCount;
        if (currentReviewCount % 20 == 0) {
            uint256 lastIndex = scenicSummaries[review.scenicId].lastReviewIndex;
            uint256 fromIndex = lastIndex + 1;
            if(lastIndex == 0){
                fromIndex = 0;
            }
            uint256 toIndex = fromIndex + 19;
            // Notify Oracle to generate new summary, returning the review index of current latest summary
            emit SummaryUpdateRequired(review.scenicId, fromIndex, toIndex, lastIndex);
        }
    }
    
    /**
     * @dev Internal function: Distribute reward for approved review
     * @param reviewId Review ID
     */
    function _rewardReview(uint256 reviewId) internal {
        Review storage review = reviews[reviewId];
        require(review.user != address(0), "ScenicReviewSystem: Review does not exist");
        require(review.status == ReviewStatus.Approved, "ScenicReviewSystem: Review not approved");
        require(!review.rewarded, "ScenicReviewSystem: Reward already issued");
        
        // Get review reward corresponding to user's current level
        uint256 rewardAmount = userLevel.getUserReviewReward(review.user);
        
        // Distribute reward from fund pool
        // Use reward method with description
        (bool success, ) = address(travelToken).call(abi.encodeWithSignature(
            "reward(address,uint256,string)",
            review.user,
            rewardAmount,
            string(abi.encodePacked(scenicSpots[review.scenicId].name, " evaluation accepted"))
        ));
        require(success, "ScenicReviewSystem: Reward issuance failed");
        
        review.rewarded = true;
        review.rewardAmount = rewardAmount;
        emit ReviewRewarded(reviewId, review.user, rewardAmount);
    }
    
    /**
     * @dev Oracle uploads AI summary
     * @param scenicId Scenic spot ID
     * @param content Summary content
     * @param reviewIds List of review IDs used as basis
     * @param lastReviewIndex Index of the last review used for current summary
     */
    function uploadSummary(
        uint256 scenicId,
        string memory content,
        uint256[] calldata reviewIds,
        uint256 lastReviewIndex
    ) external nonReentrant {
        require(_msgSender() == oracleAddress, "ScenicReviewSystem: Only Oracle can upload summary");
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        require(reviewIds.length > 0, "ScenicReviewSystem: Review ID list cannot be empty");
        
        // Check if there's an existing summary, if so save to history
        Summary storage currentSummary = scenicSummaries[scenicId];
        if (currentSummary.timestamp > 0) {
            // Store old summary to history
            scenicHistoricalSummaries[scenicId].push(currentSummary);
            emit HistoricalSummaryStored(scenicId, currentSummary.version, block.timestamp);
        }
        
        // Increment version number
        uint256 newVersion = scenicSummaryVersions[scenicId] + 1;
        scenicSummaryVersions[scenicId] = newVersion;
        
        // Save new summary
        scenicSummaries[scenicId] = Summary({
            scenicId: scenicId,
            content: content,
            reviewIds: reviewIds,
            timestamp: block.timestamp,
            lastReviewIndex: lastReviewIndex,
            version: newVersion,
            txHash: bytes32(0) // Initialize to 0, Oracle will update with actual transaction hash
        });
        
        emit SummaryGenerated(scenicId, reviewIds.length, block.timestamp, newVersion, bytes32(0));
    }
    
    /**
     * @dev Get latest approved reviews for specific scenic spot (Oracle only)
     * @param scenicId Scenic spot ID
     * @param count Number of reviews to get
     * @return Review[] Latest approved review list
     * @return uint256[] Corresponding review ID list
     */
    function getReviewsForSummary(uint256 scenicId, uint256 count) external view returns (Review[] memory, uint256[] memory) {
        require(_msgSender() == oracleAddress, "ScenicReviewSystem: Only Oracle can get review range");
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        
        uint256[] storage allReviewIds = scenicReviews[scenicId];
        uint256 totalApproved = allReviewIds.length;
        
        // Calculate actual number to return (not exceeding total count)
        uint256 actualCount = count;
        if (count > totalApproved) {
            actualCount = totalApproved;
        }
        
        // Create result arrays
        Review[] memory requestedReviews = new Review[](actualCount);
        uint256[] memory requestedReviewIds = new uint256[](actualCount);
        
        // Get the latest actualCount reviews
        for (uint256 i = 0; i < actualCount; i++) {
            // Traverse from the end of the array to get the latest reviews
            uint256 reviewIndex = totalApproved - actualCount + i;
            uint256 reviewId = allReviewIds[reviewIndex];
            requestedReviews[i] = reviews[reviewId];
            requestedReviewIds[i] = reviewId;
        }
        
        return (requestedReviews, requestedReviewIds);
    }
        
    /**
     * @dev Oracle updates review status
     * @param reviewId Review ID
     * @param isApproved Whether it's approved
     */
    function updateReviewStatus(uint256 reviewId, bool isApproved) external nonReentrant {
        require(_msgSender() == oracleAddress || _msgSender() == owner(), "ScenicReviewSystem: Only Oracle or owner can update review status");
        
        Review storage review = reviews[reviewId];
        require(review.user != address(0), "ScenicReviewSystem: Review does not exist");
        require(review.status == ReviewStatus.Pending, "ScenicReviewSystem: Review must be in pending status");
        
        // Update status based on review result
        if (isApproved) {
            _processApprovedReview(reviewId);
        } else {
            review.status = ReviewStatus.Rejected;
        }
        
        // Emit review status update event
        emit ReviewApproved(reviewId, isApproved);
    }
    
    /**
     * @dev Set Oracle address
     * @param _oracleAddress Oracle contract address
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "ScenicReviewSystem: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }
    
    /**
     * @dev Update transaction hashes for review (Oracle only)
     * @param reviewId Review ID
     * @param submitHash Transaction hash of user's review submission
     * @param approveHash Transaction hash of AI review status change
     */
    function updateReviewTxHashes(uint256 reviewId, bytes32 submitHash, bytes32 approveHash) external {
        require(_msgSender() == oracleAddress, "ScenicReviewSystem: Only Oracle can update transaction hash");
        
        Review storage review = reviews[reviewId];
        require(review.user != address(0), "ScenicReviewSystem: Review does not exist");
        
        // Update transaction hashes
        if (submitHash != bytes32(0)) {
            review.submitTxHash = submitHash;
        }
        if (approveHash != bytes32(0)) {
            review.approveTxHash = approveHash;
        }
    }
    
    /**
     * @dev Update transaction hash for summary (Oracle only)
     * @param scenicId Scenic spot ID
     * @param hash Transaction hash of uploaded summary
     */
    function updateSummaryTxHash(uint256 scenicId, bytes32 hash) external {
        require(_msgSender() == oracleAddress, "ScenicReviewSystem: Only Oracle can update transaction hash");
        
        Summary storage summary = scenicSummaries[scenicId];
        require(summary.timestamp > 0, "ScenicReviewSystem: Summary does not exist");
        
        summary.txHash = hash;
    }
    

    
    /**
     * @dev Update UserLevel contract address (admin only)
     * @param userLevelAddress New UserLevel contract address
     */
    function updateUserLevelAddress(address userLevelAddress) external onlyOwner {
        require(userLevelAddress != address(0), "ScenicReviewSystem: UserLevel address cannot be zero");
        userLevel = IUserLevel(userLevelAddress);
    }
    

    
    /**
     * @dev Update FundPool contract address (admin only)
     * @param fundPoolAddress New FundPool contract address
     */
    function updateFundPoolAddress(address fundPoolAddress) external onlyOwner {
        require(fundPoolAddress != address(0), "ScenicReviewSystem: Fund pool address cannot be zero");
        fundPool = IFundPool(fundPoolAddress);
    }
    
    /**
     * @dev User views approved historical review records of scenic spot
     * @param scenicId Scenic spot ID
     * @return Review[] Approved review list
     */
    function getHistoricalReviews(uint256 scenicId) external view returns (Review[] memory) {
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        
        uint256[] storage allReviewIds = scenicReviews[scenicId];
        uint256 totalCount = allReviewIds.length;
        
        // Create result array with size equal to number of reviews
        Review[] memory result = new Review[](totalCount);
        
        // Populate all approved reviews (scenicReviews only contains approved reviews)
        for (uint256 i = 0; i < totalCount; i++) {
            result[i] = reviews[allReviewIds[i]];
        }
        
        return result;
    }
    
    /**
     * @dev Get all review lists for user (no parameters version, returns all reviews)
     * @param user User address
     * @return Review[] All review lists for user
     */
    function getUserReviews(address user) external view returns (Review[] memory) {
        // Only user themselves can view all their reviews
        require(msg.sender == user, "ScenicReviewSystem: Can only view your own review list");
        
        uint256[] storage reviewIds = userReviews[user];
        uint256 totalCount = reviewIds.length;
        
        Review[] memory result = new Review[](totalCount);
        
        for (uint256 i = 0; i < totalCount; i++) {
            result[i] = reviews[reviewIds[i]];
        }
        
        return result;
    }
    
    /**
     * @dev Get all review lists for user (paged version)
     * @param user User address
     * @param start Start index
     * @param end End index
     * @return Review[] All review lists for user
     */
    function getUserReviews(address user, uint256 start, uint256 end) external view returns (Review[] memory) {
        // Only user themselves can view all their reviews
        require(msg.sender == user, "ScenicReviewSystem: Can only view your own review list");
        
        uint256[] storage reviewIds = userReviews[user];
        
        // Ensure requested indices are within valid range
        if (start >= reviewIds.length) {
            return new Review[](0);
        }
        
        uint256 actualEnd = end < reviewIds.length ? end : reviewIds.length - 1;
        uint256 actualCount = actualEnd - start + 1;
        Review[] memory result = new Review[](actualCount);
        
        for (uint256 i = 0; i < actualCount; i++) {
            result[i] = reviews[reviewIds[start + i]];
        }
        
        return result;
    }
    
    /**
     * @dev User views historical summary records of scenic spot
     * @param scenicId Scenic spot ID
     * @return Summary[] Historical summary list
     */
    function getHistoricalSummaries(uint256 scenicId) external view returns (Summary[] memory) {
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        
        Summary[] storage historicalSummaries = scenicHistoricalSummaries[scenicId];
        Summary storage currentSummary = scenicSummaries[scenicId];
        
        // Calculate total number of summaries (historical + current)
        uint256 totalCount = historicalSummaries.length;
        if (currentSummary.timestamp > 0) {
            totalCount++;
        }
        
        // Create result array
        Summary[] memory result = new Summary[](totalCount);
        
        // First populate historical summaries
        for (uint256 i = 0; i < historicalSummaries.length; i++) {
            result[i] = historicalSummaries[i];
        }
        
        // Then add current summary if it exists
        if (currentSummary.timestamp > 0) {
            result[historicalSummaries.length] = currentSummary;
        }
        
        return result;
    }
    
    /**
     * @dev Get total number of historical summaries for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Total number of historical summaries
     */
    function getHistoricalSummaryCount(uint256 scenicId) external view returns (uint256) {
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        Summary storage currentSummary = scenicSummaries[scenicId];
        uint256 count = scenicHistoricalSummaries[scenicId].length;
        if (currentSummary.timestamp > 0) {
            count++;
        }
        return count;
    }
    
    /**
     * @dev Get total number of historical reviews for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Total number of historical reviews
     */
    function getHistoricalReviewsCount(uint256 scenicId) external view returns (uint256) {
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        // Directly return number of approved reviews, since scenicReviews only contains approved reviews
        return scenicReviews[scenicId].length;
    }
    
    /**
     * @dev Get latest summary version for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Latest version number
     */
    function getLatestSummaryVersion(uint256 scenicId) external view returns (uint256) {
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        return scenicSummaryVersions[scenicId];
    }
    
    /**
     * @dev Get list of top 8 scenic spots by average rating
     * @return scenicIds Scenic spot ID array (max 8)
     */
    function getScenicSpotList() external view returns (uint256[] memory scenicIds) {
        // Create temporary arrays to store ratings and IDs of all active scenic spots
        uint256[] memory allScenicIds = new uint256[](nextScenicId - 1);
        uint256[] memory allRatings = new uint256[](nextScenicId - 1);
        uint256 activeCount = 0;
        
        // Collect all active scenic spots
        for (uint256 i = 1; i < nextScenicId; i++) {
            if (scenicSpots[i].active) {
                allScenicIds[activeCount] = i;
                allRatings[activeCount] = scenicSpots[i].averageRating;
                activeCount++;
            }
        }
        
        // Create arrays with actual number of active scenic spots
        uint256[] memory scenicIdsTemp = new uint256[](activeCount);
        uint256[] memory ratingsTemp = new uint256[](activeCount);
        
        for (uint256 i = 0; i < activeCount; i++) {
            scenicIdsTemp[i] = allScenicIds[i];
            ratingsTemp[i] = allRatings[i];
        }
        
        // Bubble sort, descending by rating
        for (uint256 i = 0; i < activeCount; i++) {
            for (uint256 j = i + 1; j < activeCount; j++) {
                if (ratingsTemp[i] < ratingsTemp[j]) {
                    // Swap ratings
                    uint256 tempRating = ratingsTemp[i];
                    ratingsTemp[i] = ratingsTemp[j];
                    ratingsTemp[j] = tempRating;
                    
                    // Swap corresponding scenic spot IDs
                    uint256 tempId = scenicIdsTemp[i];
                    scenicIdsTemp[i] = scenicIdsTemp[j];
                    scenicIdsTemp[j] = tempId;
                }
            }
        }
        
        // Determine number of results to return (max 8)
        uint256 resultCount = activeCount < 8 ? activeCount : 8;
        
        // Create result array
        scenicIds = new uint256[](resultCount);
        
        // Populate result array
        for (uint256 i = 0; i < resultCount; i++) {
            scenicIds[i] = scenicIdsTemp[i];
        }
        
        return scenicIds;
    }
    
    /**
     * @dev Get scenic spot details and latest summary
     * @param scenicId Scenic spot ID
     * @return scenicSpot Scenic spot details
     * @return latestSummary Latest summary information
     */
    function getScenicSpot(uint256 scenicId) external view returns (
        ScenicSpot memory scenicSpot,
        Summary memory latestSummary
    ) {
        require(scenicSpots[scenicId].active, "ScenicReviewSystem: Scenic spot does not exist or is inactive");
        
        // Get scenic spot details
        scenicSpot = scenicSpots[scenicId];
        
        // Get latest summary
        latestSummary = scenicSummaries[scenicId];
        
        return (scenicSpot, latestSummary);
    }
}
