// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;
import {console} from "forge-std/console.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IUniswapV2Router02} from "../src/IUniswapV2Router02.sol";

//质押挖矿
//- Stake: MemeSunToken
//- Unstake: MemeSunToken
//- Claim: MemeSunToken
contract StakingRewards is ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public owner;
    IERC20 public stakingToken;//Meme币
    IUniswapV2Router02 private router;
    mapping(address=>Stake) public stakes;//持币质押
    mapping(address=>uint256) public rewardsAmount;//奖励发放
    uint256 public totalStakedAmount;//总质押
    uint256 public totalRewardsAmount;//总质押奖励金额
    uint256 constant public MiniLockDuration= 15*24*60*60;//最小锁仓时间，15天
    uint256 public constant PRECISION = 1e18; // 精度因子
    uint256 public rewardTokenPerSecond;//每秒奖励token数量
    uint256 private hasDrawAmount;//已经解除质押金额
    address[] public stakers;//所有质押用户
    uint256 constant public withdrawFeeRate=2;//奖励体现手续费2%，进入流动性池子
    uint256 public waitAndLiquifyBalance;
    bool private inSwapAndLiquify;
    address private uniswapV2Addrsss;
    struct Stake {
        uint256 amount;//质押金额
        uint256 time; //质押时间
        uint256 claimTime; //最后一次领取奖励时间
    }

    event Staked(address indexed user, uint256 amount, uint256 time);
    event Unstake(address indexed user, uint256 amount, uint256 reward,uint256 time);
    event Claim(address indexed user, uint256 amount, uint256 time);

    error OnlyOwnerCall();
    error InputLessZero();
    error TransferFailed(address,uint256);
    error UnFulfill();
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OnlyOwnerCall();
        }
        _;
    }
    modifier lockTheSwap(){
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    //just stake token and claim token
    constructor(address stakeToken,address _uniswapV2Addrsss,uint256 _totalRewardsAmount){
        owner=msg.sender;
        totalRewardsAmount=_totalRewardsAmount;
        rewardTokenPerSecond=totalRewardsAmount*PRECISION/(2*365*24*60*60);
        stakingToken =IERC20(stakeToken);
        router= IUniswapV2Router02(_uniswapV2Addrsss);
    }

    //质押 you must approve first,second check balance
    function state(uint256 amount) public nonReentrant returns (bool) {
        require(msg.sender!=address(0));
        if (amount<=0) {
            revert InputLessZero();
        }
        require(totalRewardsAmount>0,"rewrad pool empty");
        require(amount<(totalRewardsAmount*50)/100,"must less totalReward");
        require(stakingToken.allowance(msg.sender,address(this))>=amount,"approve not enough");
        require(stakingToken.balanceOf(msg.sender)>=amount,"balance not enough");
        stakingToken.safeTransferFrom(msg.sender,address(this),amount);

        totalStakedAmount+=amount;
        Stake storage sk=stakes[msg.sender];
        if (sk.amount<=0){
            stakers.push(msg.sender);
        }
        sk.amount+=amount;
        sk.time=block.timestamp;//every per update
        emit Staked(msg.sender,amount,block.timestamp);
        return true;
    }

    //计算可领取奖励金额
    function earned(address account) public view returns(uint256){
        Stake memory sk=stakes[account];
        if (sk.amount<=0){
            return 0;
        }
        return calcRewardToken(sk.amount,sk.time);
    }

    //恒定 根据总奖池计算每秒奖励token数量
    function calcRewardToken(uint256 amount,uint256 startTime) private view returns(uint256){
        if (totalStakedAmount<=0){
            return 0;
        }
        if(totalRewardsAmount<=0){
            return 0;
        }
         uint256 timeDiff = block.timestamp-startTime;
         if (timeDiff==0){
            return 0;
         }
        uint256 newRewards = (rewardTokenPerSecond * timeDiff) /PRECISION;
        return (amount * newRewards) / totalStakedAmount;
    }

    //领取奖励--只做记录 不实际转账，提现的时候再转账
    function claimReward() public nonReentrant returns (bool) {
        require(msg.sender!=address(0));
        (bool result,uint256 reward,uint256 time) = claimRewardGo();
        if (!result){
            return false;
        }
        //notify
        emit Claim(msg.sender,reward,time);
        return true;
    }

    function claimRewardGo() private returns(bool result,uint256 reward,uint256 time) {
        Stake storage sk=stakes[msg.sender];
        if (sk.amount<=0){
            return (false,0,block.timestamp);
        }
        console.log("claimRewardGo ",block.timestamp);
        uint256 rewards=calcRewardToken(sk.amount,sk.time);
        if (rewards<=0){
            return (true,rewardsAmount[msg.sender],block.timestamp);
        }
        totalRewardsAmount+=rewards;
        rewardsAmount[msg.sender]+=rewards;
        sk.claimTime=block.timestamp;
        sk.time=block.timestamp;
        console.log("claimReward:",rewardsAmount[msg.sender],"  time:",sk.time);
        return (true,rewardsAmount[msg.sender],sk.time);
    }
    //解除质押,将质押金额+奖励金额一并提取
    function unStaked() public nonReentrant returns (bool){
        require(msg.sender!=address(0));
        Stake storage sk = stakes[msg.sender];
        if (sk.amount<=0){
            return false;
        }
        //检查是否超过最小锁仓时间
        if (block.timestamp-sk.time<MiniLockDuration){
            revert UnFulfill();
        }

        (bool result,uint256 reward,uint256 time)=claimRewardGo();
        console.log("result:",result,"  reward:",reward/PRECISION);
        uint256 stakeAmount=sk.amount;
        uint256 stakeStartTime=sk.time;
        sk.amount=0;
        sk.time=0;
        uint256 totalRewardAmount=reward;
        //calculate reward fee
        uint256 fee=totalRewardAmount*withdrawFeeRate/100;
        totalRewardAmount-=fee;
        waitAndLiquifyBalance+=fee;
        uint256 totalAmount=stakeAmount+totalRewardAmount;
        console.log("totalAmount:",totalAmount);

        rewardsAmount[msg.sender]=0;//reset zero
        totalStakedAmount-=stakeAmount;//cat
        uint256 currentBalance=stakingToken.balanceOf(address(this));
        console.log("currentBalance:",currentBalance);
        stakingToken.safeTransfer(msg.sender, totalAmount);

        if(waitAndLiquifyBalance/PRECISION>=100){
            addLiquify();
        }
        hasDrawAmount+=totalAmount;
        //notify
        emit Unstake(msg.sender,stakeAmount,totalRewardAmount,block.timestamp);
        return true;
    }

    //add to lq
    function addLiquify() private lockTheSwap {
        if(waitAndLiquifyBalance<100){
            return;
        }
        uint256 half = waitAndLiquifyBalance / 2;
        uint256 otherHalf = waitAndLiquifyBalance - half;
        waitAndLiquifyBalance=0;
        uint256 startETH = address(this).balance;
        stakingToken.approve(address(router),half+otherHalf);
        //一半兑换ETH
        swapToken2Eth(half);
        uint256 newEth = address(this).balance-startETH;
        //添加流动性池
        router.addLiquidityETH{value:newEth}(address(stakingToken),otherHalf,0,newEth,owner,block.timestamp);
    }

    function swapToken2Eth(uint256 amount) internal  {
        address[] memory path=new address[](2);
        path[0]=address(stakingToken);
        path[1]=router.WETH();
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount,0,path,address(this),block.timestamp);
    }

    //-----view---
    function getStake(address account) public view returns(Stake memory) {
        return stakes[account];
    }

    function getRewardToken(address account) public view returns(uint256)  {
        return rewardsAmount[account];
    }

    receive() external payable {}

}
