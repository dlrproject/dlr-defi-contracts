/*deploy*/
const { ethers, ignition, upgrades } = require("hardhat");

const TestTokenAddressModule = require("./mocks/TestTokenAddress.mock");
const TestMatchModule = require("./mocks/TestMatch.mock");
async function main() {
    const [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();


    const TestTokenAddressModuleA = await ignition.deploy(TestTokenAddressModule)
    const TestTokenAddressModuleB = await ignition.deploy(TestTokenAddressModule)
    console.log("TestTokenAddressModuleA", TestTokenAddressModuleA.tokenAddress.target);
    console.log("TestTokenAddressModuleB", TestTokenAddressModuleB.tokenAddress.target);


    const MatchModule = await ignition.deploy(TestMatchModule)
    console.log("TestMatchModule", MatchModule.testMatch.target);







}

main().then(() => {
    console.log("Script finished successfully");
    process.exit(0);
}).catch((error) => {
    console.error("Error in script:", error);
    process.exit(1);
});
