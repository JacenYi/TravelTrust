// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {ERC721Enumerable} from '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract ScenicNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    
    // Token counter
    uint256 private _tokenIdCounter;
    
    // NFT metadata mapping (tokenId => name)
    mapping(uint256 => string) private _tokenNames;
    
    // Constructor
    constructor() ERC721("ScenicNFT", "SNFT") Ownable(msg.sender) {
        _tokenIdCounter = 1;
    }
    
    /**
     * @dev Mint NFT
     * @param to Recipient address
     * @param tokenName NFT name
     * @return Minted tokenId
     */
    function mint(address to, string calldata tokenName) external returns (uint256) {
        require(to != address(0), "ScenicNFT: Recipient address cannot be zero");
        
        uint256 tokenId = _tokenIdCounter;
        _safeMint(to, tokenId);
        _tokenNames[tokenId] = tokenName;
        _tokenIdCounter++;
        
        return tokenId;
    }
    
    /**
     * @dev Return NFT metadata URI
     * @param tokenId NFT's tokenId
     * @return Metadata URI
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "ERC721Metadata: URI query for nonexistent token");
        
        string memory name = _tokenNames[tokenId];
        string memory baseURI = "https://ipfs.io/ipfs/QmXYZ123/";
        string memory imageURI = string(abi.encodePacked(baseURI, tokenId.toString(), ".png"));
        
       bytes memory json = abi.encodePacked(
            '{"name":"', name, '",',
            '"description":"Scenic Spot NFT",',
            '"image":"', imageURI, '"}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(json)
            )
        );
    }
    
    // Override functions to support ERC721Enumerable
    function _update(address to, uint256 tokenId, address auth) internal override(ERC721, ERC721Enumerable) returns (address) {
        return super._update(to, tokenId, auth);
    }
    
    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}