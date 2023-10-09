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

        const PROXY_ADDRESS       = "0xc9C744A220Ec238Bcf7798B43C9272622aF82997"       // Need to check
        // const NEW_IMPLEMENTATION  = "0x89fd8eEb870898688D4071485e2152a70D743E9F"       // Need to check
        // const NEW_IMPLEMENTATION  = "0xE4D0A7A56AF8B4E864E653BE78ECb68ca7EaeCE2"       // Need to check
        // const NEW_IMPLEMENTATION  = "0xC3A06c6a0C3e60af16FC319e332Db6525e749d9D"       // without getPrice
        const NEW_IMPLEMENTATION  = "0xDa424C4751f19325f07177b432329ff9C98b36FE"       // with getPrice

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
