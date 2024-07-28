// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";

contract BasicNFT is ERC721AQueryable {
    address erc20contract;
    string public TOKEN_URL =
        "ipfs://bafybeigyhoucmchrpa2irnuvdlwnfcsjnn7gp6qkdi2wnaar7qjph2ntoy/";

    //owner el multi-sig wallet and save the erc20 como allow to mit
    constructor() ERC721A("BasicNFT", "BNFT") {}

    function _baseURI() internal view override returns (string memory) {
        return TOKEN_URL;
    }

    function safeMint(address to, uint256 quantity) public {
        _safeMint(to, quantity);
    }
}
