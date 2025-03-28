/*
deploy
*/
const { ethers, ignition, upgrades } = require("hardhat");
const DlrFactoryModule = require("../ignition/modules/dlr.factory");
async function main() {
    const [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();

    let factoryModule = await ignition.deploy(DlrFactoryModule);
    let factory = await ethers.getContractFactory("DlrFactory");
    let proxyFactory = await upgrades.deployProxy(
        factory,
        [owner.address],
        { initializer: "initialize" }
    );


    await proxyFactory.createMatch("0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0", "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0");

    console.log("proxyAddress", proxyFactory.target);
}

main().then(() => {
    console.log("Script finished successfully");
    process.exit(0);
}).catch((error) => {
    console.error("Error in script:", error);
    process.exit(1);
});
