// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract HoldAirdropCliam is ReentrancyGuard {
    address public owner;
    error OnlyOwnerCall();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwnerCall();
        }
        _;
    }

    constructor(){

    }
}