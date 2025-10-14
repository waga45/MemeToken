pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../src/IUniswapV2Router02.sol";

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint);
}

//给UniswapRouterV2授权MemeSunToken
contract TestUniswapApprove is Script {

    //测试sepolia地址
    address constant UniswapFactroy=0x7E0987E5b3a30e3f2828572Bb659A548460a3003;
    address constant UniswapRouterV2=0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008;
    address constant WETH = 0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    address constant MemeTokenAddress=0x2CC07d6Ff706AcE3D4f984025afdf0960712A177;

    function run() external {
        // 包装部署交易，并广播，从而在链上部署合约
        vm.startBroadcast();

        //把50%代币授权给uniswapRouterV2
        IERC20 token=IERC20(MemeTokenAddress);
        IUniswapV2Factory factory = IUniswapV2Factory(UniswapFactroy);
        IUniswapV2Router02 router = IUniswapV2Router02(UniswapRouterV2);

        console.log(unicode"=== Uniswap V2 流动性添加流程 ===");
        console.log(unicode"代币地址:", MemeTokenAddress);
        console.log(unicode"工厂地址:", UniswapFactroy);
        console.log(unicode"路由器地址:", UniswapRouterV2);

        address pair=factory.getPair(MemeTokenAddress,WETH);
        if (pair==address(0)){
            console.log(unicode"MemeSun-->Eth 交易对未创建");
            createPair();
        }
        //授权 50%
        uint256 totalBalance=token.balanceOf(msg.sender);
        uint256 amount=(totalBalance*50)/100 * 10**18;
        uint256 eth=1 ether;
        console.log(unicode"准备添加流动性:");
        console.log(unicode"代币数量:", amount);
        console.log(unicode"ETH 数量:", eth);

        bool result= token.approve(UniswapRouterV2,amount);
        require(result,"approve failed");

        //检查授权是否成功
        uint256 allowance=token.allowance(address(this),UniswapRouterV2);
        require(allowance>=amount,"approve failed");

        //加入流动性池
        //设置交易超时时间为10分钟后
        uint256 deadline = block.timestamp + 10 minutes;
        //5%的滑点
        uint256 tokenAmountMin = amount * 95 / 100;
        uint256 ethAmountMin = eth * 95 / 100;
        console.log(unicode"滑点保护设置:");
        console.log(unicode"最小代币数量:", tokenAmountMin);
        console.log(unicode"最小 ETH 数量:", ethAmountMin);
        console.log(unicode"截止时间:", deadline);
        //执行交易
        //1ETH= 500w MemeSunToken
        console.log(unicode"开始初始化流动性池...");
        (uint amountToken, uint amountETH, uint liquidity) = router.addLiquidityETH{value:eth}(
            MemeTokenAddress,
            amount,
            tokenAmountMin,
            ethAmountMin,
            msg.sender,
            deadline);
        console.log(unicode"=== 流动性添加结果 ===");
        console.log(unicode"实际使用代币数量:", amountToken);
        console.log(unicode"实际使用 ETH 数量:", amountETH);
        console.log(unicode"获得 LP 代币数量:", liquidity);

        //查看结果
        address finalPair = factory.getPair(MemeTokenAddress, WETH);
        console.log(unicode"最终交易对地址:", finalPair);

        //检查交易对信息
        IUniswapV2Pair uniswapv2Pair=IUniswapV2Pair(finalPair);
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = uniswapv2Pair.getReserves();
        console.log(unicode"=== 流动性储备 ===");
        console.log("Reserve0:", reserve0);
        console.log("Reserve1:", reserve1);
        console.log(unicode"最后更新时间:", blockTimestampLast);
        vm.stopBroadcast();
    }
    //创建交易对
    function createPair() internal returns(address) {
        IUniswapV2Factory factory=IUniswapV2Factory(UniswapFactroy);
        console.log(unicode"开始创建交易对...");
        address newPair = factory.createPair(MemeTokenAddress, WETH);
        console.log(unicode"交易对创建成功，地址:", newPair);
        return newPair;
    }
}