// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract BasicNFT is ERC721AQueryable {
    //owner el multi-sig wallet and save the erc20 como allow to mit
    constructor() ERC721A("BasicNFT", "BNFT") {}

    function safeMint(address to, uint256 quantity) public {
        _safeMint(to, quantity);
    }
}
