// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MemeSunToken} from "../src/MemeSunToken.sol";
import {HoldAirdropCliam} from "../src/HoldAirdropCliam.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";


//EIP712签名验证领空投测试
contract TestEIP712AirDropCliam  is Test,EIP712{
    MemeSunToken public memeSunToken;
    HoldAirdropCliam public airdropCliam;
    address public authSigner=address(0x8977792D4D95601cf49824E2c09f29d43F27b8A1);
    address public user1=address(0x02);
    
    constructor() EIP712("MemeSunAirDrop","1.0.0"){

    }

    function setUp() public {
         vm.startPrank(user1);
        uint256 total=10000000 * 10**18;
        memeSunToken = new MemeSunToken("MemeSun","SMT",total);
        airdropCliam= new HoldAirdropCliam(address(memeSunToken),authSigner);
        console.log("memeSunToken:",address(memeSunToken));
        console.log("airdropCliam:",address(airdropCliam));
        memeSunToken.transfer(address(airdropCliam),10000 * 10**18);
        console.log("airdropCliam balance:",memeSunToken.balanceOf(address(airdropCliam)));
        vm.stopPrank();
    }
    //测试EIP712签名验证
    function test_cliam() public {
        //生成一组临时秘钥
        (address user, uint256 userPk) = makeAddrAndKey("user1");
        console.log("signer:",userPk);
        console.log("user1:",user);
        //模拟后台请求，获取到领取空投数据
        vm.startPrank(user1);
        uint256 id=1;
        uint256 amount=10 * 10**18;
        uint256 nonce=1;
        uint256 expire=block.timestamp + 1 days;
        airdropCliam.updateAuthSigner(user);
        bytes32 sign=_hashVoucher(id,user1,amount,nonce,expire);
        (uint8 v,bytes32 r,bytes32 s)= vm.sign(userPk,sign);
        bytes memory signature= abi.encodePacked(r,s,v);
        bool flag=airdropCliam.claimBySignature(id,amount,nonce,expire,signature);
        assertTrue(flag);

        console.log("airdropCliam balance:",memeSunToken.balanceOf(address(airdropCliam)));
        console.log("user1 balance:",memeSunToken.balanceOf(user1));

        //测试再次领取
        flag=airdropCliam.claimBySignature(id,amount,nonce,expire,signature);
        console.log(unicode"测试重放领取:",flag);

        vm.stopPrank();
    }

    function _hashVoucher(uint256 id,address account,uint256 amount,uint256 nonce,uint256 expire) internal view returns(bytes32) {
        bytes32 domainSeparator = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes("MemeSunAirDrop")),
            keccak256(bytes("1.0.0")),
            block.chainid,
            address(airdropCliam)
        ));
    
        bytes32 VOUCHER_TYPEHASH =keccak256("AirdropVoucher(uint256 id,address account,uint256 amount,uint256 nonce,uint256 expire)");
        bytes32 structHash = keccak256(abi.encode(
            VOUCHER_TYPEHASH,
            id,
            account,
            amount,
            nonce,
            expire
        ));
        bytes32 digest=keccak256(abi.encodePacked("\x19\x01",domainSeparator,structHash));
        return digest;
    }

}