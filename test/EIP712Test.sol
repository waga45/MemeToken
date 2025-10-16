// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {Test,Vm} from "forge-std/Test.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract EIP712Test is Test,EIP712{
    using ECDSA for bytes32;
    string public NAME="DAPP1";
    string public VERSION="1.0";

    bytes32 private constant ORDER_TYPEHASH = keccak256(
        "Order(address maker,address taker,uint256 amount)"
    );

    struct Order{
        address maker;
        address taker;
        uint256 amount;
    }

    constructor() EIP712(NAME,VERSION){

    }

    function setUp()public{

    }

    function testCompleteEIP712Flow() public {
        address maker = address(0x123);
        address taker = address(0x456);
        uint256 privateKey = 0xabc123;
        vm.deal(maker,10 ether);
        byte32 signtrue=0x1;
        Order memory order=new Order({maker: maker,taker:taker,amount:10});
        (, , uint256 chainId, , bytes32 domainSeparator) = getDomainInfo();
        bytes32 orderStructHash=keccak256(abi.encode(ORDER_TYPEHASH,order.maker,order.taker,order.amount));
        bytes32 orderDigest=_hashTypedDataV4(orderStructHash);
        //恢复的地址
        address recoverAddress= orderDigest.recover(signtrue);
        assertEq(recoverAddress,order.maker);
    }

    function getDomainInfo() public view returns(string memory domainName,
        string memory domainVersion,
        uint256 chainId,
        address verifyingContract,
        bytes32 domainSeparator) {
        return (name(),version(),block.chainid,address(this),_domainSeparatorV4());
    }

}
