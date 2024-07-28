import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import hre, { ignition } from "hardhat";
import BankerModule, { LOAN_AMOUNT } from "../ignition/modules/Banker";
import { parseEther, getAddress } from "viem";
import { expect } from "chai";

describe("Banker", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployTestSetup() {
    const { banker, nft, token } = await ignition.deploy(BankerModule);

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.viem.getWalletClients();

    const publicClient = await hre.viem.getPublicClient();

    const nftAsBorrower = await hre.viem.getContractAt(
      "BasicNFT",
      nft.address,
      { client: { wallet: otherAccount } }
    );

    const tokenAsBorrower = await hre.viem.getContractAt(
      "Usdc",
      token.address,
      { client: { wallet: otherAccount } }
    );

    const tokenAsOwner = await hre.viem.getContractAt("Usdc", token.address, {
      client: { wallet: owner },
    });

    const bankerAsOwner = await hre.viem.getContractAt(
      "Banker",
      banker.address,
      {
        client: { wallet: owner },
      }
    );

    const bankerAsBorrower = await hre.viem.getContractAt(
      "Banker",
      banker.address,
      {
        client: { wallet: otherAccount },
      }
    );

    const twoHundred = parseEther("200");

    // mint some tokens to deposit to banker contract
    await tokenAsOwner.write.mint([twoHundred]);

    // approve the loan amount so it can be moved
    await tokenAsOwner.write.approve([getAddress(banker.address), LOAN_AMOUNT]);

    // mint an nft for deposit
    await nftAsBorrower.write.safeMint([
      getAddress(otherAccount.account.address),
      BigInt(1),
    ]);

    // approve for transfer to borrow
    await nftAsBorrower.write.approve([banker.address, BigInt(0)]);

    return {
      owner,
      otherAccount,
      publicClient,
      banker,
      nft,
      token,
      nftAsBorrower,
      tokenAsBorrower,
      tokenAsOwner,
      bankerAsOwner,
      bankerAsBorrower,
    };
  }

  describe("Banking", function () {
    it("should allow you to deposit money", async function () {
      const { owner, bankerAsOwner, token, banker, tokenAsOwner } =
        await loadFixture(deployTestSetup);

      await bankerAsOwner.write.addFunding([LOAN_AMOUNT]);

      expect(await token.read.balanceOf([getAddress(banker.address)])).to.equal(
        LOAN_AMOUNT
      );

      expect(await banker.read.availableForLending()).to.equal(LOAN_AMOUNT);
      // expect 100 because we minted 200 and only deposited 100
      expect(
        await tokenAsOwner.read.balanceOf([getAddress(owner.account.address)])
      ).to.equal(LOAN_AMOUNT);
    });

    it("should allow the borrower stake their token to get a loan", async function () {
      const {
        bankerAsOwner,
        token,
        banker,
        tokenAsOwner,
        bankerAsBorrower,
        otherAccount,
      } = await loadFixture(deployTestSetup);

      await bankerAsOwner.write.addFunding([LOAN_AMOUNT]);

      // we only minted 1 nft and have it saved to this spot
      await bankerAsBorrower.write.borrow([BigInt(0)]);

      expect(
        await token.read.balanceOf([getAddress(otherAccount.account.address)])
      ).to.equal(LOAN_AMOUNT);

      expect(await banker.read.availableForLending()).to.equal(BigInt(0));

      // expect 100 because we minted 200 and only deposited 100
      expect(
        await tokenAsOwner.read.balanceOf([getAddress(banker.address)])
      ).to.equal(BigInt(0));
    });

    it("should allow the borrower to repay their loan", async function () {
      const {
        bankerAsOwner,
        token,
        banker,
        tokenAsBorrower,
        bankerAsBorrower,
        otherAccount,
      } = await loadFixture(deployTestSetup);

      await bankerAsOwner.write.addFunding([LOAN_AMOUNT]);

      // we only minted 1 nft and have it saved to this spot
      await bankerAsBorrower.write.borrow([BigInt(0)]);

      // once we have borrowed the money we need to approve the contract to be able to transfer it back
      await tokenAsBorrower.write.approve([
        getAddress(banker.address),
        LOAN_AMOUNT,
      ]);

      await bankerAsBorrower.write.repay([BigInt(0)]);

      expect(
        await token.read.balanceOf([getAddress(otherAccount.account.address)])
      ).to.equal(BigInt(0));

      expect(await banker.read.availableForLending()).to.equal(LOAN_AMOUNT);
    });
  });
});
