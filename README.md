## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/MemeSunToken.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

文档：https://learnblockchain.cn/docs/foundry/i18n/zh/reference/forge/forge-remappings.html

### 测试
```azure
 1.只运行与指定正则匹配的测试函数
    forge test --match-test "functionName"
 
 2. 运行与表达式不匹配的函数 
    forge test  --no-match-test "functionName"
 
 3. 只运行匹配的合约
    forge test --match-contract "contractName"
 4. 查看gas消耗报告
    --gas-report
    
 5. debug
    forge test --debug file
```
### MemeSunToken质押奖励设计
MemeSunToken发行量1000w，将20%作为质押奖励 锁定在质押合约中。预计分2年发放完毕。

1.质押奖励模型：时间线性发放  
2.发放模式：用户手动领取  
3.解除质押模式：质押起15天内不能解除提取  
4.质押奖励的2%扣除加入流动性池，作为流通

待优化：
1.设置最小质押奖励人数  
2.奖励方式调整：基础奖励速率*（1+质押时间/最长锁仓时间 * 倍率）

### MemeSunToken空投奖励设计
EIP712签名验证领取空投
1. 创建空投活动，设置领取条件
2. 客户端页面点击领取空投，后台系统业务判断，如果可以领取空投，返回领取信息，并且携带签名
3. 客户端调用合约领取空投，合约验证，验证通过发放空投奖励
PS：注意gas消耗，双领以及私钥安全存储问题

Merkle树验证空投领取
位图存储领取状态，每个uint256可以存储256个用户状态，每一位Bit代表一个领取者状态
![img.png](docs/img.pngg.png)
1. 后台创建空投活动
2. 查询符合领取条件的用户
3. 生成Merkle树，存储到数据库或cdn
4. 前端通过地址查询对应的MerkleProof，调用合约领取空投
5. 客户端调用合约，验证签名MerkleProof，领取空投