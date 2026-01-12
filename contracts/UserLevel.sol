// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';

// Import shared interface file
import './interfaces/ITravelDApp.sol';

/**
 * @title UserLevel
 * @dev User level system contract
 * @notice Manages user levels, upgrade rules, and upgrade records
 */
contract UserLevel is Ownable, ReentrancyGuard {
    // Level rule structure
struct LevelRule {
    uint256 requiredToken;  // Token amount required for upgrade
    uint256 reviewReward;   // Token reward amount for each accepted review
}
    
    // User level information structure
struct UserLevelInfo {
    uint256 level;         // Current level
    uint256 lastUpgrade;   // Last upgrade timestamp
}
    
    // Level up event
event LevelUp(
        address indexed user,
        uint256 oldLevel,
        uint256 newLevel,
        uint256 consumedToken,
        uint256 timestamp
    );
    
    // Level rule update event
event LevelRuleUpdated(
        uint256 indexed level,
        uint256 requiredToken,
        uint256 reviewReward,
        uint256 timestamp
    );
    
    // Level rule mapping (level => rule)
mapping(uint256 => LevelRule) public levelRules;
    
    // User level information mapping (user address => level information)
mapping(address => UserLevelInfo) public userLevels;
    
    // Maximum level
uint256 public maxLevel;
    
    // Token contract address
    IExtendedERC20 public travelToken;
    
    // Fund pool contract address
    IFundPool public fundPool;
    
    /**
 * @dev Constructor
 * @param tokenAddress TravelToken contract address
 * @param fundPoolAddress FundPool contract address
 */
    constructor(address tokenAddress, address fundPoolAddress) Ownable(msg.sender) {
        require(tokenAddress != address(0), "UserLevel: Token address cannot be zero");
        require(fundPoolAddress != address(0), "UserLevel: Fund pool address cannot be zero");
        travelToken = IExtendedERC20(tokenAddress);
        fundPool = IFundPool(fundPoolAddress);
        
        // Initialize default level rules (using 1e18 as 1 Token unit)
        _setLevelRule(1, 0, 1 ether);   // Lv1: Initial level, 1 Token reward per review
        _setLevelRule(2, 10 ether, 2 ether);  // Lv2: Consume 10 Tokens, 2 Token reward per review
        _setLevelRule(3, 20 ether, 3 ether);  // Lv3: Consume 20 Tokens, 3 Token reward per review
        maxLevel = 3;
    }
    
    /**
 * @dev Set level rules (admin only)
 * @param level Level
 * @param requiredToken Token amount required for upgrade
 * @param reviewReward Token reward amount for each accepted review
 */
    function setLevelRule(
        uint256 level,
        uint256 requiredToken,
        uint256 reviewReward
    ) external onlyOwner {
        _setLevelRule(level, requiredToken, reviewReward);
        
        // Update maximum level
        if (level > maxLevel) {
            maxLevel = level;
        }
        
        emit LevelRuleUpdated(level, requiredToken, reviewReward, block.timestamp);
    }
    
    /**
     * @dev Internal function to set level rules
     */
    function _setLevelRule(
        uint256 level,
        uint256 requiredToken,
        uint256 reviewReward
    ) internal {
        require(level > 0, "UserLevel: Level must be greater than 0");
        levelRules[level] = LevelRule(requiredToken, reviewReward);
    }
    
    /**
     * @dev User level upgrade
     * @notice Automatically upgrades by 1 level from current level
     */
    function upgrade() external nonReentrant {
        UserLevelInfo storage userInfo = userLevels[_msgSender()];
        
        // Get user's current level (ensure new users start at level 1)
        uint256 currentLevel = userInfo.level == 0 ? 1 : userInfo.level;
        
        // Calculate target level (current level + 1)
        uint256 targetLevel = currentLevel + 1;
        
        // Ensure target level does not exceed maximum level
        require(targetLevel <= maxLevel, "UserLevel: Already at maximum level");
        
        // Get token amount required for upgrade
        LevelRule storage rule = levelRules[targetLevel];
        uint256 requiredToken = rule.requiredToken;
        
        // Ensure user has sufficient tokens
        require(travelToken.balanceOf(_msgSender()) >= requiredToken, "UserLevel: Insufficient token balance");
        
        // Use consume method to burn tokens, standardize transaction record type
        travelToken.consume(
            _msgSender(),
            requiredToken,
            keccak256(abi.encodePacked("LevelUpgrade", targetLevel)),
            string(abi.encodePacked("User upgrades to Lv", Strings.toString(targetLevel)))
        );
        
        // Update user level information
        uint256 oldLevel = currentLevel;
        userInfo.level = targetLevel;
        userInfo.lastUpgrade = block.timestamp;
        
        // Emit level up event
        emit LevelUp(
            _msgSender(),
            oldLevel,
            targetLevel,
            requiredToken,
            block.timestamp
        );
    }
    
    /**
     * @dev Get user level information
     * @param user User address
     * @return UserLevelInfo User level information
     */
    function getUserLevelInfo(address user) external view returns (UserLevelInfo memory) {
        UserLevelInfo memory info = userLevels[user];
        // If user has no level information, initialize to Lv1
        if (info.level == 0) {
            return UserLevelInfo(1, 0);
        }
        return info;
    }
    
    /**
     * @dev Get review reward token amount for specified level
     * @param level Level
     * @return uint256 Review reward token amount
     */
    function getReviewReward(uint256 level) external view returns (uint256) {
        require(level > 0 && level <= maxLevel, "UserLevel: Invalid level");
        return levelRules[level].reviewReward;
    }
    
    /**
     * @dev Get review reward token amount for user's current level
     * @param user User address
     * @return uint256 Review reward token amount
     */
    function getUserReviewReward(address user) external view returns (uint256) {
        uint256 level = getUserLevel(user);
        return levelRules[level].reviewReward;
    }
    
    /**
     * @dev Get user's current level
     * @param user User address
     * @return uint256 User level
     */
    function getUserLevel(address user) public view returns (uint256) {
        UserLevelInfo memory info = userLevels[user];
        return info.level == 0 ? 1 : info.level;
    }
    
    /**
     * @dev Update Token contract address (admin only)
     * @param tokenAddress New Token contract address
     */
    function updateTokenAddress(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "UserLevel: Token address cannot be zero");
        // Use interface conversion to ensure type safety
        travelToken = IExtendedERC20(tokenAddress);
    }
    
    /**
     * @dev Update FundPool contract address (admin only)
     * @param fundPoolAddress New FundPool contract address
     */
    function updateFundPoolAddress(address fundPoolAddress) external onlyOwner {
        require(fundPoolAddress != address(0), "UserLevel: Fund pool address cannot be zero");
        fundPool = IFundPool(fundPoolAddress);
    }
}
