// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title FundPool
 * @dev Travel DApp fund pool contract
 * @notice Manages centralized storage and distribution of system funds
 */
contract FundPool is Ownable, ReentrancyGuard {
    // Event definitions
    event FundsReceived(address indexed from, uint256 amount, bytes32 indexed reason);
    event FundsDistributed(address indexed to, uint256 amount, bytes32 indexed purpose);
    event ContractAuthorized(address indexed contractAddress, bool authorized);
    
    // Authorized contracts mapping (contracts allowed to distribute funds from pool)
    mapping(address => bool) public authorizedContracts;
    
    // Token contract address
    IERC20 public travelToken;
    
    /**
     * @dev Constructor
     */
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev Set token contract address (admin only)
     * @param tokenAddress TravelToken contract address
     */
    function setTravelToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "FundPool: Token address cannot be zero");
        travelToken = IERC20(tokenAddress);
    }
    
    /**
     * @dev Authorize/unauthorize contract (admin only)
     * @param contractAddress Contract address
     * @param authorized Whether to authorize
     */
    function authorizeContract(address contractAddress, bool authorized) external onlyOwner {
        require(contractAddress != address(0), "FundPool: Contract address cannot be zero");
        authorizedContracts[contractAddress] = authorized;
        emit ContractAuthorized(contractAddress, authorized);
    }
    
    /**
     * @dev Receive funds
     * @param amount Amount
     * @param reason Reason
     */
    function receiveFunds(uint256 amount, bytes32 reason) external nonReentrant {
        require(amount > 0, "FundPool: Amount must be greater than 0");
        
        // Ensure sender has sufficient tokens
        require(travelToken.balanceOf(_msgSender()) >= amount, "FundPool: Insufficient balance of sender");
        
        // Transfer tokens to fund pool
        bool success = travelToken.transferFrom(_msgSender(), address(this), amount);
        require(success, "FundPool: Failed to receive funds");
        
        emit FundsReceived(_msgSender(), amount, reason);
    }
    
    /**
     * @dev Distribute funds (authorized contracts only)
     * @param to Recipient address
     * @param amount Amount
     * @param purpose Purpose
     */
    function distributeFunds(address to, uint256 amount, bytes32 purpose) external nonReentrant {
        require(authorizedContracts[_msgSender()], "FundPool: Caller not authorized");
        require(to != address(0), "FundPool: Recipient address cannot be zero");
        require(amount > 0, "FundPool: Amount must be greater than 0");
        
        // Ensure fund pool has sufficient tokens
        require(travelToken.balanceOf(address(this)) >= amount, "FundPool: Insufficient fund pool balance");
        
        // Transfer tokens to recipient address
        bool success = travelToken.transfer(to, amount);
        require(success, "FundPool: Failed to distribute funds");
        
        emit FundsDistributed(to, amount, purpose);
    }
    
    /**
     * @dev Emergency withdraw funds (admin only)
     * @param to Recipient address
     * @param amount Amount
     */
    function emergencyWithdraw(address to, uint256 amount) external onlyOwner nonReentrant {
        require(to != address(0), "FundPool: Recipient address cannot be zero");
        require(amount > 0, "FundPool: Amount must be greater than 0");
        
        // Ensure fund pool has sufficient tokens
        require(travelToken.balanceOf(address(this)) >= amount, "FundPool: Insufficient fund pool balance");
        
        // Transfer tokens to recipient address
        bool success = travelToken.transfer(to, amount);
        require(success, "FundPool: Failed to emergency withdraw");
    }
    
    /**
     * @dev Get fund pool balance
     * @return Token balance in fund pool
     */
    function getFundsBalance() external view returns (uint256) {
        return travelToken.balanceOf(address(this));
    }
}
