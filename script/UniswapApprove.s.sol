pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
   function addLiquidityETH(
        address token, //代币地址
        uint amountTokenDesired, //期望添加的代币数量
        uint amountTokenMin, //最小添加的代币数量
        uint amountETHMin, //最小添加的ETH数量
        address to, //凭证LP代币接收地址
        uint deadline //交易有效期
    ) external payable returns (
        uint amountToken,  //实际使用代币数量
        uint amountETH, //实际使用ETH数量
        uint liquidity //实际获得LP 代币数量
    );
}
//给UniswapRouterV2授权MemeSunToken
contract UniswapApprove is Script {
    address constant uniswapRouterV2=0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
    function run() external {
        // 包装部署交易，并广播，从而在链上部署合约
        vm.startBroadcast();
        
        address MemeSunToken=0x2CC07d6Ff706AcE3D4f984025afdf0960712A177;
        uint256 amount=10000000 * 0.5 * 10**18;
        //把50%代币授权给uniswapRouterV2
        IERC20 token=IERC20(MemeSunToken);

        bool result= token.approve(uniswapRouterV2,amount);
        require(result,"approve failed");

        //检查授权是否成功
        uint256 allowance=token.allowance(address(this),uniswapRouterV2);
        require(allowance>=amount,"approve failed");

        //加入流动性池
        IUniswapV2Router02 router = IUniswapV2Router02(uniswapRouterV2);
        //设置交易超时时间为10分钟后
        uint256 deadline = block.timestamp + 10 minutes;
   
        //执行交易
        //1ETH= 500w MemeSunToken
        uint amountTokenMin=amount*3/100;
        router.addLiquidityETH(MemeSunToken,amount, amountTokenMin, 0.95 ether, msg.sender, deadline);
        vm.stopBroadcast();
    }
}