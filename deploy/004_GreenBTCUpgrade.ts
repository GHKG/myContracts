import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { GreenBTC__factory } from "../typechain";


const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    // const { deployerAddress } = await getNamedAccounts();

    // console.log("Deploying Updated ArkreenRetirement: ", CONTRACTS.RECRetire, deployerAddress);  
     
    if(hre.network.name === 'matic_test') {
    // if(hre.network.name === 'matic') {

        const PROXY_ADDRESS       = "0x2BCCE98D208f9f45330006C24cbC756A0A7ddB3a"       // Need to check
        // const PROXY_ADDRESS       = "0xc9C744A220Ec238Bcf7798B43C9272622aF82997"       // Need to check
        
        // const NEW_IMPLEMENTATION  = "0x89fd8eEb870898688D4071485e2152a70D743E9F"       // Need to check
        // const NEW_IMPLEMENTATION  = "0xE4D0A7A56AF8B4E864E653BE78ECb68ca7EaeCE2"       // Need to check
        // const NEW_IMPLEMENTATION  = "0xC3A06c6a0C3e60af16FC319e332Db6525e749d9D"       // without getPrice
        // const NEW_IMPLEMENTATION  = "0xDa424C4751f19325f07177b432329ff9C98b36FE"       // with getPrice
        // const NEW_IMPLEMENTATION  = "0xCc98af460d3cFC032EEd1F578eA1d6301A1b2D02"       // with image contract
        // const NEW_IMPLEMENTATION  = "0x9cB546237962fD887C4743983a167e4B691304d3"       // use GreenBTCImage interface
        // const NEW_IMPLEMENTATION  = "0x83534e2F7B4B7f1AD174D4F18E9C51152bad8968"       // add manager operation  
                                    //!!!!!! block 1001 在 GreenBTC合约中未铸造，没有释出事件
        // const NEW_IMPLEMENTATION  = "0x75E6168Fbb10E27d1fbe99F723CBCCf0355a4Fb3"       // add mint with ART
        const NEW_IMPLEMENTATION  = "0xcB0f17570AF1f1595C6F7cf7155aCe9Fe2402AbE"       // add event OpenBox

        const [deployer] = await ethers.getSigners();
        const GreenBTC = GreenBTC__factory.connect(PROXY_ADDRESS, deployer);

        //const callData = ArkreenTokenUpgradeableV2.interface.encodeFunctionData("postUpdate", [FOUNDATION_ADDRESS])
//      const callData = ArkreenTokenUpgradeableV2.interface.encodeFunctionData("postUpdate", [...])
        const updateTx = await GreenBTC.upgradeTo(NEW_IMPLEMENTATION)
        await updateTx.wait()

        // console.log("callData, update", callData, updateTx)
        console.log(`GreenBTC deployed to ${hre.network.name} at ${GreenBTC.address} upgrade to new implementation ${NEW_IMPLEMENTATION}`);
        return
    } 
};

func.tags = ["GreenBTC_UP"];

export default func;
