/*
deploy
*/
const { ethers, ignition, upgrades } = require("hardhat");
const DlrFactoryModule = require("../ignition/modules/dlr.factory");
async function main() {
    const [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();
    await ignition.deploy(DlrFactoryModule);
    let factory = await ethers.getContractFactory("DlrFactory");
    let proxyFactory = await upgrades.deployProxy(
        factory,
        [owner.address],
        { initializer: "initialize" }
    );
    await proxyFactory.createMatch("0xF44259a609c777381145b0FbFa257EaC5023ADf9", "0xadB0264dE38aC757D2f98fdB5f3cCAb9a43e178f");
    console.log("proxyAddress", proxyFactory.target);
}

main().then(() => {
    console.log("Script finished successfully");
    process.exit(0);
}).catch((error) => {
    console.error("Error in script:", error);
    process.exit(1);
});
