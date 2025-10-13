// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {Test,Vm} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {MemeSunToken} from "../src/MemeSunToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract MemeSunTokenTest is Test{
    MemeSunToken public token;
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    string public NAME ="MemeSun";
    string public SYMBOL="SMT";
    uint256 public SURPLUY = 10000000 * 10**18;

    function setUp()public{
        token =new MemeSunToken(NAME,SYMBOL,SURPLUY);
        console.log("token.owner:",token.owner());
        console.log("token.address:",address(token));
    }

    function testTokenInfo() public view{
        assertEq(token.name(),NAME);
        assertEq(token.symbol(),SYMBOL);
        assertEq(token.totalSupply(),SURPLUY);
        console.log("total:",token.totalSupply());
    }

    function testBalance() public {
        uint256 ownerBalance=token.balanceOf(owner);
        console.log("ownerBalance:",ownerBalance);
        console.log("user1Balance:",token.balanceOf(user1));
        assertEq(ownerBalance,SURPLUY);
        uint256 amount = 1 * 10**18;
        bool flag=token.transfer(user1,amount);
        console.log(unicode"转账结果:",flag);
        uint256 user1Balance = token.balanceOf(user1);
        console.log(unicode"转账后用户1金额:",user1Balance);
        console.log("ownerBalance:",token.balanceOf(owner));
        assertEq(user1Balance,amount);
    }

    function testTransferEnoughBalance() public  {
        bool flag=token.transfer(user1,SURPLUY+100000);
        console.log(unicode"转账结果:",flag);
        assertEq(flag,true);
    }
    function testApproveError() public {
        vm.prank(user2);
        uint256 amount = 1 * 10**18;
        //正确期望  user2 给 user1授权
        vm.expectEmit(true, true, true, true);
        //期待事件
        emit IERC20.Approval(user2,user1,amount);

        //开始记录日志
        vm.recordLogs();
        bool flag=token.approve(user1,amount);
        console.log("approve.flag:",flag);
        vm.stopPrank();

        //拿到
        Vm.Log[] memory logs=vm.getRecordedLogs();
        //日志解码
        address eventOwner = address(uint160(uint256(logs[0].topics[1])));
        address eventSpender = address(uint160(uint256(logs[0].topics[2])));
        uint256 eventAmount = abi.decode(logs[0].data, (uint256));
        console.log("event.owner:",eventOwner);
        console.log("event.spender:",eventSpender);
        console.log("event.amount:",eventAmount);

        uint256 allowanceBalance =token.allowance(user2,user1);
        console.log(allowanceBalance);
    }

    function testApproveOk() public{
        uint256 amount = 1 * 10**18;
        vm.prank(owner);

        //owner 授权user1  1个token金额权限
        bool flag=token.approve(user1,amount);
        console.log("approve.flag:",flag);
        vm.stopPrank();
        console.log("owner->user1:",token.allowance(owner,user1));
        vm.prank(user1);
        //user1 转1个到 user2
        flag=token.transferFrom(owner,user2,amount);
        assertEq(flag,true);
        vm.stopPrank();

        console.log("owner->user1:",token.allowance(owner,user1));
        console.log("user2Balance:",token.balanceOf(user2));
    }

    function testMintError() public{
        uint256 amount = 1000* 10**18;
        vm.prank(user1);
        token.mint(owner,amount);
        vm.stopPrank();
    }

    function testMintOk() public {
        uint256 amount = 10000* 10**18;
        console.log("total:",token.totalSupply()/10**18);
        token.mint(owner,amount);
        console.log("totalNew:",token.totalSupply()/10**18);
    }

    function testBrun() public {
        uint256 amount = 10000* 10**18;
        token.burn(owner,amount);
        console.log("totalNew:",token.totalSupply()/10**18);
    }
}


