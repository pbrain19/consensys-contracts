// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

// Banker contract to simulate a simple lending scenario using an NFT as collateral
contract Banker is ERC721AQueryable {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    ERC721AQueryable public stakableToken;
    ERC20 public lendableToken;

    // for simplicity of example, assumes a fixed amount for lending on all nfts
    uint256 public LOAN_AMOUNT;
    uint256 public availableForLending;

    constructor(
        address _stakableToken,
        address _lendableToken,
        uint256 _loanAmount
    ) ERC721A("StakedBasicNFT", "sBNFT") {
        stakableToken = ERC721AQueryable(_stakableToken);
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
        
        _safeMint(msg.sender, 1);

    }

    function repay(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
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
        _burn(tokenId);
    }

    function addFunding(uint256 amount) public {
        lendableToken.transferFrom(msg.sender, address(this), amount);
        availableForLending += amount;
    }

}
