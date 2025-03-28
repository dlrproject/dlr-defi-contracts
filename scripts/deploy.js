/*
deploy
*/
const { ethers, ignition, upgrades } = require("hardhat")
const RccTokenModule = require("../ignition/modules/rcc");
const RCCStakeModule = require("../ignition/modules/stake");
async function main() {
    let tokenModule = await ignition.deploy(RccTokenModule);
    let stakeModule = await ignition.deploy(RCCStakeModule);
    console.log("tokenModule", tokenModule.token.target);
    console.log("stakeModule", stakeModule.stake.target);
    let stakeFactory = await ethers.getContractFactory("RCCStake");
    let proxyFactory = await upgrades.deployProxy(
        stakeFactory,
        [tokenModule.token.target, 100, 100, 100],
        { initializer: "initialize" }
    );
    console.log("proxyAddress", proxyFactory.target);
}
