// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// Banker contract to simulate a simple lending scenario using an NFT as collateral
contract Banker {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    ERC721A public stakableToken;
    ERC20 public lendableToken;

    // for simplicity of example, assumes a fixed amount for lending on all nfts
    uint256 public LOAN_AMOUNT;
    uint256 public availableForLending;

    // good enough for for simulation but ideally Banker contract emits an NFT with term details in metadata
    EnumerableMap.UintToAddressMap private lendingLedger;

    constructor(
        address _stakableToken,
        address _lendableToken,
        uint256 _loanAmount
    ) {
        stakableToken = ERC721A(_stakableToken);
        lendableToken = ERC20(_lendableToken);
        LOAN_AMOUNT = _loanAmount;
    }

    function borrow(uint256 tokenId) public {
        require(
            lendableToken.balanceOf(address(this)) >= LOAN_AMOUNT,
            "Contract does not have enough to make loan"
        );

        require(
            stakableToken.getApproved(tokenId) == address(this),
            "Contract is not approved to transfer this token"
        );

        stakableToken.transferFrom(msg.sender, address(this), tokenId);

        lendableToken.transfer(msg.sender, LOAN_AMOUNT);
        availableForLending -= LOAN_AMOUNT;
        lendingLedger.set(tokenId, msg.sender);
    }

    function repay(uint256 tokenId) public {
        require(
            lendingLedger.get(tokenId) == msg.sender,
            "Msg.sender is not owner of loan"
        );
        require(
            lendableToken.balanceOf(msg.sender) >= LOAN_AMOUNT,
            "Contract does not have enough to make loan"
        );

        require(
            lendableToken.transferFrom(msg.sender, address(this), LOAN_AMOUNT),
            "Contract unable to transfer tokens to settle debt"
        );

        stakableToken.transferFrom(address(this), msg.sender, tokenId);

        availableForLending += LOAN_AMOUNT;
        lendingLedger.remove(tokenId);
    }

    function addFunding(uint256 amount) public {
        lendableToken.transferFrom(msg.sender, address(this), amount);
        availableForLending += amount;
    }
}
