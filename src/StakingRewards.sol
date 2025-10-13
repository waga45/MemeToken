// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//质押挖矿
//- Stake: MemeSunToken
//- Unstake: MemeSunToken
//- Claim: MemeSunToken
contract StakingRewards is ReentrancyGuard {
    address public owner;
    IERC20 public stakingToken;
    mapping(address=>Stake) public stakes;
    mapping(address=>uint256) public rewardsAmount;
    uint256 public totalStakedAmount;
    uint256 public totalRewardsAmount;//总质押奖励金额
    uint256 constant public miniLockDuration= 15*24*60*60;//最小锁仓时间，15天
    uint256 public constant PRECISION = 1e18; // 精度因子
    uint256 public rewardTokenPerSecond;//每秒奖励token数量
    uint256 private hasDrawAmount;//已经解除质押金额
    address[] public stakers;//所有质押用户
    uint256 constant public withdrawFee=2;//奖励体现手续费2%，进入流动性池子
    struct Stake {
        uint256 amount;//质押金额
        uint256 time; //质押时间
        uint256 claimTime; //最后一次领取奖励时间
    }

    event Staked(address indexed user, uint256 amount, uint256 time);
    event Unstake(address indexed user, uint256 amount, uint256 time);
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

    //just stake token and claim token
    constructor(address stakeToken,uint256 _totalRewardsAmount){
        owner=msg.sender;
        totalRewardsAmount=_totalRewardsAmount;
        rewardTokenPerSecond=totalRewardsAmount/(365*24*60*60);
        stakingToken =IERC20(stakeToken);
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
        bool result= stakingToken.transferFrom(msg.sender,address(this),amount);
        if (!result){
            revert TransferFailed(msg.sender,amount);
        }
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
        uint256 newRewards = rewardTokenPerSecond * timeDiff;
        return (amount/totalStakedAmount)*newRewards;
    }

    //领取奖励--只做记录 不实际转账，提现的时候再转账
    function claimReward() public nonReentrant returns (bool) {
        require(msg.sender!=address(0));
        Stake storage sk=stakes[msg.sender];
        if (sk.amount<=0){
            return false;
        }
        uint256 rewards=calcRewardToken(sk.amount,sk.time);
        if (rewards<=0){
            return false;
        }
        totalRewardsAmount+=rewards;
        rewardsAmount[msg.sender]+=rewards;
        sk.claimTime=block.timestamp;
        sk.time=block.timestamp;

        emit Claim(msg.sender,rewards,block.timestamp);
        return true;
    }

    //解除质押,将质押金额+奖励金额一并提取
    function unStaked() public nonReentrant returns (bool){
        require(msg.sender!=address(0));
        Stake storage sk = stakes[msg.sender];
        if (sk.amount<=0){
            return false;
        }
        //检查是否超过最小锁仓时间
        if (block.timestamp-sk.time<miniLockDuration){
            revert UnFulfill();
        }
        uint256 stakeAmount=sk.amount;
        uint256 stakeStartTime=sk.time;
        sk.amount=0;
        sk.time=0;
        uint256 reward=calcRewardToken(stakeAmount, stakeStartTime);
        uint256 totalRewardAmount=reward+rewardsAmount[msg.sender];
        //calculate reward fee
        uint256 fee=totalRewardAmount*withdrawFee/100;
        totalRewardAmount-=fee;
        uint256 totalAmount=stakeAmount+totalRewardAmount;
        
        rewardsAmount[msg.sender]=0;
        totalStakedAmount-=stakeAmount;
        if (totalStakedAmount-hasDrawAmount>=totalAmount){
            bool flag=stakingToken.transferFrom(address(this), msg.sender, totalAmount);
            if (!flag){
                revert TransferFailed(msg.sender,totalAmount);
            }
        }else{
            //need from token transfer
            
        }
        hasDrawAmount+=totalAmount;
    }

}
