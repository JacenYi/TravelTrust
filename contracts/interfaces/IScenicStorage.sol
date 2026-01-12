// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IScenicReviewCore} from './IScenicReviewCore.sol';

/**
 * @title IScenicStorage
 * @dev Scenic spot storage contract interface
 */
interface IScenicStorage {
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
    ) external;
    
    /**
     * @dev Get scenic spot information
     * @param scenicId Scenic spot ID
     * @return ScenicSpot Scenic spot information
     */
    function getScenicSpot(uint256 scenicId) external view returns (IScenicReviewCore.ScenicSpot memory);
    
    /**
     * @dev Update scenic spot review count and average rating
     * @param scenicId Scenic spot ID
     * @param newRating Rating of the new review
     */
    function updateScenicRating(uint256 scenicId, uint256 newRating) external;
    
    /**
     * @dev Verify if scenic spot exists and is active
     * @param scenicId Scenic spot ID
     * @return bool Whether it exists and is active
     */
    function isScenicActive(uint256 scenicId) external view returns (bool);
    
    /**
     * @dev Get list of top 8 scenic spots by average rating
     * @return uint256[] Scenic spot ID array
     */
    function getTopScenicSpots() external view returns (uint256[] memory);
    
    /**
     * @dev Get next scenic spot ID
     * @return uint256 Next scenic spot ID
     */
    function getNextScenicId() external view returns (uint256);
}
