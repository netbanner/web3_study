// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.28;

import "../MemeTokenBase.sol";

contract TestableMemeTokenBase is MemeTokenBase {
    // Constructor for testing purposes
    constructor() {
        // This is just a placeholder, actual initialization happens in initialize()
    }

    // Initialize function for testing
    function initialize(
        address _routerAddress,
        address marketingWalletAddress,
        address developmentWalletAddress
    ) public initializer {
        __MemeTokenBase_init(_routerAddress, marketingWalletAddress, developmentWalletAddress);
    }

    // Override _authorizeUpgrade for UUPS compatibility
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // Expose internal functions for testing
    function testSetExcludedFromFees(address _a, bool _b) external {
        _setExcludedFromFees(_a, _b);
    }

    function testSetExcludedFromMaxTx(address _a, bool _b) external {
        _setExcludedFromMaxTx(_a, _b);
    }

    function testSetExcludedFromMaxWallet(address _a, bool _b) external {
        _setExcludedFromMaxWallet(_a, _b);
    }

    // Getter functions for internal mappings
    function isExcludedFromFees(address _a) external view returns (bool) {
        return _isExcludedFromFees[_a];
    }

    function isExcludedFromMaxTransaction(address _a) external view returns (bool) {
        return _isExcludedFromMaxTransaction[_a];
    }

    function isExcludedFromMaxWallet(address _a) external view returns (bool) {
        return _isExcludedFromMaxWallet[_a];
    }
}