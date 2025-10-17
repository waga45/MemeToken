// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MemeSunToken} from "../src/MemeSunToken.sol";
import {MerkleAirDrop} from "../src/MerkleAirDrop.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";


contract TestMerkleAirdrop is Test {
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    address public user3 = address(0x3);
    MemeSunToken public  memeSunToken;
    MerkleAirDrop public  merkleAirDrop;

    bytes32[] public leaves;
    uint256 public airDropId=1;

    function setUp() public {
        uint256 total=10000000 * 10**18;
        memeSunToken = new MemeSunToken("MemeSun","SMT",total);
        merkleAirDrop = new MerkleAirDrop();
        memeSunToken.transfer(address(merkleAirDrop),10000 * 10**18);
        console.log("merkleAirDrop balance:",memeSunToken.balanceOf(address(merkleAirDrop)));

        console.log(unicode"开始构建Merkle空投名单树");
        //模拟构建merkle tree
        //假设2个用户空投金额分别是 50 100 150
        uint256 airdropAmount1=50 * 10**18;
        uint256 airdropAmount2=100 * 10**18;
        uint256 airdropAmount3=150 * 10**18;
        leaves.push(keccak256(abi.encodePacked(uint256(1),user1,airdropAmount1)));
        leaves.push(keccak256(abi.encodePacked(uint256(2),user2,airdropAmount2)));
        leaves.push(keccak256(abi.encodePacked(uint256(3),user3,airdropAmount3)));
        bytes32 hashA;
        if (leaves[0]<leaves[1]){
            hashA=keccak256(abi.encodePacked(leaves[0],leaves[1]));
        }else{
            hashA=keccak256(abi.encodePacked(leaves[1],leaves[0]));
        }
        bytes32 root;
        if(hashA<leaves[2]){
            root=keccak256(abi.encodePacked(hashA,leaves[2]));
        }else{
            root=keccak256(abi.encodePacked(leaves[2],hashA));
        }
        //创建一个空投活动
        merkleAirDrop.createAirdrop(airDropId, root, address(memeSunToken), 10000 * 10**18, block.timestamp, block.timestamp + 1 days);
        console.log(unicode"空投活动创建成功:",airDropId);
    }

    //测试空投-异常领取
    function test_airdrop_failed() public {
        vm.startPrank(user1);
        //模拟生成user1的 proof
        uint256 index1=1;
        uint256 amount=1*10**18;//测试金额不对
        //路径 从下往上节点
        //user1兄弟节点
        //hashA的兄弟节点
        //最小路径
        bytes32[] memory merkleProof=new bytes32[](2);
        merkleProof[0]=leaves[1];
        merkleProof[1]=leaves[2];
        merkleAirDrop.claim(airDropId,index1,amount,merkleProof);
        console.log(unicode"用户1领取空投:",airDropId);
        bool receiverFlag=merkleAirDrop.isClaimed(airDropId, index1);
        console.log(unicode"空投领取结果:",receiverFlag);
        vm.expectRevert(MerkleAirDrop.VerifyFailed.selector);
        vm.stopPrank();
    }

    //正常领取
    function test_airdrop_success() public {

        //模拟生成user1的 proof
        uint256 index1=1;
        uint256 amount=50*10**18;
        //路径 从下往上节点
        //user1兄弟节点
        //hashA的兄弟节点
        //最小路径
        bytes32[] memory merkleProof=new bytes32[](2);
        merkleProof[0]=leaves[1];
        merkleProof[1]=leaves[2];
        vm.startPrank(user1);
        merkleAirDrop.claim(airDropId,index1,amount,merkleProof);
        console.log(unicode"用户1领取空投:",airDropId);
        bool receiverFlag=merkleAirDrop.isClaimed(airDropId, index1);
        console.log(unicode"空投领取结果:",receiverFlag);
        assertTrue(receiverFlag);
        vm.stopPrank();
    }
}
