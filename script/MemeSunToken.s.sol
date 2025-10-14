// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {MemeSunToken} from "../src/MemeSunToken.sol";
//部署
contract DeployMemeSunToken is Script {
    function run() external {
        // 包装部署交易，并广播，从而在链上部署合约
        vm.startBroadcast();
        string memory NAME= "MemeSun";
        string memory SYMBOL="MST";
        uint256 SURPLUS=10000000 * 10**18;
        MemeSunToken token=new MemeSunToken(NAME,SYMBOL,SURPLUS);
        console.log(token.balanceOf(msg.sender));
        vm.stopBroadcast();
    }
}