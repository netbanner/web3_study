require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200 // 优化器运行次数，值越低合约越小，值越高执行效率越高
      }
    }
  },
};