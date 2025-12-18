const {expect} = require("chai");
const { ethers } = require("hardhat");

describe("MyNFT Contract", function () {
    let MyNFT;
    let myNFT;
    let owner;
    let addr1;
    let addr2;

    beforeEach(async function () {
       const MyNFT = await ethers.getContractFactory("MyNFT");
        [owner, addr1, addr2] = await ethers.getSigners();
        myNFT = await MyNFT.deploy();

        myNFT.initialize("MyNFT", "MNFT");
    });

    if("Should deploy and initialize correctly", async function () {
        expect(await myNFT.name()).to.equal("MyNFT");
        expect(await myNFT.symbol()).to.equal("MNFT");  
    });

    if("Should mint NFT correctly", async function () {
        const tokenUri = "https://example.com/nft/1";
        const mintTx = await myNFT.connect(addr1).mint(tokenUri);

        const receipt = await mintTx.wait();
        const tokenId = receipt.events[0].args.tokenId;
        
        expect(await myNFT.ownerOf(tokenId)).to.equal(addr1.address);
        expect(await myNFT.tokenURI(tokenId)).to.equal(tokenUri);   
    }); 

    it("Should revert if non-owner tries to mint", async function () {
    const tokenURI = "https://example.com/metadata/2";
    await expect(myNFT.connect(addr1).mintNFT(addr2.address, tokenURI)).to.be.revertedWith("Ownable: caller is not the owner");
  });
       

});