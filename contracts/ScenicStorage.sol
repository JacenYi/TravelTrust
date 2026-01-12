// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {IScenicReviewCore} from './interfaces/IScenicReviewCore.sol';
import {IScenicStorage} from './interfaces/IScenicStorage.sol';

/**
 * @title ScenicStorage
 * @dev Scenic spot storage contract
 * @notice Responsible for managing scenic spot information, including adding spots, getting info, updating ratings, etc.
 */
contract ScenicStorage is Ownable, IScenicStorage {
    // Core contract address
    address public scenicReviewCoreAddr;
    
    // Permission check modifier
    modifier onlyCore() {
        require(msg.sender == scenicReviewCoreAddr, "ScenicStorage: Only core contract can call this method");
        _;
    }
    // Scenic spot mapping (ID => scenic spot info)
    mapping(uint256 => IScenicReviewCore.ScenicSpot) private _scenicSpots;
    
    // Next scenic spot ID
    uint256 private _nextScenicId;
    
    // Event definitions
    event ScenicSpotAdded(uint256 indexed scenicId, string name, string location);
    
    /**
     * @dev Constructor
     */
    constructor() Ownable(msg.sender) {
        // Initialize parameters
        _nextScenicId = 1;
    }
    
    /**
     * @dev Set core contract address
     * @param _scenicReviewCoreAddr Core contract address
     */
    function setScenicReviewCoreAddr(address _scenicReviewCoreAddr) external onlyOwner {
        require(_scenicReviewCoreAddr != address(0), "ScenicStorage: Core contract address cannot be zero");
        scenicReviewCoreAddr = _scenicReviewCoreAddr;
    }
    
    /**
     * @dev Add scenic spot
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
    ) external override onlyCore {
        uint256 scenicId = _nextScenicId;
        _scenicSpots[scenicId] = IScenicReviewCore.ScenicSpot({
            scenicId: scenicId,
            name: name,
            location: location,
            description: description,
            tags: tags,
            reviewCount: 0,
            averageRating: 0,
            active: true
        });
        
        _nextScenicId++;
        emit ScenicSpotAdded(scenicId, name, location);
    }
    
    /**
     * @dev Get scenic spot information
     * @param scenicId Scenic spot ID
     * @return ScenicSpot Scenic spot information
     */
    function getScenicSpot(uint256 scenicId) external view override returns (IScenicReviewCore.ScenicSpot memory) {
        return _scenicSpots[scenicId];
    }
    
    /**
     * @dev Update scenic spot review count and average rating
     * @param scenicId Scenic spot ID
     * @param newRating Rating of the new review
     */
    function updateScenicRating(uint256 scenicId, uint256 newRating) external override onlyCore {
        IScenicReviewCore.ScenicSpot storage scenicSpot = _scenicSpots[scenicId];
        require(scenicSpot.active, "ScenicStorage: Scenic spot does not exist or is inactive");
        require(newRating >= 1 && newRating <= 10, "ScenicStorage: Rating must be between 1 and 10");
        
        // Update review count and average rating
        scenicSpot.reviewCount++;
        uint256 currentTotal = scenicSpot.averageRating * (scenicSpot.reviewCount - 1);
        scenicSpot.averageRating = (currentTotal + (newRating * 10)) / scenicSpot.reviewCount;
    }
    
    /**
     * @dev Verify if scenic spot exists and is active
     * @param scenicId Scenic spot ID
     * @return bool Whether it exists and is active
     */
    function isScenicActive(uint256 scenicId) external view override returns (bool) {
        return _scenicSpots[scenicId].active;
    }
    
    /**
     * @dev Get list of top 8 scenic spots by average rating
     * @return uint256[] Scenic spot ID array
     */
    function getTopScenicSpots() external view override returns (uint256[] memory) {
        // Create temporary arrays to store ratings and IDs of all active scenic spots
        uint256[] memory allScenicIds = new uint256[](_nextScenicId - 1);
        uint256[] memory allRatings = new uint256[](_nextScenicId - 1);
        uint256 activeCount = 0;
        
        // Collect all active scenic spots
        for (uint256 i = 1; i < _nextScenicId; i++) {
            if (_scenicSpots[i].active) {
                allScenicIds[activeCount] = i;
                allRatings[activeCount] = _scenicSpots[i].averageRating;
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
        uint256[] memory scenicIds = new uint256[](resultCount);
        
        // Populate result array
        for (uint256 i = 0; i < resultCount; i++) {
            scenicIds[i] = scenicIdsTemp[i];
        }
        
        return scenicIds;
    }
    
    /**
     * @dev Get next scenic spot ID
     * @return uint256 Next scenic spot ID
     */
    function getNextScenicId() external view override returns (uint256) {
        return _nextScenicId;
    }
}
