pragma solidity 0.8.17;

contract CustomModule {
    string public str;

    function getStr() public view returns (string memory) {
        return str;
    }

    function setStr(string memory _str) public {
        str = _str;
    }
}
