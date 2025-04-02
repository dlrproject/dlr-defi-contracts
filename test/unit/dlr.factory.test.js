const { assert, expect } = require("chai");
const { ethers, network, ignition, upgrades } = require("hardhat");
const { developmentChains } = require("../../config");
const DlrFactoryModule = require("../../ignition/modules/dlr.factory");

const TestTokenAddressModule = require("../../scripts/mocks/TestTokenAddress.mock");
const TestMatchModule = require("../../scripts/mocks/TestMatch.mock");

const dlrFactory = require("../../ignition/modules/dlr.factory");

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Dlr Dex Factory Tests", function () {
        let owner, admin, user1, user2;
        let proxyDrlFactoryContract;
        let tokenAddresssA;
        let tokenAddresssB;
        let adddressZero = "0x0000000000000000000000000000000000000000"
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

        });

        describe("DlrFactory contract tests", function () {
            describe("initialize:       DlrFactory use initialize for constructor", function () {
                it("DlrFactory set initialize", async function () {
                    await expect(proxyDrlFactoryContract.connect(owner).initialize(owner.address))
                        .to.be.revertedWithCustomError(proxyDrlFactoryContract, "InvalidInitialization");
                });
            });
            describe("pause:            DlrFactory can toggle pause contracts", function () {
                it("DlrFactory pasue only unpased", async function () {
                    await expect(proxyDrlFactoryContract.connect(owner).unpause())
                        .to.be.revertedWithCustomError(proxyDrlFactoryContract, "ExpectedPause");
                });
                it("DlrFactory unpased only pasue", async function () {
                    let tx = await proxyDrlFactoryContract.connect(owner).pause();
                    await expect(proxyDrlFactoryContract.connect(owner).pause())
                        .to.be.revertedWithCustomError(proxyDrlFactoryContract, "EnforcedPause");
                });
                it("DlrFactory only ownner can pasue", async function () {
                    await expect(proxyDrlFactoryContract.connect(admin).pause())
                        .to.be.revertedWithCustomError(proxyDrlFactoryContract, "OwnableUnauthorizedAccount");
                });
                it("DlrFactory pasue can emit event", async function () {
                    let tx = await proxyDrlFactoryContract.connect(owner).pause();
                    await expect(tx)
                        .to.emit(proxyDrlFactoryContract, "Paused")
                });
                it("DlrFactory only ownner can unpasue", async function () {
                    await expect(proxyDrlFactoryContract.connect(admin).unpause())
                        .to.be.revertedWithCustomError(proxyDrlFactoryContract, "OwnableUnauthorizedAccount");
                });
                it("DlrFactory unpasue can emit event", async function () {
                    await proxyDrlFactoryContract.connect(owner).pause();
                    let tx = await proxyDrlFactoryContract.connect(owner).unpause();
                    await expect(tx)
                        .to.emit(proxyDrlFactoryContract, "Unpaused")
                });
            });
            describe("createMatch:      DlrFactory can create match pool", function () {
                it("DlrFactory can't same token address ", async function () {
                    await expect(proxyDrlFactoryContract.connect(admin).createMatch(
                        tokenAddresssA,
                        tokenAddresssA,
                    )).to.be.revertedWithCustomError(proxyDrlFactoryContract, "DlrFactory_TokenAddressSame");
                });
                it("DlrFactory can't be zero address ", async function () {
                    await expect(proxyDrlFactoryContract.connect(admin).createMatch(
                        tokenAddresssA,
                        adddressZero,
                    )).to.be.revertedWithCustomError(proxyDrlFactoryContract, "Dlr_AddressZero");
                });
                it("DlrFactory can't be exists address ", async function () {
                    await proxyDrlFactoryContract.connect(admin).createMatch(
                        tokenAddresssA,
                        tokenAddresssB,
                    );
                    await expect(proxyDrlFactoryContract.connect(admin).createMatch(
                        tokenAddresssA,
                        tokenAddresssB,
                    )).to.be.revertedWithCustomError(proxyDrlFactoryContract, "DlrFactory_MatchAlreadyExists");
                });
                it("DlrFactory call create match can emit created event", async function () {
                    const tx = await proxyDrlFactoryContract.connect(admin).createMatch(
                        tokenAddresssA,
                        tokenAddresssB,
                    );
                    await expect(tx)
                        .to.emit(proxyDrlFactoryContract, "DrlMatchCreated");
                });
                it("DlrFactory call create match has reture adddress", async function () {
                    const returnData = await ethers.provider.call({
                        to: proxyDrlFactoryContract.target,
                        data: proxyDrlFactoryContract.interface.encodeFunctionData("createMatch", [
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
                    const tx = await proxyDrlFactoryContract.createMatch(tokenAddresssA, tokenAddresssB);
                    const receipt = await tx.wait();
                    const eventFragment = proxyDrlFactoryContract.interface.getEvent("DrlMatchCreated");
                    const event = receipt.logs.find(log =>
                        log.topics[0] === eventFragment.topicHash
                    );

                    assert.exists(event, "DrlMatchCreated event should be emitted");
                    const decodedEvent = proxyDrlFactoryContract.interface.decodeEventLog(
                        eventFragment,
                        event.data,
                        event.topics
                    );
                    const matchAddress = decodedEvent._matchAddress;

                    assert.notEqual(matchAddress, ethers.ZeroAddress, "Invalid contract address");
                    const code = await ethers.provider.getCode(matchAddress);
                    assert.notEqual(code, "0x", "Contract code should be deployed");
                });
                it("DlrFactory call create match builded contract hash ", async function () {
                    const tx = await proxyDrlFactoryContract.createMatch(tokenAddresssA, tokenAddresssB);
                    const receipt = await tx.wait();
                    const eventFragment = proxyDrlFactoryContract.interface.getEvent("DrlMatchCreated");
                    const event = receipt.logs.find(log =>
                        log.topics[0] === eventFragment.topicHash
                    );

                    assert.exists(event, "DrlMatchCreated event should be emitted");
                    const decodedEvent = proxyDrlFactoryContract.interface.decodeEventLog(
                        eventFragment,
                        event.data,
                        event.topics
                    );
                    const matchAddress = decodedEvent._matchAddress;





                });
            });
            describe("setFeeAddress:    DlrFactory can set Fee Address ", function () {
                it("DlrFactory onyl owner can set fee address", async function () {
                    await expect(proxyDrlFactoryContract.connect(admin).setFeeAddress(owner.address))
                        .to.be.revertedWithCustomError(proxyDrlFactoryContract, "OwnableUnauthorizedAccount");
                });
                it("DlrFactory Fee address can updated", async function () {
                    await proxyDrlFactoryContract.connect(owner).setFeeAddress(owner.address);
                    const feeAddress = await proxyDrlFactoryContract.feeAddress();
                    expect(feeAddress).to.equal(owner.address, "Fee address should be updated");
                });
                it("DlrFactory Fee address can't  set address zero", async function () {
                    await expect(proxyDrlFactoryContract.connect(owner).setFeeAddress(adddressZero))
                        .to.be.revertedWithCustomError(proxyDrlFactoryContract, "Dlr_AddressZero");
                });
            });
            describe("getFeeAddress:    DlrFactory can get Fee Address ", function () {
                it("DlrFactory can't same token address ", async function () {
                    await proxyDrlFactoryContract.connect(owner).setFeeAddress(owner.address);
                    const returnData = await ethers.provider.call({
                        to: proxyDrlFactoryContract.target,
                        data: proxyDrlFactoryContract.interface.encodeFunctionData("getFeeAddress", [

                        ]),
                    });
                    const [decoded] = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["address"],
                        returnData
                    );
                    const feeAddress = await proxyDrlFactoryContract.feeAddress();
                    expect(decoded).to.equal(feeAddress, "Fee address should be updated");

                });
            });
            describe("others:           DlrMatch functions can call", function () {
                let matchAddress;
                beforeEach(async () => {
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
                    expect(matchOwner).to.equal(proxyDrlFactoryContract.target, "Match owner should be the factory address");
                });
                it("DlrMatch match hash equal test also dynamic update", async function () {
                    const TestMatch = await ignition.deploy(TestMatchModule)
                    testMatchAddress = TestMatch.testMatch.target;
                    const testMatchContract = await ethers.getContractAt("TestMatch", testMatchAddress);
                    const returnData = await ethers.provider.call({
                        to: testMatchContract.target,
                        data: testMatchContract.interface.encodeFunctionData("getMatchHash", []),
                    });
                    const decoded = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["bytes32"],
                        returnData
                    );
                    const matchHash = await proxyDrlFactoryContract.getMatchHash();

                    assert.equal(matchHash, decoded[0])
                });


                it("DlrMatch dynamic address equal general address", async function () {
                    const TestMatch = await ignition.deploy(TestMatchModule)
                    testMatchAddress = TestMatch.testMatch.target;
                    const testMatchContract = await ethers.getContractAt("TestMatch", testMatchAddress);
                    const returnData = await ethers.provider.call({
                        to: testMatchContract.target,
                        data: testMatchContract.interface.encodeFunctionData("getMatchAddress", [
                            proxyDrlFactoryContract.target,
                            tokenAddresssA,
                            tokenAddresssB,
                        ]),
                    });
                    const decoded = ethers.AbiCoder.defaultAbiCoder().decode(
                        ["address", "address", "address"],
                        returnData
                    );
                    assert.equal(matchAddress, decoded[0])
                });
            });
        })
    });

<<<<<<< HEAD
=======

>>>>>>> d48bd042e259b51997cf5c2ac9e3b6f21d456303
