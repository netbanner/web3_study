import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("MyTokenModule", (m) => {
  const counter = m.contract("MyTokenModule");

  const initialOwner = m.getParameter("initialOwner", "0x你的钱包地址");

  const zyToken = m.contract("ZYToken", [initialOwner]);

  return { counter };
});