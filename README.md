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
scripts
"compile": "hardhat compile",
"clean": "hardhat clean",
"test": "hardhat test",
"deploy": "hardhat run scripts/deploy.js",
"ignition:factory": "hardhat ignition deploy ignition/modules/dlr.factory.js",
"coverage": "hardhat coverage",
"flat": "hardhat flatten ./contracts/DlrFactory.sol > ./cache/DlrFactory.flat.sol",
"verify": "hardhat ignition verify chain-11155111",
"tx": "hardhat ignition transactions chain-11155111",
"id": "hardhat ignition deployments",
"node": "hardhat node"
```
