// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../oracle/PriceConsumer.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract NFTAuctionV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    PriceConsumer public priceConsumer;

    struct Auction {
        address seller;
        address nftAddress;
        uint256 tokenId;
        address bidToken; // ERC20 token used for bidding
        uint256 startPrice;  // Minimum bid amount in bidToken
        uint256 startTime;
        uint256 highestBid; // Highest bid amount in bidToken
        address highestBidder;
        uint256 endTime;
        bool ended;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCount;
    mapping(address => mapping(uint256 => uint256)) public userBids; // nftAddress -> auctionId -> bidAmount
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, uint256 tokenId, uint256 startPrice, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 usdValue);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 amount);
   

      
    function initialize(address _priceConsumer) public initializer { // Correct use of the initializer modifier
        __Ownable_init();  // Initialize Ownable
        __UUPSUpgradeable_init();  // Initialize UUPSUpgradeable
        priceConsumer = PriceConsumer(_priceConsumer);
    }


    function createAuction(
        address nftAddress,
        uint256 tokenId,
        address bidToken,
        uint256 startPrice,
        uint256 duration
    ) external {
        require(nftAddress != address(0), "NFT address cannot be zero address");

        IERC721(nftAddress).transferFrom(msg.sender, address(this), tokenId);
        auctionCount += 1;
        auctions[auctionCount] = Auction({
            seller: msg.sender,
            nftAddress: nftAddress, 
            tokenId: tokenId,
            bidToken: bidToken,
            startPrice: startPrice,
            startTime: block.timestamp,
            highestBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + duration,
            ended: false
        });

        emit AuctionCreated(auctionCount, msg.sender, tokenId, startPrice, block.timestamp + duration);              
    }


    function bid(uint256 auctionId, uint256 bidAmount) external payable {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp < auction.endTime, "Auction ended");
        uint256 value = auction.bidToken == address(0) ? msg.value : bidAmount;

        require(value >= auction.startPrice, "Bid too low");
        require(value > auction.highestBid, "There already is a higher bid");
        if(auction.bidToken != address(0)){
            IERC20(auction.bidToken).transferFrom(msg.sender, address(this), bidAmount);
        }   

        // Refund the previous highest bidder
        if (auction.highestBidder != address(0)) {
            if(auction.bidToken == address(0)){
                payable(auction.highestBidder).transfer(auction.highestBid);
            } else {
                IERC20(auction.bidToken).transfer(auction.highestBidder, auction.highestBid);
            }

        }
        auction.highestBid = value;
        auction.highestBidder = msg.sender;
        userBids[auction.nftAddress][auctionId] = bidAmount;
        uint256  usdValue = estimateUsdValue(auction.bidToken, value);

        emit BidPlaced(auctionId, msg.sender, value, usdValue);
    }

    function endAuction(uint256 auctionId) external {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endTime, "Auction not yet ended");
        require(!auction.ended, "Auction already ended");

        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            // Transfer NFT to highest bidder
            IERC721(auction.nftAddress).transferFrom(address(this), auction.highestBidder, auction.tokenId);
            // Transfer funds to seller
            if(auction.bidToken == address(0)){
                payable(auction.seller).transfer(auction.highestBid);
            } else {
                IERC20(auction.bidToken).transfer(auction.seller, auction.highestBid);
            }
        } else {
            // No bids were placed, return NFT to seller
            IERC721(auction.nftAddress).transferFrom(address(this), auction.seller, auction.tokenId);
        }
        emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
    }

    function estimateUsdValue(address token, uint256 amount) public view returns (uint256) {
        int price;
        if (token == address(0)) {
            // ETH case
            price = priceConsumer.getETHPrice();
            amount = amount*1e8/1e18; // convert wei to ETH with 8 decimals
        } else {
            price = priceConsumer.getPrice(token);
            require(price > 0, "Invalid price");
            uint8 decimals = IERC20Metadata(token).decimals();
            amount = amount*1e8/(10**decimals); // convert token amount to 8 decimals   
        }
        // Assuming price has 8 decimals
        return (amount * uint256(price)) / 1e8;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
