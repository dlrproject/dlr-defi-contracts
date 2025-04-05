const { network, upgrades } = require("hardhat")
const { developmentChains } = require("../config")
const { verify } = require("../utils/verify")
require("dotenv").config()
const fs = require("fs")
module.exports = async ({ getNamedAccounts, deployments }) => {
    const { log } = deployments
    const [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();
    let factoryContractFactory = await ethers.getContractFactory("DlrFactory");
    let proxyFactoryContract = await upgrades.deployProxy(
        factoryContractFactory,
        [owner.address],
        { initializer: "initialize" }
    );
    const factoryProxyAddress = proxyFactoryContract.target;
    const factoryImplementationAddress = await upgrades.erc1967.getImplementationAddress(factoryProxyAddress)

    // log(`DlrFactory Implementation deployed at      ${factoryImplementationAddress}`)
    // log(`DlrFactory Proxy deployed at               ${factoryProxyAddress}`)
    // if (
    //     !developmentChains.includes(network.name) &&
    //     process.env.ETHERSCAN_API_KEY
    // ) {
    //     await verify(factoryProxyAddress, [])
    // }

    let liquidityContractFactory = await ethers.getContractFactory("DlrLiquidity");
    let proxyDrlLiquidityContract = await upgrades.deployProxy(
        liquidityContractFactory,
        [owner.address, factoryProxyAddress],
        { initializer: "initialize" }
    );
    const liquidityProxyAddress = proxyDrlLiquidityContract.target;
    // const liquidityImplementationAddress = await upgrades.erc1967.getImplementationAddress(liquidityProxyAddress)
    // log(`DlrLiquidity Implementation deployed at      ${liquidityImplementationAddress}`)
    // log(`DlrLiquidity Proxy deployed at               ${liquidityProxyAddress}`)

    // if (
    //     !developmentChains.includes(network.name) &&
    //     process.env.ETHERSCAN_API_KEY
    // ) {
    //     await verify(liquidityProxyAddress, [])
    // }
}
module.exports.tags = ["all", "dex"]