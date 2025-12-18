// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract PriceConsumer {
    AggregatorV3Interface public immutable  ETH_USD;

    mapping(address => AggregatorV3Interface) public priceFeeds;

    constructor(address ethUsdFeed,address[] memory tokens,address[] memory feeds) {

        ETH_USD = AggregatorV3Interface(ethUsdFeed);
        require(tokens.length == feeds.length, "Length mismatch");
        for (uint i = 0; i < tokens.length; i++) {
            priceFeeds[tokens[i]] = AggregatorV3Interface(feeds[i]);
        }
    }

    function getETHPrice() public view returns (int) {
        (,int price,,,) = ETH_USD.latestRoundData();
        return price;
    }

    function getPrice(address token) public view returns (int) {
        AggregatorV3Interface priceFeed = priceFeeds[token];
        require(address(priceFeed) != address(0), "No price feed for token");
        (,int price,,,) = priceFeed.latestRoundData();
        return price;
    }

}