pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

contract ERC20Faucet{
    IERC20 public token;
    constructor(address _token){
        token= IERC20(_token);
    }

    receive () external payable {
        require(msg.value==0,"Thanks but no, send zero ether please");
        token.transfer(msg.sender, 1000000);
    }
}