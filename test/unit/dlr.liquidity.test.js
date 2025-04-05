const { assert, expect } = require("chai");
const { ethers, network, ignition, upgrades } = require("hardhat");
const { developmentChains } = require("../../config");
const DlrFactoryModule = require("../../ignition/modules/dlr.factory");
const DlrLiquidityModule = require("../../ignition/modules/dlr.liquidity");
const TestTokenAddressModule = require("./mocks/TestTokenAddress.mock");
const TestMatchModule = require("./mocks/TestMatch.mock");
const { ZeroAddress } = require("ethers");
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Dlr Dex Liquidity Tests", function () {
        let owner, admin, user1, user2;
        let proxyDrlLiquidityContract;
        let proxyDrlFactoryContract;
        let tokenAddressA;
        let tokenAddressB;
        let TestTokenAddressContractA;
        let TestTokenAddressContractB;
        let matchAddress;
        let matchContract;
        beforeEach(async () => {

            [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();

            /*
            TestTokenAddress 
            */
            const TestTokenAddressModule1 = await ignition.deploy(TestTokenAddressModule)
            const TestTokenAddressModule2 = await ignition.deploy(TestTokenAddressModule)
            const tokenAddress1 = TestTokenAddressModule1.tokenAddress.target;
            const tokenAddress2 = TestTokenAddressModule2.tokenAddress.target;


            /*
            DlrFactory 
             */
            await ignition.deploy(DlrFactoryModule);
            let factoryContractFactory = await ethers.getContractFactory("DlrFactory");
            proxyDrlFactoryContract = await upgrades.deployProxy(
                factoryContractFactory,
                [owner.address],
                { initializer: "initialize" }
            );
            const tx = await proxyDrlFactoryContract.createMatch(tokenAddress1, tokenAddress2);
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



            /*
            DlrMatch
            */

            matchAddress = decodedEvent._matchAddress;
            matchContract = await ethers.getContractAt("DlrMatch", matchAddress);

            /*
            TestTokenAddress 
            */
            if (await matchContract.tokenAddressA() == tokenAddress1) {
                tokenAddressA = tokenAddress1;
                tokenAddressB = tokenAddress2;
            } else {
                tokenAddressA = tokenAddress2;
                tokenAddressB = tokenAddress1;
            }
            TestTokenAddressContractA = await ethers.getContractAt("TestTokenAddress", tokenAddressA);
            TestTokenAddressContractB = await ethers.getContractAt("TestTokenAddress", tokenAddressB);



            /*
            DlrLiquidity  
            */

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
                    await TestTokenAddressContractA.connect(owner).transfer(admin, ethers.parseEther("2"));
                    await TestTokenAddressContractB.connect(owner).transfer(admin, ethers.parseEther("200"));
                    await TestTokenAddressContractA.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("2"));
                    await TestTokenAddressContractB.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("200"));
                    assert.equal(await TestTokenAddressContractA.connect(admin).balanceOf(admin), ethers.parseEther("2"))
                    assert.equal(await TestTokenAddressContractB.connect(admin).balanceOf(admin), ethers.parseEther("200"))
                })

                it("DlrLiquidity lp liquidity amount in can't be zero", async function () {
                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, 0, 0, 0, 0)).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_AmountInZero");

                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("100"));

                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, 0, ethers.parseEther("100"), 0, ethers.parseEther("100"))).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_AmountInZero");

                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, ethers.parseEther("1"), 0, ethers.parseEther("1"), 0)).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_AmountInZero");
                });
                it("DlrLiquidity lp liquidity real amount can't less desired", async function () {
                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("100"));
                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("2"), ethers.parseEther("100"))).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_RealAmountLessDesired");
                    await expect(proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("200"))).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_RealAmountLessDesired");
                });
                it("DlrLiquidity lp liquidity can transfer and update match pool reserve", async function () {
                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("100"));
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
                            tokenAddressA,
                            tokenAddressB,
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
                    assert(liquidity, await matchContract.balanceOf(admin))
                });
                it("DlrLiquidity lp add liquidity update match pool totalSupply", async function () {
                    const returnData = await ethers.provider.call({
                        from: admin,
                        to: proxyDrlLiquidityContract.target,
                        data: proxyDrlLiquidityContract.interface.encodeFunctionData("addLiquidity", [
                            tokenAddressA,
                            tokenAddressB,
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
                            tokenAddressA,
                            tokenAddressB,
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
                    assert(liquidity + liquidity2, await matchContract.balanceOf(admin))
                    assert(liquidity + liquidity2, await matchContract.totalSupply())
                });
                it("DlrLiquidity lp add liquidity emit event investment ", async function () {
                    let tx = await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB, ethers.parseEther("1"), ethers.parseEther("100"), ethers.parseEther("1"), ethers.parseEther("100"));
                    await expect(tx)
                        .to.emit(proxyDrlLiquidityContract, "DlrLiquidityInvestment")
                });
            });


            describe("swapToken:        DlrLiquidity swap token from match pool", function () {
                beforeEach(async () => {
                    await TestTokenAddressContractA.connect(owner).transfer(admin, ethers.parseEther("20"));
                    await TestTokenAddressContractB.connect(owner).transfer(admin, ethers.parseEther("2000"));
                    await TestTokenAddressContractA.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("20"));
                    await TestTokenAddressContractB.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("2000"));
                    assert.equal(await TestTokenAddressContractA.connect(admin).balanceOf(admin), ethers.parseEther("20"))
                    assert.equal(await TestTokenAddressContractB.connect(admin).balanceOf(admin), ethers.parseEther("2000"))
                    assert.equal(await TestTokenAddressContractA.connect(admin).allowance(admin, proxyDrlLiquidityContract.target), ethers.parseEther("20"))
                    assert.equal(await TestTokenAddressContractB.connect(admin).allowance(admin, proxyDrlLiquidityContract.target), ethers.parseEther("2000"))

                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB,
                        ethers.parseEther("1"),
                        ethers.parseEther("100"),
                        ethers.parseEther("1"),
                        ethers.parseEther("100"));

                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB,
                        ethers.parseEther("1"),
                        ethers.parseEther("100"),
                        ethers.parseEther("1"),
                        ethers.parseEther("100"));

                })
                it("DlrLiquidity amount in cat't be zero", async function () {
                    await expect(proxyDrlLiquidityContract.connect(admin).swapToken(
                        ethers.parseEther("0"),
                        ethers.parseEther("100"),
                        tokenAddressA,
                        tokenAddressB)).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_AmountInZero");
                });

                it("DlrLiquidity token address in and token address out cat't be zero", async function () {
                    await expect(proxyDrlLiquidityContract.connect(admin).swapToken(
                        ethers.parseEther("1"),
                        ethers.parseEther("100"),
                        ZeroAddress,
                        tokenAddressB)).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "Dlr_AddressZero");

                    await expect(proxyDrlLiquidityContract.connect(admin).swapToken(
                        ethers.parseEther("1"),
                        ethers.parseEther("100"),
                        tokenAddressA,
                        ZeroAddress)).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "Dlr_AddressZero");
                });


                it("DlrLiquidity swap amout out can't greater then match pool percent", async function () {
                    const matchContractReserveA = await matchContract.reserveA();
                    const matchContractReserveB = await matchContract.reserveB();
                    assert.notEqual(matchContractReserveA, ethers.parseEther("0"), "Match pool reserveA should be initialized")
                    assert.notEqual(matchContractReserveB, ethers.parseEther("0"), "Match pool reserveB should be initialized")
                    await expect(proxyDrlLiquidityContract.connect(admin).swapToken(
                        ethers.parseEther("1"),
                        ethers.parseEther("101"),
                        tokenAddressA,
                        tokenAddressB)).to.be.revertedWithCustomError(proxyDrlLiquidityContract, "DlrLiquidity_DesireAmountOutChanged");
                });

                it("DlrLiquidity match pool add one reserve add another resever reduce", async function () {
                    const tx = await proxyDrlLiquidityContract.connect(admin).swapToken(
                        ethers.parseEther("1"),
                        ethers.parseEther("40"),
                        tokenAddressA,
                        tokenAddressB);
                    const receipt = await tx.wait();
                    let a = await matchContract.reserveA();
                    assert.equal(
                        a,
                        ethers.parseEther("3")
                    );
                });
                it("DlrLiquidity lp remove liquidity emit event swap toke", async function () {
                    const tx = await proxyDrlLiquidityContract.connect(admin).swapToken(
                        ethers.parseEther("1"),
                        ethers.parseEther("40"),
                        tokenAddressA,
                        tokenAddressB);
                    await expect(tx)
                        .to.emit(proxyDrlLiquidityContract, "DlrLiquiditySwapToken")

                });
            });

            describe("removeLiquidity:  DlrLiquidity remove liquidity", function () {

                beforeEach(async () => {
                    await TestTokenAddressContractA.connect(owner).transfer(admin, ethers.parseEther("20"));  //admin  a 20
                    await TestTokenAddressContractB.connect(owner).transfer(admin, ethers.parseEther("2000"));//admin  b 2000

                    //操作liquid 所有 admin
                    await TestTokenAddressContractA.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("20"));
                    await TestTokenAddressContractB.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("2000"));

                    assert.equal(await TestTokenAddressContractA.connect(admin).balanceOf(admin), ethers.parseEther("20"))
                    assert.equal(await TestTokenAddressContractB.connect(admin).balanceOf(admin), ethers.parseEther("2000"))
                    assert.equal(await TestTokenAddressContractA.connect(admin).allowance(admin, proxyDrlLiquidityContract.target), ethers.parseEther("20"))
                    assert.equal(await TestTokenAddressContractB.connect(admin).allowance(admin, proxyDrlLiquidityContract.target), ethers.parseEther("2000"))


                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB,
                        ethers.parseEther("1"),
                        ethers.parseEther("100"),
                        ethers.parseEther("1"),
                        ethers.parseEther("100"));

                    await proxyDrlLiquidityContract.connect(admin).addLiquidity(tokenAddressA, tokenAddressB,
                        ethers.parseEther("1"),
                        ethers.parseEther("100"),
                        ethers.parseEther("1"),
                        ethers.parseEther("100"));

                    assert.equal(ethers.parseEther("2"), await matchContract.reserveA())
                    assert.equal(ethers.parseEther("200"), await matchContract.reserveB())
                    const totalSupply = await matchContract.totalSupply();
                    const adminBalance = await matchContract.balanceOf(admin);
                    assert.equal(totalSupply, ethers.parseEther("20"));
                    assert.equal(totalSupply, adminBalance);
                })
                it("DlrLiquidity remove liquidity", async function () {
                    await matchContract.connect(admin).approve(matchAddress, ethers.parseEther("20"));
                    await matchContract.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("20"));
                    const allowance = await matchContract.allowance(admin, proxyDrlLiquidityContract.target);
                    assert.equal(allowance, ethers.parseEther("20"));
                    assert.equal(await matchContract.connect(admin).allowance(admin, matchAddress), ethers.parseEther("20"));

                    await proxyDrlLiquidityContract.connect(admin).removeLiquidity(
                        tokenAddressA,
                        tokenAddressB,
                        ethers.parseEther("10"),
                        ethers.parseEther("1"),
                        ethers.parseEther("100"));
                });

                it("DlrLiquidity remove  emit event profit", async function () {
                    await matchContract.connect(admin).approve(matchAddress, ethers.parseEther("20"));
                    await matchContract.connect(admin).approve(proxyDrlLiquidityContract.target, ethers.parseEther("20"));

                    const tx = await proxyDrlLiquidityContract.connect(admin).removeLiquidity(
                        tokenAddressA,
                        tokenAddressB,
                        ethers.parseEther("10"),
                        ethers.parseEther("1"),
                        ethers.parseEther("100"));
                    await expect(tx)
                        .to.emit(proxyDrlLiquidityContract, "DlrLiquidityProfit")
                });
            });
        });
    });


/* 
it("DlrLiquidity swap match pool reserve in can't be zero", async function () {

    const newTokenAddressModuleA = await ignition.deploy(TestTokenAddressModule)
    const newTokenAddressModuleB = await ignition.deploy(TestTokenAddressModule)

    const newTokenAddressA = newTokenAddressModuleA.tokenAddress.target;
    const newTokenAddressB = newTokenAddressModuleB.tokenAddress.target;

    const returnData = await ethers.provider.call({
        to: proxyDrlFactoryContract.target,
        data: proxyDrlFactoryContract.interface.encodeFunctionData("createMatch", [
            newTokenAddressA,
            newTokenAddressB,
        ]),
    });
    const decoded = ethers.AbiCoder.defaultAbiCoder().decode(
        ["address"],
        returnData
    );    
});
*/