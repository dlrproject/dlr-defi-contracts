// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
module.exports =
    buildModule(`TestMatchModule`, (m) => {
        const deployer = m.getAccount(0);
        const args = [

        ];
        const options = {
            from: deployer,
        };
        const testMatch = m.contract("TestMatch", args, options)
        return { testMatch }
    })





