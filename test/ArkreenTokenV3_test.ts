import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
const {ethers, upgrades} =  require("hardhat");
import hre from 'hardhat'
import { ecsign, fromRpcSig, ecrecover } from 'ethereumjs-util'
import {getPermitDigest, expandToDecimals, ZERO_ADDRESS} from './utils/myUtils'

// console.log(upgrades)

import {
    ArkreenTokenV1,
    ArkreenTokenV1__factory,
    ArkreenTokenV2,
    ArkreenTokenV2__factory,
    ArkreenTokenV3,
    ArkreenTokenV3__factory
} from "../typechain";
import { deploy } from "@openzeppelin/hardhat-upgrades/dist/utils";

describe("test ArkreenTokenV3", ()=>{

    async function deployFixture() {
        const [deployer, user1,user2] = await ethers.getSigners();
        //  console.log(deployer.address)
        const ArkreenTokenV3Factory = await ethers.getContractFactory("ArkreenTokenV3")
        const arkreenTokenV3 : ArkreenTokenV3 = await upgrades.deployProxy(
            ArkreenTokenV3Factory, [100000000, user1.address],{initializer: 'initialize',kind: "uups"})
  
        await arkreenTokenV3.deployed()

        return {arkreenTokenV3, deployer, user1, user2}


    }

    describe('init test', () => {
        it("all argument should be set correctly ", async function () {

            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
            // console.log(arkreenTokenV1.deployTransaction)
    
            expect(await arkreenTokenV3.totalSupply()).to.equal(expandToDecimals(100000000, 18));
            expect(await arkreenTokenV3.balanceOf(user1.address)).to.equal(expandToDecimals(100000000, 18));
            expect(await arkreenTokenV3.balanceOf(user2.address)).to.equal(0);
            expect(await arkreenTokenV3.owner()).to.be.equal(deployer.address)
    
        //     const chainId = hre.network.config.chainId
        //     //const chainId = 80001;
        //   console.log(`chainId is  ${chainId}`);
    
        });

        it('function initialize() could be execute only onec',async () => {
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

            await expect(arkreenTokenV3.initialize(100000000, user1.address)).to.be.revertedWith("Initializable: contract is already initialized")
        })
    })

    describe('permit test', () => {

        it("approve by permit transaction", async () => {

            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
            const user1_key = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
            const value = 100
            const nonce = 0
            const deadline = 19000000000    //big enough
            const domainName = await arkreenTokenV3.name()

            const digest = getPermitDigest(
                    user1.address,
                    user2.address,
                    ethers.BigNumber.from(value),
                    ethers.BigNumber.from(nonce),
                    ethers.BigNumber.from(deadline),
                    arkreenTokenV3.address,
                    domainName,
                    "1"
                  )

            const {v,r,s} = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(user1_key.slice(2), 'hex'))

            expect(await arkreenTokenV3.connect(deployer).permit(
                user1.address, 
                user2.address, 
                ethers.BigNumber.from(value), 
                ethers.BigNumber.from(deadline),
                v,  r,  s)).to.be.ok

            expect(await arkreenTokenV3.allowance(user1.address, user2.address)).to.be.equal(value)
        })

        it("expired deadline should be reverted", async ()=>{
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
            // console.log(await ethers.getSigners())
            const user1_key = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
            const value = 100
            const nonce = 0
            const deadline = 19000000   //a little timestamp number
            const domainName = await arkreenTokenV3.name()
            // console.log("domain name is :",domainName)

            const digest = getPermitDigest(
                    user1.address,
                    user2.address,
                    ethers.BigNumber.from(value),
                    ethers.BigNumber.from(nonce),
                    ethers.BigNumber.from(deadline),
                    arkreenTokenV3.address,
                    domainName,
                    "1"
                  )
            // const sig = await (user1 as SignerWithAddress).signMessage(digest)

            // console.log(sig)

            const {v,r,s} = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(user1_key.slice(2), 'hex'))
            // console.log(v, r, s)

            await expect(arkreenTokenV3.connect(deployer).permit(
                user1.address, 
                user2.address, 
                ethers.BigNumber.from(value), 
                ethers.BigNumber.from(deadline),
                v,  r,  s)).to.be.revertedWith("ERC20Permit: expired deadline")

        })

        it("wrong version cause sig error ,should be reverted", async ()=>{
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
            const user1_key = "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"
            const value = 100
            const nonce = 0
            const deadline = 19000000000
            const domainName = await arkreenTokenV3.name()

            const digest = getPermitDigest(
                    user1.address,
                    user2.address,
                    ethers.BigNumber.from(value),
                    ethers.BigNumber.from(nonce),
                    ethers.BigNumber.from(deadline),
                    arkreenTokenV3.address,
                    domainName,
                    "2"//********************** */ use the wrong verson '2'
                  )

            const {v,r,s} = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(user1_key.slice(2), 'hex'))

            await expect(arkreenTokenV3.connect(deployer).permit(
                user1.address, 
                user2.address, 
                ethers.BigNumber.from(value), 
                ethers.BigNumber.from(deadline),
                v,  r,  s)).to.be.revertedWith("ERC20Permit: invalid signature")

        })

    })

    describe("pause test", ()=>{

        it('if paused , transfer is forbidden', async () => {
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

            await arkreenTokenV3.connect(deployer).pause();
            await expect(arkreenTokenV3.connect(user1).transfer(user2.address, expandToDecimals(100, 8))).to.be.revertedWith('Pausable: paused')
        })
        it('if unpaused , transfer is allowed', async () => {
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
           
            await arkreenTokenV3.connect(deployer).pause();
            await arkreenTokenV3.connect(deployer).unpause();
            expect(await arkreenTokenV3.connect(user1).transfer(user2.address, expandToDecimals(100, 8))).to.be.ok
            expect(await arkreenTokenV3.balanceOf(user2.address)).to.equal(expandToDecimals(100, 8));
        })
    })

    describe("ownerable test", ()=>{

        it('only owner could call pause/unpause function',async () => {
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
            expect(await arkreenTokenV3.connect(deployer).pause()).to.be.ok;
            await expect(arkreenTokenV3.connect(user1).unpause()).to.be.revertedWith('Ownable: caller is not the owner')
        })

        it('only owner can transfer ownership',async () => {
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

            expect(await arkreenTokenV3.owner()).to.be.equal(deployer.address)
            await arkreenTokenV3.transferOwnership(user1.address)
            await expect(arkreenTokenV3.transferOwnership(user2.address)).to.be.revertedWith("Ownable: caller is not the owner")
            await arkreenTokenV3.connect(user1).transferOwnership(user2.address)
            expect(await arkreenTokenV3.owner()).to.be.equal(user2.address)
        })
        it('transfer ownership to address 0 is not allowed',async () => {
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
            await expect(arkreenTokenV3.transferOwnership(ZERO_ADDRESS)).to.be.revertedWith("Ownable: new owner is the zero address")
        })

    })

    describe.only("votes test",  ()=>{


        it("after initialize, global checkpoints[0].vote shoud be equal expandToDecimals(100000000, 18)", async ()=>{
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

            // await ethers.provider.send("evm_mine");
            // let currentBlockNumber = await ethers.provider.getBlockNumber();
            // console.log("current block number is : ", currentBlockNumber)

            await ethers.provider.send("evm_mine");
            let currentBlockNumber = await ethers.provider.getBlockNumber();
            console.log("current block number is : ", currentBlockNumber)

            expect(await arkreenTokenV3.getPastTotalSupply(currentBlockNumber-1)).to.be.equal(expandToDecimals(100000000, 18))
        })

        it("before delegate, any user have no checkpoint", async ()=>{
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

            expect(await arkreenTokenV3.numCheckpoints(deployer.address)).to.be.equal(0)
            expect(await arkreenTokenV3.numCheckpoints(user1.address)).to.be.equal(0)

        })

        it("after delegate, user got checkpoint", async ()=>{

            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

            // expect(await arkreenTokenV3.connect(deployer.address).transfer(user1.address, 10000)).to.be.ok;

            expect(await arkreenTokenV3.numCheckpoints(user1.address)).to.be.equal(0)
            expect(await arkreenTokenV3.connect(user1).delegate(user1.address)).to.be.ok;
            expect(await arkreenTokenV3.numCheckpoints(user1.address)).to.be.equal(1)
            expect(await arkreenTokenV3.getVotes(user1.address)).to.be.equal(expandToDecimals(100000000, 18))

        })

        it.only("after token transfer, both sende and receiver modify their own vote power", async ()=>{
            const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

            expect(await arkreenTokenV3.numCheckpoints(user1.address)).to.be.equal(0)
            expect(await arkreenTokenV3.numCheckpoints(user2.address)).to.be.equal(0)

            expect(await arkreenTokenV3.connect(user1).delegate(user1.address)).to.be.ok;
            expect(await arkreenTokenV3.connect(user2).delegate(user2.address)).to.be.ok;

            expect(await arkreenTokenV3.numCheckpoints(user1.address)).to.be.equal(1)
            // expect(await arkreenTokenV3.numCheckpoints(user2.address)).to.be.equal(1)

            // expect(await arkreenTokenV3.connect(user1).transfer(user2.address, expandToDecimals(30000000, 18))).to.be.ok;

            // expect(await arkreenTokenV3.numCheckpoints(user1.address)).to.be.equal(2)
            // expect(await arkreenTokenV3.numCheckpoints(user2.address)).to.be.equal(2)

            // expect(await arkreenTokenV3.getVotes(user1.address)).to.be.equal(expandToDecimals(70000000, 18))
            // expect(await arkreenTokenV3.getVotes(user2.address)).to.be.equal(expandToDecimals(30000000, 18))

        })

        // it("", async ()=>{
        //     const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
        // })

        // it("", async ()=>{
        //     const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
        // })

        // it("", async ()=>{
        //     const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)
        // })

    })

    // describe("upgrade test", ()=>{

    //     it("contract owner should be deployer", async () =>{
    //         const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

    //         expect(await arkreenTokenV3.connect(deployer).owner()).to.be.equal(deployer.address)
    //     })

    //     it("upgrade method 1", async ()=>{

    //         const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

    //         // console.log("AKRETokenUpgradeable address is " + arkreenTokenV1.address)
    //         // console.log("deployer address is " + deployer.address)

    //         // console.log(await upgrades.erc1967.getImplementationAddress(arkreenTokenV1.address)," getImplementationAddress")
    //         // console.log(await upgrades.erc1967.getAdminAddress(arkreenTokenV1.address)," getAdminAddress")  


    //         let ArkreenTokenV2Factory = await ethers.getContractFactory("ArkreenTokenV2")
    //         let AKRETokenV2 = await ArkreenTokenV2Factory.deploy()
    //         await AKRETokenV2.deployed()
            

    //         // console.log()
    //         // console.log("new ArkreenTokenV2 impl address is " + AKRETokenV2.address)

    //         const ArkreenTokenV1Factory = ArkreenTokenV1__factory.connect(arkreenTokenV1.address, deployer);
    //         let calldata = arkreenTokenV1.interface.encodeFunctionData("postUpdate", [user2.address])
    //         const updateTx = await arkreenTokenV1.upgradeToAndCall(AKRETokenV2.address, calldata)
    //         await updateTx.wait()

    //         // console.log(await upgrades.erc1967.getImplementationAddress(arkreenTokenV1.address)," getImplementationAddress")
    //         // console.log(await upgrades.erc1967.getAdminAddress(arkreenTokenV1.address)," getAdminAddress") 

    //         expect(await upgrades.erc1967.getImplementationAddress(arkreenTokenV1.address)).to.be.equal(AKRETokenV2.address)
    //         expect(await arkreenTokenV1.balanceOf(user2.address)).to.be.equal(expandToDecimals((10_000_000_000 - 10) ,8))
    //     })

    //     it("upgrade method 2", async ()=>{

    //         const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

    //         // console.log("AKRETokenUpgradeable address is " + arkreenTokenV1.address)
    //         // console.log("deployer address is " + deployer.address)

    //         // console.log(await upgrades.erc1967.getImplementationAddress(arkreenTokenV1.address)," getImplementationAddress")
    //         // console.log(await upgrades.erc1967.getAdminAddress(arkreenTokenV1.address)," getAdminAddress")  

    //         // console.log("before upgrade")
    //         // console.log(await upgrades.erc1967.getImplementationAddress(arkreenTokenV1.address)," getImplementationAddress")
    //         // console.log(await upgrades.erc1967.getAdminAddress(arkreenTokenV1.address)," getAdminAddress")    
            
    //         let ArkreenTokenV2Factory = await ethers.getContractFactory("ArkreenTokenV2")
    //         let arkreenTokenV2 = await upgrades.upgradeProxy(arkreenTokenV1.address, ArkreenTokenV2Factory)

            

    //         // console.log("after upgrade")
    //         // console.log("ArkreenTokenV2 address is " + arkreenTokenV2.address)
    //         expect(arkreenTokenV2.address).to.be.equal(arkreenTokenV1.address)

    //         // console.log(await upgrades.erc1967.getImplementationAddress(arkreenTokenV2.address)," getImplementationAddress")
    //         // console.log(await upgrades.erc1967.getAdminAddress(arkreenTokenV2.address)," getAdminAddress")    

    //         //expect(await ArkreenTokenUpgradeable2.connect(deployer).nonces(receiver.address)).to.be.equal(0)
    //         expect(await arkreenTokenV2.connect(deployer).setMarking('aaaaa')).to.be.ok
    //         expect(await arkreenTokenV2.connect(deployer).marking()).to.be.equal('aaaaa')

    //     })

    //     it('only owner could do upgrade',async () => {
    //         const {arkreenTokenV1, deployer, user1, user2} = await loadFixture(deployFixture)

    //         let ArkreenTokenV2Factory = await ethers.getContractFactory("ArkreenTokenV2")
    //         let AKRETokenV2 = await ArkreenTokenV2Factory.deploy()
    //         await AKRETokenV2.deployed()
            
    //         await expect(arkreenTokenV1.connect(user1).upgradeTo(AKRETokenV2.address)).to.be.revertedWith('Ownable: caller is not the owner')
    //     })
    // })

    // describe('proxy test',async () => {
        
    //     it('only proxy could call postUpdate',async () => {
            
    //         const {arkreenTokenV3, deployer, user1, user2} = await loadFixture(deployFixture)

    //         let ArkreenTokenV1Factory = await ethers.getContractFactory("ArkreenTokenV1")
    //         let AKRETokenV1 = await ArkreenTokenV1Factory.deploy()
    //         await AKRETokenV1.deployed()

    //         await expect(AKRETokenV1.postUpdate(user1.address)).to.be.revertedWith('Function must be called through delegatecall')
    //     })
    // })


})