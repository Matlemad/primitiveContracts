// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/**
 * the Storage.sol evergreen where only certain NFT holders (or NFTiD holder) 
 * can store value in the variable 
 * public retrieve the number
 */
contract Storage is Ownable {

    uint256 number;
    ERC721 nftAddress;
    uint256 NFTId;

// use this modifier if you want to allow all holders of a given NFT collection

    modifier hasNFTCollection {
        require(nftAddress.balanceOf(msg.sender) >= 1);
        _;
    }

// use this modifier if you want to allow only the holder of a specific NFTid

    modifier hasNFTId {
        require(nftAddress.ownerOf(NFTId) == msg.sender);
        _;
    }

// only the owner can set the NFT collection address

    function setNFTCollection(ERC721 _nft) public onlyOwner {
        nftAddress = _nft;
    }

// only the owner can set the NFT Id

    function setNFTId(uint256 _tokenId) public onlyOwner {
        NFTId = _tokenId;
    }


    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public hasNFTCollection {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}