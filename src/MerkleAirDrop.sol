// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

//merkle树验证空投
contract MerkleAirDrop is ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public immutable owner;
    struct Airdrop{
        bytes32 merkleRoot;
        IERC20 token;
        uint256 totalAmount;
        uint256 startTime;
        uint256 endTime;
        bool exist;
    }
    mapping(uint256 => Airdrop) public airdrops;
    //这里不用 uint256->bool  gas 用户多太贵
    //优化存储 一个uint256可以存储256个用户状态，每一位Bit代表一个领取者状态
    //airdrop-->wordIndex-->256个用户状态 0000...10001
    mapping(uint256 => mapping(uint256 => uint256)) public claimedBitMap;

    event EventClaimed(uint256 indexed airdropId, uint256 indexed userId, uint256 amount,uint256 timestamp);
    event EventAirdropCreated(uint256 indexed airdropId, bytes32 merkleRoot,address token,uint256 totalAmount,uint256 startTime,uint256 endTime);

    error NotOwner();
    error InvalidId();
    error InvalidEndTime();
    error NotExist();
    error DropNotStart();
    error DropEnded();
    error HasClaimed();
    error VerifyFailed();
    modifier onlyOwner{
        if(msg.sender!=owner){
            revert NotOwner();
        }
        _;
    }

    constructor() {
        owner=msg.sender;
    }
    //to add new aridrop
    function createAirdrop(uint256 id, bytes32 merkleRoot,address token,uint256 totalAmount,uint256 startTime,uint256 endTime) external onlyOwner {
        if(id<=0){
            revert InvalidId();
        }
        if (endTime<=startTime){
            revert InvalidEndTime();
        }
        airdrops[id]=Airdrop(merkleRoot,IERC20(token),totalAmount,startTime,endTime,true);
        emit EventAirdropCreated(id,merkleRoot,token,totalAmount,startTime,endTime);
    }
    //领取空投
    function claim(uint256 id,uint256 index,uint256 amount,bytes32[] calldata merkleProof) public nonReentrant {
        Airdrop storage airdrop=airdrops[id];
        if(!airdrop.exist){
            revert NotExist();
        }
        if(airdrop.startTime>block.timestamp){
            revert DropNotStart();
        }
        if(airdrop.endTime<block.timestamp){
            revert DropEnded();
        }
        if(isClaimed(id,index)){
            revert HasClaimed();
        }
        //验证路径
        bytes32 node=keccak256(abi.encodePacked(index,msg.sender,amount));
        bool verifyResult=MerkleProof.verify(merkleProof,airdrop.merkleRoot,node);
        if(!verifyResult){
            revert VerifyFailed();
        }
        airdrop.token.safeTransfer(msg.sender,amount);
        updateClaimed(id,index);
        emit EventClaimed(id,index,amount,block.timestamp);
    }

    function isClaimed(uint256 id,uint256 index) public view returns(bool)  {
        uint256 wordIndex = index/256;
        uint256 bitIndex = index%256;
        uint256 word = claimedBitMap[id][wordIndex];
        //生成第bitIndex为位1的掩码，如果 做与运算后1表示领取
        return (word&(1 << bitIndex))!=0;
    }

    function updateClaimed(uint256 id,uint256 index) private  {
        uint256 wordIndex = index/256;
        uint256 bitIndex = index%256;
        //搞一个在 bitIndex位为1的掩码 按位或运算
        claimedBitMap[id][wordIndex]=claimedBitMap[id][wordIndex] | (1 << bitIndex);
    }

    //回收没有被领取的空投
    function recoverUnClaimed(uint256 id,address to) public onlyOwner  {
        Airdrop storage airdrop = airdrops[id];
        require(airdrop.exist,"not exist");
        require(airdrop.endTime != 0 && block.timestamp > airdrop.endTime, "not ended");
        uint256 balance=airdrop.token.balanceOf(address(this));
        if(balance>0){
            airdrop.token.safeTransfer(to,balance);
        }
    }
}