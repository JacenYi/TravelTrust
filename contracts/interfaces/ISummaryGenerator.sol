// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IScenicReviewCore} from './IScenicReviewCore.sol';

/**
 * @title ISummaryGenerator
 * @dev Summary generator contract interface
 */
interface ISummaryGenerator {
    /**
     * @dev Upload AI summary
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
    ) external;
    
    /**
     * @dev Get latest summary for scenic spot
     * @param scenicId Scenic spot ID
     * @return Summary Latest summary information
     */
    function getLatestSummary(uint256 scenicId) external view returns (IScenicReviewCore.Summary memory);
    
    /**
     * @dev Get historical summary records for scenic spot
     * @param scenicId Scenic spot ID
     * @return Summary[] Historical summary list
     */
    function getHistoricalSummaries(uint256 scenicId) external view returns (IScenicReviewCore.Summary[] memory);
    
    /**
     * @dev Get total number of historical summaries for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Total number of historical summaries
     */
    function getHistoricalSummaryCount(uint256 scenicId) external view returns (uint256);
    
    /**
     * @dev Get latest summary version for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Latest version number
     */
    function getLatestSummaryVersion(uint256 scenicId) external view returns (uint256);
    
    /**
     * @dev Update transaction hash for summary
     * @param scenicId Scenic spot ID
     * @param hash Transaction hash of uploaded summary
     */
    function updateSummaryTxHash(uint256 scenicId, bytes32 hash) external;
}
