import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { parseEther } from "viem";

export const LOAN_AMOUNT: bigint = parseEther("100");

const BankerModule = buildModule("BankerModule", (m) => {
  const token = m.contract("Usdc", [], {});
  const nft = m.contract("BasicNFT", [], {});
  const banker = m.contract("Banker", [nft, token, LOAN_AMOUNT], {});

  return { token, nft, banker };
});

export default BankerModule;
