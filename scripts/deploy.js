/*deploy*/
const { ethers, ignition, upgrades } = require("hardhat");
const DlrFactoryModule = require("../ignition/modules/dlr.factory");
const DlrLiquidityModule = require("../ignition/modules/dlr.liquidity");
async function main() {
    const [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();
    await ignition.deploy(DlrFactoryModule);
    let factoryContractFactory = await ethers.getContractFactory("DlrFactory");
    let proxyDrlFactoryContract = await upgrades.deployProxy(
        factoryContractFactory,
        [owner.address],
        { initializer: "initialize" }
    );
    console.log("proxyDrlFactoryContract", proxyDrlFactoryContract.target);

    await ignition.deploy(DlrLiquidityModule);
    let liquidityContractFactory = await ethers.getContractFactory("DlrLiquidity");
    let proxyDrlLiquidityContract = await upgrades.deployProxy(
        liquidityContractFactory,
        [owner.address, proxyDrlFactoryContract.target],
        { initializer: "initialize" }
    );
    console.log("proxyDrlLiquidityContract", proxyDrlLiquidityContract.target);
}

main().then(() => {
    console.log("Script finished successfully");
    process.exit(0);
}).catch((error) => {
    console.error("Error in script:", error);
    process.exit(1);
});
