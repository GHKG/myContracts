import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
const {ethers, upgrades} =  require("hardhat");
// import hre from 'hardhat'
import { ZERO_ADDRESS} from './utils/myUtils'


import {
    ArkreenNotaryU,
    ArkreenNotaryU__factory,
    ArkreenNotaryU2,
    ArkreenNotaryU2__factory
} from "../typechain";
import { deploy } from "@openzeppelin/hardhat-upgrades/dist/utils";

describe("test ArkreenNotary", ()=>{

    async function deployFixture() {
        const [deployer, manager, user2] = await ethers.getSigners();

        let ArkreenNotaryUFactory = await ethers.getContractFactory("ArkreenNotaryU");
        const arkreenNotary:ArkreenNotaryU= await upgrades.deployProxy(ArkreenNotaryUFactory, [manager.address], {initializer: 'initialize', kind: 'uups'});
        await arkreenNotary.deployed();

        return {arkreenNotary, deployer, manager, user2}
        
    }

    describe("set data manager test", ()=>{

        it("only owner can set data manager",async () => {
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)
            expect(await arkreenNotary.dataManager()).to.be.equal(manager.address)
            expect(await arkreenNotary.connect(deployer).setDataManager(user2.address)).to.be.ok
            expect(await arkreenNotary.dataManager()).to.be.equal(user2.address)

            await expect(arkreenNotary.connect(user2).setDataManager(manager.address)).to.be.revertedWith("Ownable: caller is not the owner")            
        })

        it('zero address is not allowed for data manager',async () => {
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)

            await expect(arkreenNotary.connect(deployer).setDataManager(ZERO_ADDRESS)).to.be.revertedWith("zero address is forbidden !")
        })

        it('identical address is not allowed for data manager',async () => {
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)

            await expect(arkreenNotary.connect(deployer).setDataManager(manager.address)).to.be.revertedWith("identical address is forbidden !")
        })
        
    })

    describe("save data test", ()=>{

        it("user can not save data except the data manager", async function () {
    
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)
    
            expect(await arkreenNotary.dataManager()).to.be.equal(manager.address)
            await expect(arkreenNotary.connect(deployer).saveData("aaa", "bbb", 100, 100, 100)).to.be.revertedWith("Only data manager can do this!")
            expect(await arkreenNotary.connect(manager).saveData("aaa", "bbb", 100, 100, 100)).to.be.ok
        });
    
        it("save data", async function () {
    
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)
    
            expect(await arkreenNotary.connect(manager).saveData("aaa", "bbb", 0, 1, 2)).to.be.ok
    
            expect(await arkreenNotary.blockHash()).to.be.equal("aaa")
            expect(await arkreenNotary.cid()).to.be.equal("bbb")
            expect(await arkreenNotary.blockHeight()).to.be.equal(0)
            expect(await arkreenNotary.totalPowerGeneraton()).to.be.equal(1)
            expect(await arkreenNotary.circulatingSupply()).to.be.equal(2)
    
        });

        it("blockheight, totalPowerGeneraton, circulatingSupply should be increased", async function(){

            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)
    
            expect(await arkreenNotary.connect(manager).saveData("aaa", "bbb", 100, 100, 100)).to.be.ok
    
            await expect(arkreenNotary.connect(manager).saveData("aaa", "b", 99, 100, 100)).to.be.revertedWith("blockHeight data must increase!")
            await expect(arkreenNotary.connect(manager).saveData("aaa", "b", 100, 99, 100)).to.be.revertedWith("totalPowerGeneraton data must increase!")
            await expect(arkreenNotary.connect(manager).saveData("aaa", "b", 100, 100, 99)).to.be.revertedWith("circulatingSupply data must increase!")
        })
    })


    describe("ownerable test", ()=>{

        it("deployer should be owner", async function () {

            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)
    
            expect(await arkreenNotary.owner()).to.be.equal(deployer.address)
    
        });
    

        it('only owner can transfer ownership',async () => {
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)

            expect(await arkreenNotary.owner()).to.be.equal(deployer.address)
            await arkreenNotary.transferOwnership(user2.address)
            expect(await arkreenNotary.owner()).to.be.equal(user2.address)
            await expect(arkreenNotary.transferOwnership(manager.address)).to.be.revertedWith("Ownable: caller is not the owner")
            await arkreenNotary.connect(user2).transferOwnership(manager.address)
            expect(await arkreenNotary.owner()).to.be.equal(manager.address)
        })

        it('transfer ownership to address 0 is not allowed',async () => {
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)
            await expect(arkreenNotary.transferOwnership(ZERO_ADDRESS)).to.be.revertedWith("Ownable: new owner is the zero address")
        })
    })

    describe('event test',async () => {

        it("saveData should emit event",async () => {
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)

            await expect(arkreenNotary.connect(manager).saveData("aaa", "b", 99, 100, 100))
            .to.emit(arkreenNotary, "DataSaved")
            .withArgs("aaa", "b", 99, 100, 100);
        })

    })

    describe('upgrade test',async () => {
        

        it('only owner could do upgrade',async () => {
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)

            let ArkreenNotaryU2Factory = await ethers.getContractFactory("ArkreenNotaryU2")
            let arkreenNotaryU2 = await ArkreenNotaryU2Factory.deploy()
            await arkreenNotaryU2.deployed()
            
            await expect(arkreenNotary.connect(user2).upgradeTo(arkreenNotaryU2.address)).to.be.revertedWith('Ownable: caller is not the owner')
        })

        it('upgrade to new empl',async () => {
            const {arkreenNotary, deployer, manager, user2} = await loadFixture(deployFixture)

            let ArkreenNotaryU2Factory = await ethers.getContractFactory("ArkreenNotaryU2")
            let arkreenNotaryU2 = await ArkreenNotaryU2Factory.deploy()
            await arkreenNotaryU2.deployed()
            
            const updateTx = await arkreenNotary.upgradeTo(arkreenNotaryU2.address)
            await updateTx.wait()

            expect(await upgrades.erc1967.getImplementationAddress(arkreenNotary.address)).to.be.equal(arkreenNotaryU2.address)
            
            const aNotaryU2Factory = ArkreenNotaryU2__factory.connect(arkreenNotary.address, deployer);
            const aNotaryU2 = aNotaryU2Factory.attach(arkreenNotary.address)  
            await expect(aNotaryU2.saveData("aaa", "b", 99, 100, 100, 99))
                .to.emit(aNotaryU2, "DataSaved2")
                .withArgs("aaa", "b", 99, 100, 100, 99);

        })
    })



})