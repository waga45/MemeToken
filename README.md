## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

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
```

MemeToken 代币 接入Uniswap 添加流动性
[ 你的钱包 ]
   │
   ▼
approve() → 授权 Uniswap Router 使用你的 Token
   │
   ▼
addLiquidityETH() → 把 Token + ETH 一起存入流动性池
   │
   ▼
✅ Uniswap 自动创建一个新交易对 (Token/WETH)
   │
   ▼
你获得 LP Token（流动性凭证）
