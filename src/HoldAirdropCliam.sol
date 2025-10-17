// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//空投活动合约 通过EIP712签名验证
//useing EIP-712 safe sign, by backend gen signature,and just fulfil condition by biz
contract HoldAirdropCliam is ReentrancyGuard,EIP712 {
    using ECDSA for bytes32;
    address public immutable owner;
    string private constant NAME="MemeSunAirDrop";
    string private constant VERSION = "1.0.0";
    using SafeERC20 for IERC20;
    IERC20 public immutable rewardToken;
    address public authSigner;
    mapping(uint256 => bool) public usedNonce;//维护已经使用的nonce，由后台维护
    struct AirdropVoucher{
        uint256 id;
        address account;
        uint256 amount;
        uint256 nonce;
        uint256 expire;
    }
    bytes32 private constant VOUCHER_TYPEHASH =keccak256("AirdropVoucher(uint256 id,address account,uint256 amount,uint256 nonce,uint256 expire)");

    error OnlyOwnerCall();
    error NotExitAirDrop();
    error ExpireTime();
    error HasRecovered();
    error SignVerifyFiled();
    error NotEnoughBalance();

    event EventClaimed(address indexed account,uint256 indexed airdropId,uint256 amount,uint256 timestamp);

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwnerCall();
        }
        _;
    }

    constructor(address token,address signer) EIP712(NAME,VERSION){
        owner = msg.sender;
        authSigner=signer;
        rewardToken=IERC20(token);
    }
    //to update signer
    function updateAuthSigner(address newSigner) external onlyOwner  {
        authSigner=newSigner;
    }

    //calculate sigtrue
    function hashVoucher(uint256 id,address account,uint256 amount,uint256 nonce,uint256 expire) internal view returns(bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(VOUCHER_TYPEHASH,id,account,amount,nonce,expire)
        );
        return _hashTypedDataV4(structHash);
    }

    //领取空投  calldata 只读 低成gas，memory需要复制到内存 gas消耗多
    function claimBySignature(uint256 id,uint256 amount,uint256 nonce,uint256 expire,bytes calldata signature) external nonReentrant returns(bool) {
        if (id<=0){
            revert NotExitAirDrop();
        }
        if(block.timestamp>expire){
            revert ExpireTime();
        }
        if(usedNonce[nonce]){
            revert HasRecovered();
        }
        uint256 balance=rewardToken.balanceOf(address(this));
        if(balance<amount){
            revert NotEnoughBalance();
        }
        bytes32 sigs=hashVoucher(id,msg.sender,amount,nonce,expire);
        address signer=sigs.recover(signature);
        if(signer!=authSigner){
            revert SignVerifyFiled();
        }
        usedNonce[nonce]=true;
        //claim
        rewardToken.safeTransfer(msg.sender,amount);

        emit EventClaimed(msg.sender,id,amount,block.timestamp);
        return true;
    }

}