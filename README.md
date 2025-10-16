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

