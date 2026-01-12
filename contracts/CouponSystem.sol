// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

// Import shared interface file
import './interfaces/ITravelDApp.sol';

contract CouponSystem is AccessControl, ReentrancyGuard {
    // Define verifier role
bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    
    // Coupon status enum
enum CouponStatus {
    Active,    // Usable
    Used,      // Used
    Expired    // Expired
}

    // Coupon definition structure
struct CouponDefinition {
    uint256 couponId;      // Coupon ID
    string name;           // Coupon name
    string description;    // Coupon description
    string tag;            // Coupon tag (e.g., hotel, ticket, transportation, etc.)
    uint256 price;         // Purchase price (TRT)
    uint256 maxSupply;     // Maximum supply
    uint256 validityDays;  // Validity period (days)
    uint256 soldCount;     // Sold quantity
    bool active;           // Whether active
    string nftName;        // NFT name issued after verification
}

    // User coupon structure
struct UserCoupon {
    uint256 couponId;      // Coupon definition ID
    string couponCode;     // Unique coupon code
    uint256 purchaseDate;  // Purchase date
    uint256 expiryDate;    // Expiry date
    CouponStatus status;   // Status
}
    
    // Full coupon information structure (for query results)
struct FullCouponInfo {
    uint256 couponId;          // Coupon definition ID
    string couponCode;         // Unique coupon code
    string name;               // Coupon name
    string description;        // Coupon description
    string tag;                // Coupon tag
    uint256 price;             // Purchase price (TRT)
    uint256 validityDays;      // Validity period (days)
    string nftName;            // NFT name issued after verification
    uint256 purchaseDate;      // Purchase date
    uint256 expiryDate;        // Expiry date
    CouponStatus status;       // User coupon status
}

    // Event definitions
    event CouponDefined(uint256 indexed couponId, string name, uint256 price);
    event CouponPurchased(uint256 indexed couponId, string indexed couponCode, address indexed user, uint256 purchaseDate, uint256 expiryDate);
    event CouponUsed(string indexed couponCode, address indexed user, uint256 timestamp);
    event CouponStatusUpdated(string indexed couponCode, CouponStatus status);

    // Coupon definition mapping (ID => Coupon definition)
mapping(uint256 => CouponDefinition) public couponDefinitions;

    // Coupon position information structure
struct CouponPosition {
    address user;          // User address
    uint256 couponId;      // Coupon definition ID
    uint256 index;         // User coupon array index
}

    // User coupon mapping (user address => (coupon ID => user coupons))
mapping(address => mapping(uint256 => UserCoupon[])) public userCoupons;

    // User coupon count mapping (user address => coupon definition ID => count)
mapping(address => mapping(uint256 => uint256)) public userCouponCount;

    // Coupon code to position mapping (unique code => coupon position)
mapping(string => CouponPosition) public couponCodeToPosition;

    // Coupon code existence mapping
mapping(string => bool) public couponCodeExists;

    // Token contract address
    ITravelToken public travelToken;

    // Oracle address
    address public oracleAddress;

    // Fund pool contract address
    IFundPool public fundPool;
    
    // ScenicNFT contract address
    IScenicNFT public scenicNFT;

    // Next coupon definition ID
uint256 public nextCouponId;
    
    // Coupon ID list, used for querying all coupons
uint256[] public couponIds;

    // Helper function: Convert bytes to hex string
    function bytesToHex(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";        
        bytes memory str = new bytes(data.length * 2);        
        for (uint i = 0; i < data.length; i++) {
            uint8 b = uint8(data[i]);
            str[i*2] = alphabet[b >> 4];
            str[i*2+1] = alphabet[b & 0x0f];
        }
        return string(str);
    }

    // Generate random 32-bit string coupon code
    function generateRandomCouponCode() internal returns (string memory) {
        uint256 nonce = block.timestamp;
        string memory couponCode;
        bool foundUnique = false;
        
        // Try up to 10 times to generate a unique coupon code
        for (uint256 i = 0; i < 10; i++) {
            // Generate random number using block.prevrandao, block.timestamp, msg.sender, and nonce
            bytes32 randomHash = keccak256(
                abi.encodePacked(
                    block.prevrandao, // Random source introduced by EIP-4399
                    block.timestamp,  
                    msg.sender,       
                    nonce,           
                    i                // Number of attempts
                )
            );
            
            // Take the first 16 bytes (32-bit hexadecimal string)
            bytes memory randomBytes = abi.encodePacked(randomHash);
            bytes memory truncatedBytes = new bytes(16);
            for (uint256 j = 0; j < 16; j++) {
                truncatedBytes[j] = randomBytes[j];
            }
            
            // Convert to 32-bit hexadecimal string
            couponCode = bytesToHex(truncatedBytes);
            
            // Check if it already exists
            if (!couponCodeExists[couponCode]) {
                foundUnique = true;
                break;
            }
            
            nonce++;
        }
        
        // If no unique code is found after 10 attempts, use blockhash as backup
        if (!foundUnique) {
            bytes32 blockHash = blockhash(block.number - 1);
            bytes memory hashBytes = abi.encodePacked(blockHash);
            bytes memory truncatedBytes = new bytes(16);
            for (uint256 j = 0; j < 16; j++) {
                truncatedBytes[j] = hashBytes[j];
            }
            couponCode = bytesToHex(truncatedBytes);
        }
        
        return couponCode;
    }

    /**
     * @dev Constructor
     * @param tokenAddress TravelToken contract address
     * @param fundPoolAddress FundPool contract address
     * @param scenicNFTAddress ScenicNFT contract address
     */
    constructor(address tokenAddress, address fundPoolAddress, address scenicNFTAddress) {
        require(tokenAddress != address(0), "CouponSystem: Token address cannot be zero");
        require(fundPoolAddress != address(0), "CouponSystem: Fund pool address cannot be zero");
        require(scenicNFTAddress != address(0), "CouponSystem: NFT contract address cannot be zero");
        
        // Set default admin role (OpenZeppelin v5 API)
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        
        travelToken = ITravelToken(tokenAddress);
        fundPool = IFundPool(fundPoolAddress);
        scenicNFT = IScenicNFT(scenicNFTAddress);
        nextCouponId = 1;
    }

    /**
     * @dev Define new coupon (admin only)
     * @param name Coupon name
     * @param description Coupon description
     * @param tag Coupon tag (e.g., hotel, ticket, transportation, etc.)
     * @param price Purchase price (TRT)
     * @param maxSupply Maximum supply
     * @param validityDays Validity period (days)
     * @param nftName NFT name issued after verification
     */
    function defineCoupon(
        string calldata name,
        string calldata description,
        string calldata tag,
        uint256 price,
        uint256 maxSupply,
        uint256 validityDays,
        string calldata nftName
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(maxSupply > 0, "CouponSystem: Maximum supply must be greater than 0");
        require(validityDays > 0, "CouponSystem: Validity period must be greater than 0");
        
        uint256 couponId = nextCouponId;
        
        couponDefinitions[couponId] = CouponDefinition({
            couponId: couponId,
            name: name,
            description: description,
            tag: tag,
            price: price,
            maxSupply: maxSupply,
            validityDays: validityDays,
            soldCount: 0,
            active: true,
            nftName: nftName
        });
        
        // Add new coupon ID to list
        couponIds.push(couponId);
        
        nextCouponId++;
        emit CouponDefined(couponId, name, price);
    }
    
    /**
     * @dev User purchases coupon
     * @param couponId Coupon definition ID
     */
    function purchaseCoupon(uint256 couponId) external nonReentrant {
        CouponDefinition storage couponDef = couponDefinitions[couponId];
        require(couponDef.active, "CouponSystem: Coupon is not purchasable");
        
        // Atomic check and update of sold quantity (prevent race conditions under high concurrency)
        // First check if quantity is sufficient, then increment immediately to ensure atomicity
        require(couponDef.soldCount < couponDef.maxSupply, "CouponSystem: Exceeds maximum supply");
        
        // Verify user balance
        require(travelToken.balanceOf(_msgSender()) >= couponDef.price, "CouponSystem: Insufficient token balance");
        
        // 1. First update state (Checks-Effects-Interactions pattern)
        // Use unchecked for safe atomic increment operation
        unchecked {
            couponDef.soldCount++;
        }
        
        // 2. Then make external calls
        // Consume tokens, consumed tokens return to fund pool
        travelToken.consume(
            _msgSender(),
            couponDef.price,
            keccak256(abi.encodePacked("CouponPurchase", couponId)),
            string(abi.encodePacked("Exchange ", couponDef.name))
        );
        
        // Generate user coupon
        uint256 currentDate = block.timestamp;
        string memory couponCode = generateRandomCouponCode();
        
        UserCoupon memory userCoupon = UserCoupon({
            couponId: couponId,
            couponCode: couponCode,
            purchaseDate: currentDate,
            expiryDate: currentDate + (couponDef.validityDays * 1 days),
            status: CouponStatus.Active
        });
        
        // Add to user coupon list
        uint256 index = userCoupons[_msgSender()][couponId].length;
        userCoupons[_msgSender()][couponId].push(userCoupon);
        userCouponCount[_msgSender()][couponId]++;
        
        // Update coupon code to position mapping
        couponCodeToPosition[couponCode] = CouponPosition({
            user: _msgSender(),
            couponId: couponId,
            index: index
        });
        
        // Mark coupon code as existing
        couponCodeExists[couponCode] = true;
        
        emit CouponPurchased(couponId, couponCode, _msgSender(), currentDate, userCoupon.expiryDate);
    }
    
    /**
     * @dev Authorized personnel directly verify coupon
     * @param couponCode Unique coupon code
     */
    function verifyCoupon(
        string calldata couponCode
    ) external nonReentrant {
        // Check if caller has verifier role
        require(hasRole(VERIFIER_ROLE, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CouponSystem: No permission to verify coupon");
        
        // Verify if coupon code exists
        require(couponCodeExists[couponCode], "CouponSystem: Coupon does not exist");
        
        // Get coupon position information
        CouponPosition memory position = couponCodeToPosition[couponCode];
        
        // Get user coupon
        UserCoupon storage userCoupon = userCoupons[position.user][position.couponId][position.index];
        require(keccak256(abi.encodePacked(userCoupon.couponCode)) == keccak256(abi.encodePacked(couponCode)), "CouponSystem: Coupon information does not match");
        
        // Verify coupon is active and not expired
        require(userCoupon.status == CouponStatus.Active, "CouponSystem: Coupon is not available");
        require(userCoupon.expiryDate > block.timestamp, "CouponSystem: Coupon has expired");
        
        // Update status to used
        userCoupon.status = CouponStatus.Used;
        
        // Emit used event
        emit CouponUsed(couponCode, position.user, block.timestamp);
        emit CouponStatusUpdated(couponCode, CouponStatus.Used);
        
        // Issue NFT
        CouponDefinition storage couponDef = couponDefinitions[position.couponId];
        scenicNFT.mint(position.user, couponDef.nftName);
    }
    
    /**
     * @dev Set Oracle address (admin only)
     * @param newOracleAddress New Oracle address
     */
    function setOracleAddress(address newOracleAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newOracleAddress != address(0), "CouponSystem: Oracle address cannot be zero");
        oracleAddress = newOracleAddress;
    }
    
    /**
     * @dev Assign verifier role (admin only)
     * @param account Address to assign role
     */
    function grantVerifierRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(account != address(0), "CouponSystem: Address cannot be zero");
        grantRole(VERIFIER_ROLE, account);
    }
    
    /**
     * @dev Revoke verifier role (admin only)
     * @param account Address to revoke role
     */
    function revokeVerifierRole(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(VERIFIER_ROLE, account);
    }
    
    /**
     * @dev Set coupon status (admin only)
     * @param couponId Coupon definition ID
     * @param active Whether to activate
     */
    function setCouponActive(uint256 couponId, bool active) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(couponDefinitions[couponId].maxSupply > 0, "CouponSystem: Coupon does not exist");
        couponDefinitions[couponId].active = active;
    }

    /**
     * @dev Get details of user's specific coupon
     * @param user User address
     * @param couponId Coupon definition ID
     * @param index Coupon index
     * @return User coupon details
     */
    function getUserCoupon(address user, uint256 couponId, uint256 index) external view returns (UserCoupon memory) {
        require(userCoupons[user][couponId].length > index, "CouponSystem: Coupon does not exist");
        return userCoupons[user][couponId][index];
    }
    
    /**
     * @dev Get coupon definition details
     * @param couponId Coupon definition ID
     * @return Coupon definition details
     */
    function getCouponDefinition(uint256 couponId) external view returns (CouponDefinition memory) {
        return couponDefinitions[couponId];
    }
    
    /**
     * @dev Get list of all coupon IDs
     * @return Array of all coupon IDs
     */
    function getAllCouponIds() external view returns (uint256[] memory) {
        return couponIds;
    }
    
    /**
     * @dev Get count of all coupons
     * @return Total number of coupons
     */
    function getCouponCount() external view returns (uint256) {
        return couponIds.length;
    }
    
    /**
     * @dev Get complete details of all active coupons (one-step query)
     * @return Array containing all active coupon IDs and details
     */
    function getAllCoupons() external view returns (CouponDefinition[] memory) {
        // First calculate the number of active coupons
        uint256 activeCount = 0;
        for (uint256 i = 0; i < couponIds.length; i++) {
            uint256 couponId = couponIds[i];
            if (couponDefinitions[couponId].active) {
                activeCount++;
            }
        }
        
        // Create result array
        CouponDefinition[] memory result = new CouponDefinition[](activeCount);
        uint256 resultIndex = 0;
        
        // Iterate through all coupon IDs, only add active coupons to result array
        for (uint256 i = 0; i < couponIds.length; i++) {
            uint256 couponId = couponIds[i];
            CouponDefinition storage couponDef = couponDefinitions[couponId];
            if (couponDef.active) {
                result[resultIndex] = couponDef;
                resultIndex++;
            }
        }
        
        return result;
    }
    
    /**
     * @dev Get detailed list of user's purchased, unused, and unexpired coupons
     * @param user User address to query
     * @return Array of detailed information for coupons that meet the conditions
     */
    function getUserActiveCoupons(address user) external view returns (FullCouponInfo[] memory) {
        // First calculate the number of eligible coupons
        uint256 totalCount = 0;
        uint256 currentTimestamp = block.timestamp;
        
        // Iterate through all coupon types
        for (uint256 i = 0; i < couponIds.length; i++) {
            uint256 couponId = couponIds[i];
            
            // Get number of user coupons of this type
            UserCoupon[] storage userCouponList = userCoupons[user][couponId];
            uint256 count = userCouponList.length;
            
            // Iterate through all user coupons of this type
            for (uint256 j = 0; j < count; j++) {
                UserCoupon storage userCoupon = userCouponList[j];
                
                // Check if coupon is unused and not expired
                if (userCoupon.status == CouponStatus.Active && userCoupon.expiryDate > currentTimestamp) {
                    totalCount++;
                }
            }
        }
        
        // Create result array
        FullCouponInfo[] memory result = new FullCouponInfo[](totalCount);
        uint256 resultIndex = 0;
        
        // Iterate through all coupon types again to populate result array
        for (uint256 i = 0; i < couponIds.length; i++) {
            uint256 couponId = couponIds[i];
            CouponDefinition storage couponDef = couponDefinitions[couponId];
            
            // Get number of user coupons of this type
            UserCoupon[] storage userCouponList = userCoupons[user][couponId];
            uint256 count = userCouponList.length;
            
            // Iterate through all user coupons of this type
            for (uint256 j = 0; j < count; j++) {
                UserCoupon storage userCoupon = userCouponList[j];
                
                // Check if coupon is unused and not expired
                if (userCoupon.status == CouponStatus.Active && userCoupon.expiryDate > currentTimestamp) {
                    // Populate complete coupon information
                    result[resultIndex] = FullCouponInfo({
                        couponId: couponDef.couponId,
                        couponCode: userCoupon.couponCode,
                        name: couponDef.name,
                        description: couponDef.description,
                        tag: couponDef.tag,
                        price: couponDef.price,
                        validityDays: couponDef.validityDays,
                        nftName: couponDef.nftName,
                        purchaseDate: userCoupon.purchaseDate,
                        expiryDate: userCoupon.expiryDate,
                        status: userCoupon.status
                    });
                    resultIndex++;
                }
            }
        }
        
        return result;
    }
}
