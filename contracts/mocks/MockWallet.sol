pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockWallet {
    address public pubKey;
    IERC721 public token;

    constructor(address _pubKey, address _token) {
        pubKey = _pubKey;
        token = IERC721(_token);
    }

    function transferNFT(address to, uint256 tokenId) external {
        require(msg.sender == pubKey, "incorrect signer public key");
        token.transferFrom(address(this), to, tokenId);
    }
}
