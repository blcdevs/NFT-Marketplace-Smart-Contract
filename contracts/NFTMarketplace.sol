// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//INTERNAL IMPORTS FOR NFT OPENZEPPELIN
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage{
    
        using Counters for Counters.Counter;
        Counters.Counter private _tokenIds; //Counter every unique nft by IDs
        Counters.Counter private _itemsSold; //Check how many tokens are sold


        uint256 listingPrice = 0.0023 ether;


        address payable owner;

        mapping(uint256 => MarketItem) private idMarketItem;

        struct MarketItem{
            uint256 tokenId;
            address payable seller;
            address payable owner;
            uint256 price;
            bool sold;
        }

        event idMarketItemCreated(
            uint256 indexed tokenId,
            address seller,
            address owner,
            uint256 price,
            bool sold
        );

        //MODIFIER FOR LISTING PRICE
        modifier onlyOwner() {
            require(msg.sender == owner, "Only contract owner can change the listing price");
            _;
        }


        constructor() ERC721("Mintavax", "MTV"){
            owner == payable(msg.sender);
        }

        function updateListingPrice(uint256 _listingPrice) public payable onlyOwner{
           listingPrice = _listingPrice;
        }


        function getListingPrice() public view returns(uint256){
            return listingPrice;
        }

        //CREATE NFT TOKEN FUNCTION
        function createToken(string memory tokenURI, uint256 price) public payable returns(uint256){
            _tokenIds.increment();

            uint256 newTokenId = _tokenIds.current();

            _mint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, tokenURI);

            createMarketItem(newTokenId, price);

            return newTokenId;

        }

        //create market item
        function createMarketItem(uint256 tokenId, uint256 price) private{
            require(price > 0, "Price has to be creater than 0");
                require(msg.value == listingPrice, "Price must be equal to listing price");

                idMarketItem[tokenId] = MarketItem(
                    tokenId, 
                    payable(msg.sender),
                    payable(address(this)), //This means that the NFT of money belong to the contraact itself
                    price,
                    false
                );
                    //TRANSFER THE NFT FROM THE PERSON WHO CREATED THE NFT TO CONTRACT WHO CREATED IT
                _transfer(msg.sender, address(this), tokenId);


                emit idMarketItemCreated(
                    tokenId, 
                    msg.sender, 
                    address(this), 
                    price, 
                    false
                    );
        }


        //FUNCTION TO RESELL NFT
        function reSellToken(uint256 tokenId, uint256 price) public payable{
            require(idMarketItem[tokenId].owner == msg.sender, "Only item owner can perform this transaction");

            require(msg.value == listingPrice, "Price must be equal to listing price");

            idMarketItem[tokenId].sold = false;
            idMarketItem[tokenId].price = price;
            idMarketItem[tokenId].seller = payable(msg.sender);
            idMarketItem[tokenId].owner = payable(address(this));

            _itemsSold.decrement();

            _transfer(msg.sender, address(this), tokenId);

        }


        //FUNCTION CREATE MARKET SALE
        function createMarketSale(uint256 tokenId) public payable{
            uint256 price = idMarketItem[tokenId].price;

            require(msg.value == price, "PLease, the required price in order to complete the purchase");

            idMarketItem[tokenId].owner = payable(msg.sender);
            idMarketItem[tokenId].sold = true;
            idMarketItem[tokenId].owner = payable(address(0));

             _transfer(address(this), msg.sender, tokenId);

             payable(owner).transfer(listingPrice);
             payable(idMarketItem[tokenId].seller).transfer(msg.value);
        } 



        //FETCH UNSOLD NFT DATA
        function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
            for(uint256 i = 0; i < itemCount; i++){
                if(idMarketItem[i + 1].owner == address(this)){
                    uint256 currentId = i +1;

                    MarketItem storage currentItem = idMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
            return items;
    }


    //PURCHASED ITEMS(ASSETS)

    function fetchMyNFT() public view returns(MarketItem[] memory){
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for(uint256 i = 0; i < totalCount; i++){
            if(idMarketItem[i + 1].owner == msg.sender){
                itemCount +=1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint256 i = 0; i < totalCount; i++){

            if(idMarketItem[i + 1].owner == msg.sender){
            uint256 currentId = i + 1;
            MarketItem storage currentItem = idMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex +=1;
             }
        }
        return items;
    }

        //FETCH SINGLE USER ITEM
        function fetchItemsListed() public view returns(MarketItem[] memory){
            uint256 totalCount = _tokenIds.current();
            uint256 itemCount = 0;
            uint256 currentIndex = 0;

                for(uint256 i =0; i < totalCount; i++){
                    if(idMarketItem[i + 1].seller == msg.sender){
                        itemCount += 1;
                    }
                }


        MarketItem[] memory items = new MarketItem[](itemCount);
            for(uint256 i = 0; i < totalCount; i++){
                if(idMarketItem[i + 1].seller == msg.sender){
                    uint256 currentId = i + 1;
                    MarketItem storage currentItem = idMarketItem[currentId];
                    items[currentIndex] = currentItem;
                    currentIndex +=1;
                }
            }

            return items;

        }


}
