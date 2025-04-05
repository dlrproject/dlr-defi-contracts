/*deploy*/
const { ethers, network, ignition, upgrades } = require("hardhat");
const DlrFactoryModule = require("../ignition/modules/dlr.factory");
const DlrLiquidityModule = require("../ignition/modules/dlr.liquidity");
async function main() {
    const [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();
    const FactoryModule = await ignition.deploy(DlrFactoryModule);
    let factoryContractFactory = await ethers.getContractFactory("DlrFactory");
    let proxyDrlFactoryContract = await upgrades.deployProxy(
        factoryContractFactory,
        [owner.address],
        { initializer: "initialize" }
    );

    console.log("Deployed  ImplementationAddress", FactoryModule.factory.target);
    console.log("proxyDrlFactoryContract", proxyDrlFactoryContract.target);

    // const LiquidityModule = await ignition.deploy(DlrLiquidityModule);
    // let liquidityContractFactory = await ethers.getContractFactory("DlrLiquidity");
    // let proxyDrlLiquidityContract = await upgrades.deployProxy(
    //     liquidityContractFactory,
    //     [owner.address, proxyDrlFactoryContract.target],
    //     { initializer: "initialize" }
    // );

    // console.log(" ", LiquidityModule.liquidity.target);
    // console.log("proxyDrlLiquidityContract", proxyDrlLiquidityContract.target);
    let b = await upgrades.erc1967.getImplementationAddress(proxyDrlFactoryContract.target);
    console.log("Deployed  ImplementationAddress", b.target);
}

main().then(() => {
    console.log(`✅ Deployment completed successfully!`);
    process.exit(0);
}).catch((error) => {
    console.error("Deployment Error in script:", error);
    process.exit(1);
});
