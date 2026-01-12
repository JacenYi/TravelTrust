// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IScenicReviewCore} from './interfaces/IScenicReviewCore.sol';
import {IScenicStorage} from './interfaces/IScenicStorage.sol';
import {IReviewProcessor} from './interfaces/IReviewProcessor.sol';
import {ISummaryGenerator} from './interfaces/ISummaryGenerator.sol';
import './interfaces/ITravelDApp.sol';

/**
 * @title ScenicReviewCore
 * @dev Scenic spot review system core contract
 * @notice Serves as the entry point for the entire system, managing sub-contract addresses and forwarding calls
 */
contract ScenicReviewCore is Ownable, ReentrancyGuard, IScenicReviewCore {
    // Subcontract addresses
    address public scenicStorageAddr;
    address public reviewProcessorAddr;
    address public summaryGeneratorAddr;
    
    // Oracle address
    address public oracleAddress;
    
    // Events are already defined in the interface, no need to redefine
    
    /**
     * @dev Constructor
     * @param initialOwner Initial owner address
     */
    constructor(address initialOwner) Ownable(initialOwner) {}
    
    /**
     * @dev Set Oracle address
     * @param _oracleAddress Oracle contract address
     */
    function setOracleAddress(address _oracleAddress) external override onlyOwner {
        require(_oracleAddress != address(0), "ScenicReviewCore: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }
    
    /**
     * @dev Get Oracle address
     * @return address Oracle contract address
     */
    function getOracleAddress() external view override returns (address) {
        return oracleAddress;
    }
    
    /**
     * @dev Set various subcontract addresses
     * @param _scenicStorageAddr Scenic spot storage contract address
     * @param _reviewProcessorAddr Review processor contract address
     * @param _summaryGeneratorAddr Summary generator contract address
     */
    function setSubContractAddresses(
        address _scenicStorageAddr,
        address _reviewProcessorAddr,
        address _summaryGeneratorAddr
    ) external override onlyOwner {
        require(_scenicStorageAddr != address(0), "ScenicReviewCore: ScenicStorage address cannot be zero");
        require(_reviewProcessorAddr != address(0), "ScenicReviewCore: ReviewProcessor address cannot be zero");
        require(_summaryGeneratorAddr != address(0), "ScenicReviewCore: SummaryGenerator address cannot be zero");
        
        scenicStorageAddr = _scenicStorageAddr;
        reviewProcessorAddr = _reviewProcessorAddr;
        summaryGeneratorAddr = _summaryGeneratorAddr;
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
        IScenicStorage(scenicStorageAddr).addScenicSpot(name, location, description, tags);
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
        IReviewProcessor(reviewProcessorAddr).submitReview(scenicId, content, rating, msg.sender);
    }
    
    /**
     * @dev Update review status
     * @param reviewId Review ID
     * @param isApproved Whether it's approved
     */
    function updateReviewStatus(uint256 reviewId, bool isApproved) external nonReentrant {
        require(msg.sender == oracleAddress || msg.sender == owner(), "ScenicReviewCore: Only Oracle or owner can update review status");
        IReviewProcessor(reviewProcessorAddr).updateReviewStatus(reviewId, isApproved);
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
        require(msg.sender == oracleAddress, "ScenicReviewCore: Only Oracle can upload summary");
        ISummaryGenerator(summaryGeneratorAddr).uploadSummary(scenicId, content, reviewIds, lastReviewIndex);
    }
    
    /**
     * @dev Get latest approved reviews for specific scenic spot (Oracle only)
     * @param scenicId Scenic spot ID
     * @param count Number of reviews to get
     * @return Review[] Latest approved review list
     * @return uint256[] Corresponding review ID list
     */
    function getReviewsForSummary(uint256 scenicId, uint256 count) external view returns (Review[] memory, uint256[] memory) {
        require(msg.sender == oracleAddress, "ScenicReviewCore: Only Oracle can get review range");
        return IReviewProcessor(reviewProcessorAddr).getReviewsForSummary(scenicId, count);
    }
    
    /**
     * @dev Update transaction hashes for review (Oracle only)
     * @param reviewId Review ID
     * @param submitHash Transaction hash of user's review submission
     * @param approveHash Transaction hash of AI review status change
     */
    function updateReviewTxHashes(uint256 reviewId, bytes32 submitHash, bytes32 approveHash) external {
        require(msg.sender == oracleAddress, "ScenicReviewCore: Only Oracle can update transaction hash");
        IReviewProcessor(reviewProcessorAddr).updateReviewTxHashes(reviewId, submitHash, approveHash);
    }
    
    /**
     * @dev Update transaction hash for summary (Oracle only)
     * @param scenicId Scenic spot ID
     * @param hash Transaction hash of uploaded summary
     */
    function updateSummaryTxHash(uint256 scenicId, bytes32 hash) external {
        require(msg.sender == oracleAddress, "ScenicReviewCore: Only Oracle can update transaction hash");
        ISummaryGenerator(summaryGeneratorAddr).updateSummaryTxHash(scenicId, hash);
    }
    
    /**
     * @dev Get latest approved review records for specific scenic spot
     * @param scenicId Scenic spot ID
     * @return Review[] Approved review list
     */
    function getHistoricalReviews(uint256 scenicId) external view returns (Review[] memory) {
        return IReviewProcessor(reviewProcessorAddr).getHistoricalReviews(scenicId);
    }
    
    /**
     * @dev Get all review lists for user (no parameters version, returns all reviews)
     * @param user User address
     * @return Review[] All review lists for user
     */
    function getUserReviews(address user) external view returns (Review[] memory) {
        return IReviewProcessor(reviewProcessorAddr).getUserReviews(user);
    }
    
    /**
     * @dev Get all review lists for user (paged version)
     * @param user User address
     * @param start Start index
     * @param end End index
     * @return Review[] All review lists for user
     */
    function getUserReviews(address user, uint256 start, uint256 end) external view returns (Review[] memory) {
        return IReviewProcessor(reviewProcessorAddr).getUserReviews(user, start, end);
    }
    
    /**
     * @dev User views historical summary records of scenic spot
     * @param scenicId Scenic spot ID
     * @return Summary[] Historical summary list
     */
    function getHistoricalSummaries(uint256 scenicId) external view returns (Summary[] memory) {
        return ISummaryGenerator(summaryGeneratorAddr).getHistoricalSummaries(scenicId);
    }
    
    /**
     * @dev Get total number of historical summaries for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Total number of historical summaries
     */
    function getHistoricalSummaryCount(uint256 scenicId) external view returns (uint256) {
        return ISummaryGenerator(summaryGeneratorAddr).getHistoricalSummaryCount(scenicId);
    }
    
    /**
     * @dev Get total number of historical reviews for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Total number of historical reviews
     */
    function getHistoricalReviewsCount(uint256 scenicId) external view returns (uint256) {
        return IReviewProcessor(reviewProcessorAddr).getHistoricalReviewsCount(scenicId);
    }
    
    /**
     * @dev Get latest summary version for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Latest version number
     */
    function getLatestSummaryVersion(uint256 scenicId) external view returns (uint256) {
        return ISummaryGenerator(summaryGeneratorAddr).getLatestSummaryVersion(scenicId);
    }
    
    /**
     * @dev Get list of top 8 scenic spots by average rating
     * @return scenicIds Scenic spot ID array (max 8)
     */
    function getScenicSpotList() external view returns (uint256[] memory scenicIds) {
        return IScenicStorage(scenicStorageAddr).getTopScenicSpots();
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
        scenicSpot = IScenicStorage(scenicStorageAddr).getScenicSpot(scenicId);
        latestSummary = ISummaryGenerator(summaryGeneratorAddr).getLatestSummary(scenicId);
        return (scenicSpot, latestSummary);
    }
}
