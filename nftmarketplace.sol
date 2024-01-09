// smart contract build for the NFT marketplace

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// INTERNAL IMPORT FOR NFT OPENZIPLINE
import "openzeppelin/contracts/utils/Counters.sol";
import "openzeppelin/contracts/token/ERC721/extensions/ERD721URIStorage.sol";
import "openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract  NFTMARKETPLACE is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itmesSold;

    uint256 listingPrice = 0.0025 ether;
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;              // idMarketItem; changed to idToMarketItem

    struct MarketItem{
        uint256 _tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold,
    );


// not seeing modifier 
// this modifier function is used in onlyOwner function updating listing price 
// alothought they are not useful 

    /*
    modifier onlyOwner {
        require(
            msg.sender== owner,
            "only owner of the marketplace can change the listing price"
        )
        _; 
    }
    */

    constructor() ERC721("Metavarse Tokens", "METT"){
        owner == payable(msg.sender);

    }


    // updating the listing price of the contract
    // change this function from video to code 

    // this function can not use modifier    
    function updateListingPrice(uint256 _listingPrice) public payable{
       require(
        owner == msg.sender,
        "Only marketplace owner can update listing price"
       );
       listingPrice= _listingPrice;
    }
    
    // this function use modifier 
    /*
    function updateListingPrice(uint256 _listingPrice) public payable onlyOwner{
        listingPrice = _listingPrice;
    }
    */


    // return the listing price of the contract

    function getListingPrice() public view returns(uint256){
        return listingPrice;
    }


    // let create NFT token functions
    // mints a token and kists it in the marketplace

    function createToken(string memory tokenURI , uint256 price) public payable return(uint256){
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(mag.sender,newTokenId);
        _setTokenURI(newTokenId,tokenURI);
        createMarketItem(newTokenId,price);
        return newTokenId;
    }


    // creating market items

    function createMarketItem(uint256 tokenId,uint256 price) private{
        require(price > 0, "Price must be at least 1");
        require(
            msg.value == listingPrice,
            "Price must must be equal to listing price"
        );

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender,address(this),tokenId);
        emit MarketItemCreated(
            tokenId, 
            msg.sender, 
            address(this), 
            price, 
            false
        );
    }

    // allow someone who resell a token they have purchased
    // function for resell token

    function resellToken(uint256 tokenId,uint price) public payable{
        require(
            idToMarketItem[tokenId].owner== msg.sender, 
            "only item owner can perform this operation"
        );

        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itmesSold.decrement();

        _transfer(msg.sender,address(this),tokenId);
    }

    // function create market sale
    // create the sale of a marketplace item

    function createMarketSale(uint256 tokenId) public payable{
        uint256 price = idToMarketItem[tokenId].price;

        require(
            msg.value == price,
            "Please submit the asking price in order the complete the purchase"
        );

        idToMarketItem[tokenId].owner == payable(msg.sender);
        idToMarketItem[tokenId].sold == true;
        idToMarketItem[tokenId].seller == payable(address(0));
        _itmesSold.increment();
        _transfer(address(this),msg.sender,tokenId);

        payable(owner).transfer(listingPrice);
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
    }

    // getting unsold NFT data
    // return all the unsold market items

    function fetchMarketItems() public view returns(MarketItem[] memory){
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemsCount = _tokenIds.current() - _itmesSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemsCount);

        for(uint256 i=0;i<itemCount;i++){
            if(idToMarketItem[i+1].owner == address(this)){
                uint256 currentId = i+1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex+=1;
            }
        }
        return items;
    }

    // purchase items
    // return only the item that a user has purchases 

    function fetchMyNFTs() public view returns(MarketItem[] memory){
        uint256 totalItemCount= _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i=0;i<totalItemCount;i++){
            if(idToMarketItem[i+1].owner == msg.sender){
                itemCount+=1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i=0;i<totalItemCount;i++){
            if(idToMarketItem[i+1].owner== msg.sender){
                uint256 currentId=i+1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex+=1;
            }
        }
        return items;
    }


    // single user item
    //return only items a user has listed

    function fetchItemsListed() public view returns(MarketItem[] memory){
        uint256 totalItemCount=_tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex =0;

        for(uint256 i=0;i<totalItemCount;i++){
            if(MarketItem[i+1].seller == msg.sender){
                itemCount +=1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i=0;i<totalItemCount;i++){
            if(idToMarketItem[i+1].seller == msg.sender){
                uint256 currentId =i+1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex+=1;
            }
        }
        return items;

    }
}


//  debugging is completed some changes are having in updatelistingprice function 
// i think modiifier is not important so i commented out that function modifier

// both functions are same but in onlyOwner modifier we initilised in globally 
// both work as it is 