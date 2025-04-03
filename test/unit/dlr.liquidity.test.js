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
            describe("addLiquidity:     DlrLiquidity add Liquidity to match pool", function () {
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
                it("DlrLiquidity lp liquidity amount in can't be zero", async function () {
                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddresssA, tokenAddresssB, 0, 0, 0, 0)).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_AmountInZero");

                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddresssA, tokenAddresssB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("100"));

                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddresssA, tokenAddresssB, 0, ethers.parseEther("100"), 0, ethers.parseEther("100"))).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_AmountInZero");

                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddresssA, tokenAddresssB, ethers.parseEther("1"), 0, ethers.parseEther("1"), 0)).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_AmountInZero");
                });
                it("DlrLiquidity lp liquidity real amount can't less desired", async function () {
                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddresssA, tokenAddresssB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("100"));
                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddresssA, tokenAddresssB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("2"), ethers.parseEther("100"))).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_RealAmountLessDesired");
                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddresssA, tokenAddresssB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("200"))).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_RealAmountLessDesired");
                });
                it("DlrLiquidity lp liquidity can transfer and update match pool reserve", async function () {
                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddresssA, tokenAddresssB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("100"));
                    const matchContract = await ethers.getContractAt("DlrMatch", matchAddress);
                    assert.equal(
                        await matchContract.reserveA(),
                        ethers.parseEther("1"),
                        "TokenA should be initialized"
                    );
                    assert.equal(
                        await matchContract.reserveB(),
                        ethers.parseEther("100"),
                        "TokenB should be initialized"
                    );

                    assert.equal(
                        await matchContract.getPriceA(),
                        100 * 1000,
                        "TokenA should be initialized"
                    );
                    assert.equal(
                        await matchContract.getPriceB(),
                        0.01 * 1000,
                        "TokenA should be initialized"
                    );
                });

                it("DlrLiquidity lp add liquidity can mint lp token amount", async function () {
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
                        ["uint"],
                        returnData
                    );
                    assert(liquidity, ethers.parseEther("10"))
                    const matchContract = await ethers.getContractAt("DlrMatch", matchAddress);
                    assert(liquidity, await matchContract.balanceOf(admin))
                });

                it("DlrLiquidity lp add liquidity update match pool totalSupply", async function () {
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
                        ["uint"],
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
                        ["uint"],
                        returnData2
                    );
                    assert(liquidity2, ethers.parseEther("10"))
                    const matchContract = await ethers.getContractAt("DlrMatch", matchAddress);
                    assert(liquidity + liquidity2, await matchContract.balanceOf(admin))
                    assert(liquidity + liquidity2, await matchContract.totalSupply())
                });
            });
            describe("swapToken:        DlrLiquidity swap token from match pool", function () {
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
                        ["uint"],
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
                        ["uint"],
                        returnData2
                    );
                })
                it("DlrLiquidity lp liquidity amount in can't be zero", async function () {

                });
            });
        });
    });





