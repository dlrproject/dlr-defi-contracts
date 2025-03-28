# defi **(contracts)** 用 pnpm

### raffle 奖池

- (仓库) https://github.com/Raffleth

- (合约) https://github.com/Raffleth/protocol

- (前端) https://github.com/Raffleth/subgraph

- (官网) https://raffl.xyz/

### loan 借贷

- (仓库) https://github.com/compound-finance

- (合约) https://github.com/compound-finance/compound-protocol

- (前端) https://github.com/compound-finance/compound-js

- (官网) https://compound.finance/

### dex 交易所

## uniswap

- (仓库) https://github.com/Uniswap

- (合约) https://github.com/Uniswap/v2-core

- (前端) https://github.com/compound-finance/compound-js

- (官网) https://app.uniswap.org/

## raydium

- (仓库) https://github.com/raydium-io

- (官网) https://raydium.io/

```
### scripts

#### 编译

"compile": "hardhat compile",

#### 缓存

"clean": "hardhat clean",

#### 测试

"test": "hardhat test",

#### 部署

"deploy": "hardhat run scripts/deploy.js",

#### 单文件上

"ignition:stake": "hardhat ignition deploy ignition/modules/stake.js",

#### 测试

"ignition:token": "hardhat ignition deploy ignition/modules/rcc.js",

####

"coverage": "hardhat coverage",

#### 生成单文件

"flat": "hardhat flatten ./contracts/FLYStake.sol > ./cache/FLYStake_All.sol",

#### 验证

"verify": "hardhat ignition verify chain-11155111",

#### 获取部署的交易 HASH

"tx": "hardhat ignition transactions chain-11155111",

#### 获取部署 id

"id": "hardhat ignition deployments",

#### 本地 evm

"node": "hardhat node"
```
