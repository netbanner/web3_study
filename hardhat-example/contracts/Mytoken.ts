import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { network } from "hardhat";

describe("MyToken (Hardhat v3 + viem)", async () => {
  const { viem } = await network.connect();
  const [owner, alice] = await viem.getWalletClients();

  it("should deploy with initial supply to owner", async () => {

    const token = await viem.deployContract("MyToken", [
      "MyToken",
      "MTK",
    ]);
    const ownerBalance = await token.read.balanceOf([owner.account.address]);
  });

  it("should allow only owner to mint", async () => {
    const token = await viem.deployContract("MyToken", [
      "MyToken",
      "MTK",
    ]);
    await assert.rejects(
      token.write.mint([alice.account.address, 1n], {
        account: alice.account,
      })
    );
  });
});