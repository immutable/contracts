pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract MockWallet {
    event Received(address, address, uint256, uint256, bytes);

    event ReceivedBatch(address, address, uint256[], uint256[], bytes);

    function transferNFT(address token, address from, address to, uint256 tokenId) external {
        IERC721(token).transferFrom(from, to, tokenId);
    }

    function transfer1155(address token, address from, address to, uint256 tokenId, uint256 amount) external {
        IERC1155(token).safeTransferFrom(from, to, tokenId, amount, "");
    }

    function batchTransfer1155(
        address token,
        address from,
        address to,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external {
        IERC1155(token).safeBatchTransferFrom(from, to, tokenIds, amounts, "");
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        emit Received(operator, from, id, value, data);
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        emit ReceivedBatch(operator, from, ids, values, data);
        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }
}
