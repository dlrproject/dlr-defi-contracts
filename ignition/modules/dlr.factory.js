// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");


module.exports = buildModule("DlrFactoryModule", (m) => {
  const deployer = m.getAccount(0);
  const args = [];
  const options = {
    from: deployer,
  };
  const factory = m.contract("DlrFactory", args, options)
  return { factory };
});
