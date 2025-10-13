// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//this is great token,you must take it
contract MemeSunToken is ERC20 {
    address public owner;
    error OnlyOwnerCall();
    error InsufficientBalance();
    error BigThanZero();

    modifier onlyOwner() {
        if(msg.sender != owner){
            revert OnlyOwnerCall();
        }
        _;
    }

    constructor(string memory name,string memory symbol,uint256 surplus) ERC20(name,symbol){
        owner = msg.sender;
        _mint(msg.sender,surplus);
    }

    function mint(address to,uint256 amount) external onlyOwner{
        if(amount<=0){
            revert BigThanZero();
        }
        _mint(to,amount);
    }

    function burn(address from,uint256 amount) external onlyOwner{
        if(balanceOf(from)<amount){
            revert InsufficientBalance();
        }
        if(amount<=0){
            revert BigThanZero();
        }
        _burn(from,amount);
    }

}
