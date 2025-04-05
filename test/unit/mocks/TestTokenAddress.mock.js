// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
const { ethers } = require("hardhat");
module.exports =
    buildModule(`TestTokenAddressModule`, (m) => {
        const deployer = m.getAccount(0);
        const args = [
            `TestTokenAddress`,
            `TTA`,
            ethers.parseEther("10000")
        ];
        const options = {
            from: deployer,
        };
        const tokenAddress = m.contract("TestTokenAddress", args, options)
        return { tokenAddress }
    })

    



