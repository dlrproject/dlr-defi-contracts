const { assert, expect } = require("chai");
const { ethers, network, ignition, upgrades } = require("hardhat");
const { developmentChains } = require("../../config");
const DlrFactoryModule = require("../../ignition/modules/dlr.factory");
const DlrLiquidityModule = require("../../ignition/modules/dlr.liquidity");
const TestTokenAddressModule = require("../../scripts/mocks/TestTokenAddress.mock");
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Dlr Dex Liquidity Tests", function () {
        let owner, admin, user1, user2;
        let proxyDrlLiquidityContract;
        let proxyDrlFactoryContract;
        let tokenAddresssA;
        let tokenAddresssB;
        let adddressZero = "0x0000000000000000000000000000000000000000"
        let matchAddress;
        beforeEach(async () => {
            [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();
            await ignition.deploy(DlrFactoryModule);

            const TestTokenAddressModuleA = await ignition.deploy(TestTokenAddressModule)
            const TestTokenAddressModuleB = await ignition.deploy(TestTokenAddressModule)
            tokenAddresssA = TestTokenAddressModuleA.tokenAddress.target;
            tokenAddresssB = TestTokenAddressModuleB.tokenAddress.target;
            let factoryContractFactory = await ethers.getContractFactory("DlrFactory");
            proxyDrlFactoryContract = await upgrades.deployProxy(
                factoryContractFactory,
                [owner.address],
                { initializer: "initialize" }
            );
            const tx = await proxyDrlFactoryContract.createMatch(tokenAddresssA, tokenAddresssB);
            const receipt = await tx.wait();
            const eventFragment = proxyDrlFactoryContract.interface.getEvent("DrlMatchCreated");
            const event = receipt.logs.find(log =>
                log.topics[0] === eventFragment.topicHash
            );
            const decodedEvent = proxyDrlFactoryContract.interface.decodeEventLog(
                eventFragment,
                event.data,
                event.topics
            );
            matchAddress = decodedEvent._matchAddress;

            await ignition.deploy(DlrLiquidityModule);
            let liquidityContractFactory = await ethers.getContractFactory("DlrLiquidity");
            proxyDrlLiquidityContract = await upgrades.deployProxy(
                liquidityContractFactory,
                [owner.address, proxyDrlFactoryContract.target],
                { initializer: "initialize" }
            );

        });
        describe("DlrLiquidity contract tests", function () {
            describe("initialize:       DlrLiquidity use initialize for constructor", function () {
                it("DlrLiquidity set initialize", async function () {
                    await expect(proxyDrlLiquidityContract.connect(owner).initialize(owner.address, proxyDrlFactoryContract.target))
                        .to.be.revertedWithCustomError(proxyDrlLiquidityContract, "InvalidInitialization");
                });
            });

            describe("addLiquidity:     DlrLiquidity add Liquidity", function () {
                beforeEach(async () => {
                    const TestTokenAddressContractA = await ethers.getContractAt("TestTokenAddress", tokenAddresssA);
                    await TestTokenAddressContractA.connect(owner).transfer(admin, ethers.parseEther("2"));
                    const TestTokenAddressContractB = await ethers.getContractAt("TestTokenAddress", tokenAddresssB);
                    await TestTokenAddressContractB.connect(owner).transfer(admin, ethers.parseEther("200"));
                    await TestTokenAddressContractA.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("2"));
                    await TestTokenAddressContractB.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("200"));
                    assert.equal(await TestTokenAddressContractA.connect(admin).balanceOf(admin), ethers.parseEther("2"))
                    assert.equal(await TestTokenAddressContractB.connect(admin).balanceOf(admin), ethers.parseEther("200"))
                })
                it("DlrLiquidity lp add pool liquidity again", async function () {
                    const returnData = await ethers.provider.call({
                        from: admin,
                        to: proxyDrlLiquidityContract.target,
                        data: proxyDrlLiquidityContract.interface.encodeFunctionData("addLiquidity", [
                            tokenAddresssA,
                            tokenAddresssB,
                            ethers.parseEther("1"),
                            ethers.parseEther("100"),
                            ethers.parseEther("1"),
                            ethers.parseEther("100")
                        ]),
                    });
                    const [liquidity] = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["address"],
                        returnData
                    );
                    assert(liquidity, ethers.parseEther("10"))
                    const returnData2 = await ethers.provider.call({
                        from: admin,
                        to: proxyDrlLiquidityContract.target,
                        data: proxyDrlLiquidityContract.interface.encodeFunctionData("addLiquidity", [
                            tokenAddresssA,
                            tokenAddresssB,
                            ethers.parseEther("1"),
                            ethers.parseEther("100"),
                            ethers.parseEther("1"),
                            ethers.parseEther("100")
                        ]),
                    });
                    const [liquidity2] = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["address"],
                        returnData2
                    );
                    assert(liquidity2, ethers.parseEther("10"))
                });
                it("DlrLiquidity lp first add pool liquidity", async function () {
                    const returnData = await ethers.provider.call({
                        from: admin,
                        to: proxyDrlLiquidityContract.target,
                        data: proxyDrlLiquidityContract.interface.encodeFunctionData("addLiquidity", [
                            tokenAddresssA,
                            tokenAddresssB,
                            ethers.parseEther("1"),
                            ethers.parseEther("100"),
                            ethers.parseEther("1"),
                            ethers.parseEther("100")
                        ]),
                    });
                    const [liquidity] = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["address"],
                        returnData
                    );
                    assert(liquidity, ethers.parseEther("10"))
                });
                it("DlrLiquidity lp add pool liquidity again", async function () {

                });
            });
            describe("swapToken:        DlrLiquidity swap token", function () {
                let liquidity;
                beforeEach(async () => {
                    const TestTokenAddressContractA = await ethers.getContractAt("TestTokenAddress", tokenAddresssA);
                    await TestTokenAddressContractA.connect(owner).transfer(admin, ethers.parseEther("2"));
                    const TestTokenAddressContractB = await ethers.getContractAt("TestTokenAddress", tokenAddresssB);
                    await TestTokenAddressContractB.connect(owner).transfer(admin, ethers.parseEther("200"));

                    await TestTokenAddressContractA.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("2"));
                    await TestTokenAddressContractB.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("200"));

                    assert.equal(await TestTokenAddressContractA.connect(admin).balanceOf(admin), ethers.parseEther("2"))
                    assert.equal(await TestTokenAddressContractB.connect(admin).balanceOf(admin), ethers.parseEther("200"))

                    const returnData = await ethers.provider.call({
                        from: admin,
                        to: proxyDrlLiquidityContract.target,
                        data: proxyDrlLiquidityContract.interface.encodeFunctionData("addLiquidity", [
                            tokenAddresssA,
                            tokenAddresssB,
                            ethers.parseEther("1"),
                            ethers.parseEther("100"),
                            ethers.parseEther("1"),
                            ethers.parseEther("100")
                        ]),
                    });
                    [liquidity] = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["address"],
                        returnData
                    );
                    const returnData2 = await ethers.provider.call({
                        from: admin,
                        to: proxyDrlLiquidityContract.target,
                        data: proxyDrlLiquidityContract.interface.encodeFunctionData("addLiquidity", [
                            tokenAddresssA,
                            tokenAddresssB,
                            ethers.parseEther("1"),
                            ethers.parseEther("100"),
                            ethers.parseEther("1"),
                            ethers.parseEther("100")
                        ]),
                    });
                    [liquidity] = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["address"],
                        returnData2
                    );
                })
            });
        });
    });


