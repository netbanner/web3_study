// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
contract MetaNode is ERC20, Ownable {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
        Ownable(msg.sender)          // 初始化 Ownable
    {
        // 直接调 _mint，绕过 onlyOwner 检查
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }


    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
