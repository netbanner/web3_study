const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

const INITIAL_SUPPLY = 1_000_000n * 10n ** 18n;; // 1 million tokens with 18 decimals
const NAME        = "MyToken";
const SYMBOL      = "MTK";
module.exports = buildModule("MyTokenModule", (m) => {
  const name = m.getParameter("name", NAME);
  const symbol = m.getParameter("symbol", SYMBOL);
  const initialSupply = m.getParameter("initialSupply", INITIAL_SUPPLY);

   // 部署合约
  const token = m.contract("MyToken", [name, symbol, initialSupply]);
  // 可选：再给固定地址 mint 100 个（示范）
 //m.call(token, "mint", [m.getAccount(1), 100n * 10n ** 18n]);
  return { token };
});