// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title IExtendedERC20
 * @dev Extended ERC20 interface with consume and reward methods
 */
interface IExtendedERC20 is IERC20 {
    /**
     * @dev Consume tokens
     * @param user User address
     * @param amount Consumption amount
     * @param reason Consumption reason
     */
    function consume(address user, uint256 amount, bytes32 reason) external;
    
    /**
     * @dev Consume tokens (with description)
     * @param user User address
     * @param amount Consumption amount
     * @param reason Consumption reason
     * @param description Consumption description
     */
    function consume(address user, uint256 amount, bytes32 reason, string calldata description) external;
    
    /**
     * @dev Reward tokens
     * @param to User address receiving reward
     * @param amount Reward amount
     */
    function reward(address to, uint256 amount) external;
    
    /**
     * @dev Reward tokens (with description)
     * @param to User address receiving reward
     * @param amount Reward amount
     * @param description Reward description
     */
    function reward(address to, uint256 amount, string calldata description) external;
    
    /**
     * @dev Get funds pool address
     * @return address Funds pool address
     */
    function fundsPool() external view returns (address);
}

/**
 * @title IFundPool
 * @dev Funds pool interface
 */
interface IFundPool {
    /**
     * @dev Distribute funds
     * @param to Recipient address
     * @param amount Amount
     */
    function distribute(address to, uint256 amount) external;
    
    /**
     * @dev Receive funds
     * @param amount Amount
     */
    function receiveFunds(uint256 amount) external;
    
    /**
     * @dev Receive funds from system
     * @param amount Amount
     */
    function receiveFromSystem(uint256 amount) external;
}

/**
 * @title IUserLevel
 * @dev User level system interface
 */
interface IUserLevel {
    /**
     * @dev Get user review reward
     * @param user User address
     * @return uint256 Review reward amount
     */
    function getUserReviewReward(address user) external view returns (uint256);
}

/**
 * @title IScenicNFT
 * @dev Scenic spot NFT interface
 */
interface IScenicNFT {
    /**
     * @dev Mint NFT
     * @param to Recipient address
     * @param tokenName NFT name
     * @return uint256 NFT ID
     */
    function mint(address to, string calldata tokenName) external returns (uint256);
}

/**
 * @title ITravelToken
 * @dev Travel token interface
 */
interface ITravelToken {
    /**
     * @dev Consume tokens
     * @param user User address
     * @param amount Consumption amount
     * @param reason Consumption reason
     * @param description Consumption description
     */
    function consume(address user, uint256 amount, bytes32 reason, string calldata description) external;
    
    /**
     * @dev Check balance
     * @param account User address
     * @return uint256 Balance
     */
    function balanceOf(address account) external view returns (uint256);
}