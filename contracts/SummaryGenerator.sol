// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IScenicReviewCore} from './interfaces/IScenicReviewCore.sol';
import {ISummaryGenerator} from './interfaces/ISummaryGenerator.sol';
import {IScenicStorage} from './interfaces/IScenicStorage.sol';
import './interfaces/ITravelDApp.sol';

/**
 * @title SummaryGenerator
 * @dev Summary generation contract
 * @notice Responsible for managing review summary storage, history records and query functions
 */
contract SummaryGenerator is Ownable, ReentrancyGuard, ISummaryGenerator {
    // Subcontract addresses
    address public scenicStorageAddr;
    address public scenicReviewCoreAddr;
    
    // Oracle address
    address public oracleAddress;
    
    // Scenic spot summary mapping (scenicId => summary info)
    mapping(uint256 => IScenicReviewCore.Summary) private _scenicSummaries;
    
    // Scenic spot historical summary mapping (scenicId => historical summary list)
    mapping(uint256 => IScenicReviewCore.Summary[]) private _scenicHistoricalSummaries;
    
    // Scenic spot summary version counter mapping (scenicId => version)
    mapping(uint256 => uint256) private _scenicSummaryVersions;
    
    // Event definitions
    event SummaryGenerated(uint256 indexed scenicId, uint256 reviewIdsCount, uint256 timestamp, uint256 version, bytes32 txHash);
    event HistoricalSummaryStored(uint256 indexed scenicId, uint256 version, uint256 timestamp);
    
    /**
     * @dev Constructor
     */
    constructor() Ownable(msg.sender) {
        
    }
    
    /**
     * @dev Set subcontract addresses
     * @param _scenicStorageAddr Scenic spot storage contract address
     * @param _scenicReviewCoreAddr Core contract address
     */
    function setSubContractAddresses(address _scenicStorageAddr, address _scenicReviewCoreAddr) external onlyOwner {
        require(_scenicStorageAddr != address(0), "SummaryGenerator: ScenicStorage address cannot be zero");
        require(_scenicReviewCoreAddr != address(0), "SummaryGenerator: ScenicReviewCore address cannot be zero");
        
        scenicStorageAddr = _scenicStorageAddr;
        scenicReviewCoreAddr = _scenicReviewCoreAddr;
    }
    
    /**
     * @dev Set Oracle address
     * @param _oracleAddress Oracle contract address
     */
    function setOracleAddress(address _oracleAddress) external onlyOwner {
        require(_oracleAddress != address(0), "SummaryGenerator: Oracle address cannot be zero");
        oracleAddress = _oracleAddress;
    }
    
    /**
     * @dev Upload AI summary
     * @param scenicId Scenic spot ID
     * @param content Summary content
     * @param reviewIds List of review IDs based on the summary
     * @param lastReviewIndex Index of the last review used for the current summary
     */
    function uploadSummary(
        uint256 scenicId,
        string memory content,
        uint256[] calldata reviewIds,
        uint256 lastReviewIndex
    ) external override nonReentrant {
        require(msg.sender == oracleAddress || msg.sender == scenicReviewCoreAddr, "SummaryGenerator: Only Oracle or core contract can upload summary");
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "SummaryGenerator: Scenic spot does not exist or is inactive");
        require(reviewIds.length > 0, "SummaryGenerator: Review ID list cannot be empty");
        
        // Check if there's an existing summary, if so save to history
        IScenicReviewCore.Summary storage currentSummary = _scenicSummaries[scenicId];
        if (currentSummary.timestamp > 0) {
            // Store old summary to history
            _scenicHistoricalSummaries[scenicId].push(currentSummary);
            emit HistoricalSummaryStored(scenicId, currentSummary.version, block.timestamp);
        }
        
        // Increment version number
        uint256 newVersion = _scenicSummaryVersions[scenicId] + 1;
        _scenicSummaryVersions[scenicId] = newVersion;
        
        // Save new summary
        _scenicSummaries[scenicId] = IScenicReviewCore.Summary({
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
     * @dev Get latest summary for scenic spot
     * @param scenicId Scenic spot ID
     * @return Summary Latest summary information
     */
    function getLatestSummary(uint256 scenicId) external view override returns (IScenicReviewCore.Summary memory) {
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "SummaryGenerator: Scenic spot does not exist or is inactive");
        return _scenicSummaries[scenicId];
    }
    
    /**
     * @dev Get historical summary records for scenic spot
     * @param scenicId Scenic spot ID
     * @return Summary[] Historical summary list
     */
    function getHistoricalSummaries(uint256 scenicId) external view override returns (IScenicReviewCore.Summary[] memory) {
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "SummaryGenerator: Scenic spot does not exist or is inactive");
        
        IScenicReviewCore.Summary[] storage historicalSummaries = _scenicHistoricalSummaries[scenicId];
        IScenicReviewCore.Summary storage currentSummary = _scenicSummaries[scenicId];
        
        // Calculate total number of summaries (historical + current)
        uint256 totalCount = historicalSummaries.length;
        if (currentSummary.timestamp > 0) {
            totalCount++;
        }
        
        // Create result array
        IScenicReviewCore.Summary[] memory result = new IScenicReviewCore.Summary[](totalCount);
        
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
    function getHistoricalSummaryCount(uint256 scenicId) external view override returns (uint256) {
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "SummaryGenerator: Scenic spot does not exist or is inactive");
        IScenicReviewCore.Summary storage currentSummary = _scenicSummaries[scenicId];
        uint256 count = _scenicHistoricalSummaries[scenicId].length;
        if (currentSummary.timestamp > 0) {
            count++;
        }
        return count;
    }
    
    /**
     * @dev Get latest summary version for scenic spot
     * @param scenicId Scenic spot ID
     * @return uint256 Latest version number
     */
    function getLatestSummaryVersion(uint256 scenicId) external view override returns (uint256) {
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "SummaryGenerator: Scenic spot does not exist or is inactive");
        return _scenicSummaryVersions[scenicId];
    }
    
    /**
     * @dev Update transaction hash for summary
     * @param scenicId Scenic spot ID
     * @param hash Transaction hash of the uploaded summary
     */
    function updateSummaryTxHash(uint256 scenicId, bytes32 hash) external override {
        require(msg.sender == oracleAddress, "SummaryGenerator: Only Oracle can update transaction hash");
        require(IScenicStorage(scenicStorageAddr).isScenicActive(scenicId), "SummaryGenerator: Scenic spot does not exist or is inactive");
        
        IScenicReviewCore.Summary storage summary = _scenicSummaries[scenicId];
        require(summary.timestamp > 0, "SummaryGenerator: Summary does not exist");
        
        summary.txHash = hash;
    }
}
