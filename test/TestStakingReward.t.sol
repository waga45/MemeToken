// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {StakingRewards} from "../src/StakingRewards.sol";
import {MemeSunToken} from "../src/MemeSunToken.sol";
import {IUniswapV2Router02} from "../src/IUniswapV2Router02.sol";

contract TestStakingReward is Test {
    StakingRewards public stakingRewards;
    MemeSunToken public memeSunToken;
    IUniswapV2Router02 public uniswapV2Router;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    uint256 public constant PRECISION = 10**18;
    function setUp() public {
        uint256 total=10000000 * 10**18;
        memeSunToken = new MemeSunToken("MemeSun","SMT",total);
        uniswapV2Router = IUniswapV2Router02(0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008);
        stakingRewards = new StakingRewards(address(memeSunToken), address(uniswapV2Router),total*50/100);

        console.log("memeSunToken:",address(memeSunToken));
        console.log("uniswapV2Router:",address(uniswapV2Router));
        console.log("stakingRewards:",address(stakingRewards));

        memeSunToken.transfer(user1,10000*10**18);
        memeSunToken.transfer(user2,10000*10**18);

        console.log("user1:",user1);
        console.log("user2:",user2);
    }

    //测试质押
    function test_State() public{
        vm.startPrank(user1);

        memeSunToken.approve(address(stakingRewards),10000*10**18);
        bool flag=stakingRewards.state(10000*10**18);
        vm.assertEq(flag,true);
        console.log(unicode"质押合约余额:",memeSunToken.balanceOf(address(stakingRewards))/PRECISION);
        vm.stopPrank();

        console.log(unicode"当前质押总金额：",stakingRewards.totalStakedAmount()/PRECISION);
        console.log(unicode"每秒释放奖励：",weiToEthWithDecimals(stakingRewards.rewardTokenPerSecond()/PRECISION,8));

        //模拟用户2质押
        vm.startPrank(user2);
        memeSunToken.approve(address(stakingRewards),5000*10**18);
        flag=stakingRewards.state(5000*10**18);
        vm.assertEq(flag,true);
        console.log(unicode"用户2质押后合约余额:",memeSunToken.balanceOf(address(stakingRewards))/PRECISION);
        console.log(unicode"当前质押总金额：",stakingRewards.totalStakedAmount()/PRECISION);
        console.log(unicode"每秒释放奖励：",stakingRewards.rewardTokenPerSecond()/PRECISION);
        vm.stopPrank();

    }


    function weiToEthWithDecimals(uint256 weiAmount, uint8 decimals) public pure returns (string memory) {
        uint256 ethWhole = weiAmount / 1 ether;
        uint256 remainder = weiAmount % 1 ether;

        // 计算指定小数位数
        uint256 divisor = 10**(18 - decimals);
        uint256 fractionalPart = remainder / divisor;

        // 构建字符串
        return string(abi.encodePacked(
            _uintToString(ethWhole),
            ".",
            _padZeros(fractionalPart, decimals)
        ));
    }
    function _padZeros(uint256 number, uint8 length) internal pure returns (string memory) {
        string memory str = _uintToString(number);
        uint256 currentLength = bytes(str).length;

        if (currentLength >= length) {
            return str;
        }

        bytes memory zeros = new bytes(length - currentLength);
        for (uint256 i = 0; i < length - currentLength; i++) {
            zeros[i] = bytes1('0');
        }

        return string(abi.encodePacked(zeros, str));
    }

    function _uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }

        uint256 temp = value;
        uint256 digits;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }

        return string(buffer);
    }
}