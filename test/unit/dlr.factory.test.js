const { assert, expect } = require("chai");
const { ethers, network, ignition, upgrades } = require("hardhat");
const { developmentChains } = require("../../config");
const DlrFactoryModule = require("../../ignition/modules/dlr.factory");
const dlrFactory = require("../../ignition/modules/dlr.factory");
const { time } = require("console");
!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Dlr Dex Tests", function () {
        let owner, admin, user1, user2;
        let proxyDrlFactory;
        let tokenAddresssA = "0xadB0264dE38aC757D2f98fdB5f3cCAb9a43e178f";
        let tokenAddresssB = "0xF44259a609c777381145b0FbFa257EaC5023ADf9";
        beforeEach(async () => {
            [owner, admin, user1, user2, ...addrs] = await ethers.getSigners();
            await ignition.deploy(DlrFactoryModule);
            let factory = await ethers.getContractFactory("DlrFactory");
            proxyDrlFactory = await upgrades.deployProxy(
                factory,
                [owner.address],
                { initializer: "initialize" }
            );
        });

        describe("DlrFactory contract tests", function () {
            describe("DlrFactory can create match pool", function () {
                it("DlrFactory can't same token address ", async function () {
                    await expect(proxyDrlFactory.connect(admin).createMatch(
                        tokenAddresssA,
                        tokenAddresssA,
                    )).to.be.revertedWithCustomError(proxyDrlFactory, "DlrFactory_TokenAddressSame()");
                });
                it("DlrFactory can't be zero address ", async function () {
                    await expect(proxyDrlFactory.connect(admin).createMatch(
                        tokenAddresssA,
                        "0x0000000000000000000000000000000000000000",
                    )).to.be.revertedWithCustomError(proxyDrlFactory, "DlrFactory_TokenAddressZero()");
                });
                it("DlrFactory can't be exists address ", async function () {
                    await proxyDrlFactory.connect(admin).createMatch(
                        tokenAddresssA,
                        tokenAddresssB,
                    );
                    await expect(proxyDrlFactory.connect(admin).createMatch(
                        tokenAddresssA,
                        tokenAddresssB,
                    )).to.be.revertedWithCustomError(proxyDrlFactory, "DlrFactory_MatchAlreadyExists()");
                });
                it("DlrFactory call create match can emit created event", async function () {
                    const tx = await proxyDrlFactory.connect(admin).createMatch(
                        tokenAddresssA,
                        tokenAddresssB,
                    );
                    await expect(tx)
                        .to.emit(proxyDrlFactory, "DrlMatchCreated");
                });
                it("DlrFactory call create match has reture adddress", async function () {
                    const returnData = await ethers.provider.call({
                        to: proxyDrlFactory.target,
                        data: proxyDrlFactory.interface.encodeFunctionData("createMatch", [
                            tokenAddresssA,
                            tokenAddresssB,
                        ]),
                    });
                    const decoded = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["address"],
                        returnData
                    );
                    assert.exists(decoded[0], "Returned address should exist");
                });
                it("DlrFactory call create match builded contract can call ", async function () {
                    const tx = await proxyDrlFactory.createMatch(tokenAddresssA, tokenAddresssB);
                    const receipt = await tx.wait();
                    const eventFragment = proxyDrlFactory.interface.getEvent("DrlMatchCreated");
                    const event = receipt.logs.find(log =>
                        log.topics[0] === eventFragment.topicHash
                    );
                    assert.exists(event, "DrlMatchCreated event should be emitted");
                    const decodedEvent = proxyDrlFactory.interface.decodeEventLog(
                        eventFragment,
                        event.data,
                        event.topics
                    );
                    const matchAddress = decodedEvent._mapAddress;
                    assert.notEqual(matchAddress, ethers.ZeroAddress, "Invalid contract address");
                    const code = await ethers.provider.getCode(matchAddress);
                    assert.notEqual(code, "0x", "Contract code should be deployed");
                });
            });
        })


        describe("DlrMatch functions can call", function () {
            let matchAddress;
            beforeEach(async () => {
                const tx = await proxyDrlFactory.createMatch(tokenAddresssA, tokenAddresssB);
                const receipt = await tx.wait();
                const eventFragment = proxyDrlFactory.interface.getEvent("DrlMatchCreated");
                const event = receipt.logs.find(log =>
                    log.topics[0] === eventFragment.topicHash
                );
                const decodedEvent = proxyDrlFactory.interface.decodeEventLog(
                    eventFragment,
                    event.data,
                    event.topics
                );
                matchAddress = decodedEvent._mapAddress;
            });
            it("DlrMatch is inintialized", async function () {
                const matchContract = await ethers.getContractAt("DlrMatch", matchAddress);
                assert.equal(
                    await matchContract.tokenAddressA(),
                    tokenAddresssA,
                    "TokenA should be initialized"
                );
                assert.equal(
                    await matchContract.tokenAddressB(),
                    tokenAddresssB,
                    "TokenB should be initialized"
                );
            });
            it("DlrMatch mint can emit event", async function () {
                const matchContract = await ethers.getContractAt("DlrMatch", matchAddress);
                const mintTx = await matchContract.mint(tokenAddresssA);
                await expect(mintTx)
                    .to.emit(matchContract, "DlrMatchMint")
            });
            it("DlrMatch ownner is factory", async function () {
                const matchContract = await ethers.getContractAt("DlrMatch", matchAddress);
                const matchOwner = await matchContract.owner();
                expect(matchOwner).to.equal(proxyDrlFactory.target, "Match owner should be the factory address");
            });
        });
    });
