# defi **(contracts)** 用 pnpm

```
1。 createMatch 不是用你调用。是lp 添加流动性的时候自己创建。
2。  首次自动create match pool,   IDlrLiquidity 中，addLiquidity 是添加流动性。
  function addLiquidity(
        address _tokenAddressIn1,  //   go接口1。 获取所有不同种类的代币 address
        address _tokenAddressIn2,  //   go 接口2。 根据 上面代币address  获取match pool 中对应的代币地址
        uint128 _amountIn1,            //    go接口3。 获取有没有match pool  首次lp, _amountIn1， amountIn2 ，可以随便输入，下面 的 _amountInMin1与 _amountInMin2 与_amountIn1， amountIn2的值一样
        uint128 _amountIn2,            //    go接口4。不是首次lp 根据 match pool 对应的比值 自动生成
        uint128 _amountInMin1,     //    go接口3。 获取有没有match pool  首次lp, _amountIn1， amountIn2 ，可以随便输入，下面 的 _amountInMin1与 _amountInMin2 与_amountIn1， amountIn2的值一样
        uint128 _amountInMin2      //    go接口4。不是首次lp 根据 match pool 对应的比值 自动生成
    ) external returns (uint liquidity);
3。  IDlrLiquidity 中，swapToken 是交换代币
 function swapToken(
        uint128 _amountIn,
        uint128 _amountOutMin,      //    go接口4。根据 match pool 对应的比值 自动生成
        address _tokenAddressIn,      //    go接口1。 获取所有不同种类的代币 address
        address _tokenAddressOut    //    go接口2。 根据 上面代币address  获取match pool 中对应的代币地址
    ) external returns (uint128 amountOut);
```

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
