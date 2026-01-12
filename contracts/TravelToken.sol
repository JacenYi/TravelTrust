// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title TravelToken
 * @dev Base token contract for travel DApp system
 * @notice Standard ERC20 token used for rewards, consumption and level upgrades within the system
 * @dev Fund pool is managed by separate FundPool contract
 */
contract TravelToken is ERC20, Ownable, ReentrancyGuard {
    // Token consumption event
    event TokenConsumed(address indexed user, uint256 amount, bytes32 indexed reason);
    
    // Token transaction history event
    event TokenTransaction(address indexed user, address indexed from, address indexed to, uint256 amount, string action, uint256 timestamp);
    
    // Fund pool contract address
    address public immutable fundsPool;
    
    // Token transaction structure
    struct TokenTransactionRecord {
        uint256 id;
        address from;
        address to;
        uint256 amount;
        string action;
        string description;
        uint256 timestamp;
    }
    
    // User transaction history records
    mapping(address => TokenTransactionRecord[]) public userTransactions;
    
    // Global transaction ID
    uint256 public nextTransactionId;
    
    /**
     * @dev Constructor
     * @param name Token name
     * @param symbol Token symbol
     * @param initialSupply Initial supply (18 decimals)
     * @param fundPoolAddress Fund pool contract address
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address fundPoolAddress
    ) ERC20(name, symbol) Ownable(msg.sender) {
        require(fundPoolAddress != address(0), "TravelToken: Fund pool address cannot be zero");
        // Set fund pool contract address
        fundsPool = fundPoolAddress;
        // Mint initial supply to fund pool
        _mint(fundsPool, initialSupply);
        // Initialize transaction ID
        nextTransactionId = 1;
    }
    
    /**
     * @dev Record token transaction (with description)
     */
    function _recordTransaction(address user, address from, address to, uint256 amount, string memory action, string memory description) internal {
        userTransactions[user].push(TokenTransactionRecord({
            id: nextTransactionId,
            from: from,
            to: to,
            amount: amount,
            action: action,
            description: description,
            timestamp: block.timestamp
        }));
        
        emit TokenTransaction(user, from, to, amount, action, block.timestamp);
        nextTransactionId++;
    }
    
    /**
     * @dev Record token transaction (compatible with old version)
     */
    function _recordTransaction(address user, address from, address to, uint256 amount, string memory action) internal {
        _recordTransaction(user, from, to, amount, action, "");
    }
    
    /**
     * @dev Transfer tokens from fund pool to user (authorized contracts only)
     * @param to User address receiving the reward
     * @param amount Reward amount
     */
    function reward(address to, uint256 amount) external nonReentrant {
        require(to != address(0), "TravelToken: Cannot reward to zero address");
        require(amount > 0, "TravelToken: Reward amount must be greater than 0");
        
        // Transfer tokens from fund pool
        _transfer(fundsPool, to, amount);
        
        // Record transaction
        _recordTransaction(to, fundsPool, to, amount, "REWARD", "System reward");
    }
    
    /**
     * @dev Transfer tokens from fund pool to user (version with description)
     * @param to User address receiving the reward
     * @param amount Reward amount
     * @param description Reward description
     */
    function reward(address to, uint256 amount, string calldata description) external nonReentrant {
        require(to != address(0), "TravelToken: Cannot reward to zero address");
        require(amount > 0, "TravelToken: Reward amount must be greater than 0");
        
        // Transfer tokens from fund pool
        _transfer(fundsPool, to, amount);
        
        // Record transaction
        _recordTransaction(to, fundsPool, to, amount, "REWARD", description);
    }
        
    /**
     * @dev Consume tokens (version with description)
     * @param user User address
     * @param amount Consumption amount
     * @param reason Consumption reason
     * @param description Consumption description
     */
    function consume(address user, uint256 amount, bytes32 reason, string calldata description) external nonReentrant {
        require(user != address(0), "TravelToken: User address cannot be zero");
        require(amount > 0, "TravelToken: Consumption amount must be greater than 0");
        require(balanceOf(user) >= amount, "TravelToken: Insufficient balance");
        
        // Transfer consumed tokens to fund pool
        _transfer(user, fundsPool, amount);
        
        // Record consumption event
        emit TokenConsumed(user, amount, reason);
        
        // Record transaction
        _recordTransaction(user, user, fundsPool, amount, "CONSUME", description);
    }
    
    /**
     * @dev Mint tokens (admin only, can only mint to fund pool)
     * @param amount Mint amount
     */
    function mintToFundsPool(uint256 amount) external onlyOwner nonReentrant {
        require(amount > 0, "TravelToken: Mint amount must be greater than 0");
        
        // Mint tokens to fund pool
        _mint(fundsPool, amount);
        
        // Record transaction
        _recordTransaction(fundsPool, address(0), fundsPool, amount, "MINT");
    }
    
    /**
     * @dev Withdraw funds from fund pool (admin only)
     * @param to Transfer target address
     * @param amount Transfer amount
     */
    function transferFromFundsPool(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "TravelToken: Cannot transfer to zero address");
        require(amount > 0, "TravelToken: Transfer amount must be greater than 0");
        
        _transfer(fundsPool, to, amount);
        
        // Record transaction
        _recordTransaction(to, fundsPool, to, amount, "WITHDRAW");
    }
    
    /**
     * @dev Get user's transaction history records
     * @param user User address
     * @param start Start index
     * @param end End index
     * @return TokenTransactionRecord[] User's transaction history records
     */
    function getUserTransactions(address user, uint256 start, uint256 end) external view returns (TokenTransactionRecord[] memory) {
        TokenTransactionRecord[] storage transactions = userTransactions[user];
        uint256 length = transactions.length;
        
        if (start >= length) {
            return new TokenTransactionRecord[](0);
        }
        
        uint256 actualEnd = end < length ? end : length - 1;
        uint256 actualLength = actualEnd - start + 1;
        
        TokenTransactionRecord[] memory result = new TokenTransactionRecord[](actualLength);
        for (uint256 i = 0; i < actualLength; i++) {
            result[i] = transactions[start + i];
        }
        
        return result;
    }
    
    /**
     * @dev Get user's total transaction count
     * @param user User address
     * @return uint256 User's total transaction count
     */
    function getUserTransactionCount(address user) external view returns (uint256) {
        return userTransactions[user].length;
    }
}
