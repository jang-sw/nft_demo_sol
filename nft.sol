// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MinNftToken is ERC721Enumerable {
    
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    string _name = "iki";
    string _symbol = "jquery_symbol";
    
    constructor() ERC721("iki", "jquery_symbol"){}
    
    function changeSetting(string memory new_name, string memory new_symbol) public {
        _name = new_name;
        _symbol = new_symbol;
    }

    mapping(uint => string ) public tokenURIs; 

    function tokenURI(uint _tokenId) override public view returns (string memory) {
        return tokenURIs[_tokenId];
    }

    function mintNFT( string memory _tokenURI ) public returns (uint256) {
        _tokenIds.increment();

        uint256 tokenId = _tokenIds.current();
        tokenURIs[tokenId] = _tokenURI;
        _mint(msg.sender, tokenId);

        return tokenId;
    }

    struct NftTokenData {
        uint256 nftTokenId;
        string nftTokenURI;
        uint price;
    }

    function getNftTokens(address _nftTokenOwner) public view returns (NftTokenData[] memory){
        uint256 balanceLength = balanceOf(_nftTokenOwner);
        require(balanceLength != 0, "Owner did not have token.");
        NftTokenData[] memory nftTokenData = new NftTokenData[](balanceLength);

        for( uint256 i = 0; i < balanceLength; i++ ){
            uint256 nftTokenId = tokenOfOwnerByIndex(_nftTokenOwner, i);
            string memory nftTokenURI = tokenURI(nftTokenId);
            uint tokenPrice = getNftTokenPrice(nftTokenId);            
            nftTokenData[i] = NftTokenData(nftTokenId, nftTokenURI, tokenPrice);
        }
        return nftTokenData;
    }
    //sales regist
    mapping(uint256 => uint256) public nftTokenPrices;   
    uint256[] public onSaleNftTokenArray;
    function setSaleNftToken(uint256 _tokenId, uint _price) public {
        address nftTokenOwner = ownerOf(_tokenId);
        require(nftTokenOwner == msg.sender, "Caller is not nft token owner.");
        require(_price > 0, "Price is zero or lower.");
        require(nftTokenPrices[_tokenId] == 0 , "This nft token is already on sale.");
        require(isApprovedForAll(nftTokenOwner, address(this)), "nft token owner did not approve token.");    

        nftTokenPrices[_tokenId] = _price;
        onSaleNftTokenArray.push(_tokenId);
    }
    //get sales list
    function getSaleNftTokens() public view returns (NftTokenData[] memory){
        uint[] memory onSaleNftToken = getSaleNftToken();
        NftTokenData[] memory onSaleNftTokens = new NftTokenData[](onSaleNftToken.length);

        for(uint i = 0; i  < onSaleNftToken.length; i++){
            uint tokenId = onSaleNftToken[i];
            uint tokenPrice = getNftTokenPrice(tokenId);
            onSaleNftTokens[i] = NftTokenData(tokenId, tokenURI(tokenId), tokenPrice);
        }
        return onSaleNftTokens;
    }

    function getSaleNftToken() public view returns (uint[] memory){
        return onSaleNftTokenArray;
    }

    function getNftTokenPrice(uint256 _tokenId) public view returns(uint256){
        return nftTokenPrices[_tokenId];
    }
    //buy nft token
    function buyNftToken(uint256 _tokenId) public payable{
        uint256 price = nftTokenPrices[_tokenId];
        address nftTokenOwner = ownerOf(_tokenId);

        require(price > 0, "nft token not sale.");
        require(price <= msg.value, "caller sent lower than price.");
        require(nftTokenOwner != msg.sender, "caller is nft token owner.");
        require(isApprovedForAll(nftTokenOwner, address(this)), "nft token owner did not approve token.");
        payable(nftTokenOwner).transfer(msg.value);

        //transfer owner
        IERC721(address(this)).safeTransferFrom(nftTokenOwner, msg.sender, _tokenId);

        removeToken(_tokenId);

    }

    function burn(uint256 _tokenId) public{
        address addr_owner = ownerOf(_tokenId);
        require(addr_owner == msg.sender, "sender is not owner of the token");
        _burn(_tokenId);
        removeToken(_tokenId);
    }
    //remove from sales list
    function removeToken(uint256 _tokenId) private {
        nftTokenPrices[_tokenId] = 0;
        for(uint256 i = 0; i < onSaleNftTokenArray.length; i++){
            if(nftTokenPrices[onSaleNftTokenArray[i]] == 0){
                onSaleNftTokenArray[i] = onSaleNftTokenArray[onSaleNftTokenArray.length - 1];
                onSaleNftTokenArray.pop();
            }
        }
    }


}