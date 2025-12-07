// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract MyToken is ERC20, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        // initialSupply_ 已按 ether 单位传入（含 18 0）
        _mint(msg.sender, initialSupply_);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

}