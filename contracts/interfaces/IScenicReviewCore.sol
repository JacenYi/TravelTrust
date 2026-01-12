// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title IScenicReviewCore
 * @dev Scenic spot review system core interface
 */
interface IScenicReviewCore {
    // Review status enum
enum ReviewStatus {
    Pending,    // Pending review
    Approved,   // Approved
    Rejected    // Rejected
}

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
    
    /**
     * @dev Set Oracle address
     * @param _oracleAddress Oracle contract address
     */
    function setOracleAddress(address _oracleAddress) external;
    
    /**
     * @dev Get Oracle address
     * @return address Oracle contract address
     */
    function getOracleAddress() external view returns (address);
    
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
    ) external;
}
