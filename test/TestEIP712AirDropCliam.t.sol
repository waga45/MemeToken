// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MemeSunToken} from "../src/MemeSunToken.sol";
import {HoldAirdropCliam} from "../src/HoldAirdropCliam.sol";

//EIP712签名验证领空投测试
contract TestEIP712AirDropCliam  is Test{
    MemeSunToken public token;
    HoldAirdropCliam public airdropCliam;
    address public authSigner=address(0x01);
    address public user1=address(0x02);
    function setUp() public {
        uint256 total=10000000 * 10**18;
        memeSunToken = new MemeSunToken("MemeSun","SMT",total);
        airdropCliam= new HoldAirdropCliam(address(memeSunToken),authSigner);
        console.log("memeSunToken:",address(memeSunToken));
        console.log("airdropCliam:",address(airdropCliam));
        memeSunToken.transfer(address(airdropCliam),10000 * 10**18);
        console.log("airdropCliam balance:",memeSunToken.balanceOf(address(airdropCliam)));
    }

    function test_cliam() public {
        //模拟后台请求，获取到领取空投数据
        vm.startPrank(user1);
        uint256 id=1;
        uint256 amount=10 * 10**18;
        uint256 nonce=1;
        uint256 expire=block.timestamp + 1 days;
        bytes memory signature=0x1234567890123456789012345678901234567890123456789012345678901234;
        bool flag=airdropCliam.claimBySignature(id,amount,nonce,expire,signature);
        assertTrue(flag);
        vm.stopPrank();
        console.log("airdropCliam balance:",memeSunToken.balanceOf(address(airdropCliam)));
        console.log("user1 balance:",memeSunToken.balanceOf(user1));
    }

}