const { expect } = require("chai");
const { ethers } = require("hardhat");

const ONE_DAY = 24 * 3600;
const ETH_USD_PRICE = 2000_00000000; // 8 dec

describe("NFTAuctionV1 (JS)", function () {
  let nft;
  let auction;
  let priceConsumer;
  let ethUsdFeed;

  let owner, seller, bidder1, bidder2;

  beforeEach(async () => {
    [owner, seller, bidder1, bidder2] = await ethers.getSigners();

    // 1. Deploy MockV3Aggregator
    const MockFeedFactory = await ethers.getContractFactory("MockV3Aggregator");
    ethUsdFeed = await MockFeedFactory.deploy(8, ETH_USD_PRICE);

    // 2. Deploy PriceConsumer
    const PriceConsumerFactory = await ethers.getContractFactory("PriceConsumer");
    priceConsumer = await PriceConsumerFactory.deploy(
      ethUsdFeed.address,
      [],
      []
    );

    // 3. Deploy NFT (普通部署)
    const NFTFactory = await ethers.getContractFactory("MyNFT");
    nft = await NFTFactory.deploy();
    await nft.initialize("MyNFT", "MNFT");

    // 4. Deploy Auction (普通部署)
    const AuctionFactory = await ethers.getContractFactory("NFTAuctionV1");
    auction = await AuctionFactory.deploy();
    await auction.initialize(priceConsumer.address);
  });

  it("should create auction", async () => {
    const txMint = await nft.connect(owner).mint(seller.address, "ipfs://abc");
    const receipt = await txMint.wait();
    const tokenId = receipt.events.find(e => e.event === "Transfer").args.tokenId;

    await nft.connect(seller).approve(auction.address, tokenId);

    await expect(
      auction.connect(seller).createAuction(
        nft.address,
        tokenId,
        ethers.constants.AddressZero, // ETH
        ethers.utils.parseEther("1"),
        ONE_DAY
      )
    )
      .to.emit(auction, "AuctionCreated")
      .withArgs(
        1,
        seller.address,
        tokenId,
        ethers.utils.parseEther("1"),
        (await ethers.provider.getBlock("latest")).timestamp + ONE_DAY
      );

    const a = await auction.auctions(1);
    expect(a.seller).to.eq(seller.address);
    expect(a.highestBid).to.eq(0);
  });

  it("should place bid and refund previous", async () => {
    const txMint = await nft.connect(owner).mint(seller.address, "ipfs://abc");
    const receipt = await txMint.wait();
    const tokenId = receipt.events.find(e => e.event === "Transfer").args.tokenId;

    await nft.connect(seller).approve(auction.address, tokenId);
    await auction.connect(seller).createAuction(
      nft.address,
      tokenId,
      ethers.constants.AddressZero,
      ethers.utils.parseEther("1"),
      ONE_DAY
    );

    // bid1 1 ETH
    await auction.connect(bidder1).bid(1, ethers.utils.parseEther("1"), { value: ethers.utils.parseEther("1") });
    expect(await ethers.provider.getBalance(auction.address)).to.eq(
      ethers.utils.parseEther("1")
    );

    // bid2 2 ETH
    await auction.connect(bidder2).bid(1, ethers.utils.parseEther("2"), { value: ethers.utils.parseEther("2") });
    expect(await ethers.provider.getBalance(auction.address)).to.eq(
      ethers.utils.parseEther("2")
    );

    const a = await auction.auctions(1);
    expect(a.highestBidder).to.eq(bidder2.address);
    expect(a.highestBid).to.eq(ethers.utils.parseEther("2"));
  });

  it("should end auction and transfer NFT", async () => {
    const txMint = await nft.connect(owner).mint(seller.address, "ipfs://abc");
    const receipt = await txMint.wait();
    const tokenId = receipt.events.find(e => e.event === "Transfer").args.tokenId;

    await nft.connect(seller).approve(auction.address, tokenId);
    await auction.connect(seller).createAuction(
      nft.address,
      tokenId,
      ethers.constants.AddressZero,
      ethers.utils.parseEther("1"),
      ONE_DAY
    );

    await auction.connect(bidder1).bid(1, ethers.utils.parseEther("1.5"), { value: ethers.utils.parseEther("1.5") });

    // increase time
    await ethers.provider.send("evm_increaseTime", [ONE_DAY + 1]);
    await ethers.provider.send("evm_mine");

    await expect(auction.connect(owner).endAuction(1))
      .to.emit(auction, "AuctionEnded")
      .withArgs(1, bidder1.address, ethers.utils.parseEther("1.5"));

    expect(await nft.ownerOf(tokenId)).to.eq(bidder1.address);
  });

  it("should estimate USD value correctly", async () => {
    const usd = await auction.estimateUsdValue(
      ethers.constants.AddressZero,
      ethers.utils.parseEther("2")
    );
    expect(usd).to.eq(4000_00000000); // 4000 USD, 8 dec
  });
});