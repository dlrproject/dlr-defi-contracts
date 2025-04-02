// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");


module.exports = buildModule("DlrLiquidityModule", (m) => {
    const deployer = m.getAccount(0);
    const args = [];
    const options = {
        from: deployer,
    };
    const liquidity = m.contract("DlrLiquidity", args, options)
    return { liquidity };
});
