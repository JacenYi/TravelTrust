// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IScenicReviewCore} from './IScenicReviewCore.sol';

/**
 * @title IReviewProcessor
 * @dev Review processor contract interface
 */
interface IReviewProcessor {
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
    ) external;
    
    /**
     * @dev Update review status
     * @param reviewId Review ID
     * @param isApproved Whether it's approved
     */
    function updateReviewStatus(uint256 reviewId, bool isApproved) external;
    
    /**
     * @dev Distribute reward for review
     * @param reviewId Review ID
     */
    function rewardReview(uint256 reviewId) external;
    
    /**
     * @dev Get review information
     * @param reviewId Review ID
     * @return Review Review information
     */
    function getReview(uint256 reviewId) external view returns (IScenicReviewCore.Review memory);
    
    /**
     * @dev Get user's review list
     * @param user User address
     * @return Review[] User's review list
     */
    function getUserReviews(address user) external view returns (IScenicReviewCore.Review[] memory);
    
    /**
     * @dev Get user's review list (paged)
     * @param user User address
     * @param start Start index
     * @param end End index
     * @return Review[] User's review list
     */
    function getUserReviews(address user, uint256 start, uint256 end) external view returns (IScenicReviewCore.Review[] memory);
    
    /**
     * @dev Get approved review list for scenic spot
     * @param scenicId Scenic spot ID
     * @param count Number of reviews to get
     * @return Review[] Latest approved review list
     * @return uint256[] Corresponding review ID list
     */
    function getReviewsForSummary(uint256 scenicId, uint256 count) external view returns (IScenicReviewCore.Review[] memory, uint256[] memory);
    
    /**
     * @dev Get total number of historical reviews for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Total number of historical reviews
     */
    function getHistoricalReviewsCount(uint256 scenicId) external view returns (uint256);
    
    /**
     * @dev Get historical review records for scenic spot
     * @param scenicId Scenic spot ID
     * @return Review[] Approved review list
     */
    function getHistoricalReviews(uint256 scenicId) external view returns (IScenicReviewCore.Review[] memory);
    
    /**
     * @dev Update transaction hashes for review
     * @param reviewId Review ID
     * @param submitHash Transaction hash of user's review submission
     * @param approveHash Transaction hash of AI review status change
     */
    function updateReviewTxHashes(uint256 reviewId, bytes32 submitHash, bytes32 approveHash) external;
    
    /**
     * @dev Get next review ID
     * @return uint256 Next review ID
     */
    function getNextReviewId() external view returns (uint256);
    
    /**
     * @dev Validate JSON format review content
     * @param jsonStr JSON string to validate
     * @return bool Whether it's valid JSON format
     */
    function validateReviewJson(string memory jsonStr) external pure returns (bool);
}
