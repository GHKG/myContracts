import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";
import { ArkreenNotaryU__factory } from "../typechain";


const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    // const { deployerAddress } = await getNamedAccounts();

    // console.log("Deploying Updated ArkreenRetirement: ", CONTRACTS.RECRetire, deployerAddress);  
     
    if(hre.network.name === 'matic_test') {
        const PROXY_ADDRESS       = "0xff7330D8EfEF19aa2214eFbbc7b26ef4Def3a3b6"       // Need to check
        const NEW_IMPLEMENTATION  = "0x03C10DAf2d1657842b4AD86aDCf9AcBA4Dc9E949"       // Need to check
        //const FOUNDATION_ADDRESS  = "0x1C9055Db231CD96447c61D07B3cEA77592154C3d"  //from Gery        

        const [deployer] = await ethers.getSigners();
        const ArkreenNotaryU = ArkreenNotaryU__factory.connect(PROXY_ADDRESS, deployer);

        //const callData = ArkreenTokenUpgradeableV2.interface.encodeFunctionData("postUpdate", [FOUNDATION_ADDRESS])
//      const callData = ArkreenTokenUpgradeableV2.interface.encodeFunctionData("postUpdate", [...])
        const updateTx = await ArkreenNotaryU.upgradeTo(NEW_IMPLEMENTATION)
        await updateTx.wait()

        // console.log("callData, update", callData, updateTx)
        console.log(`ArkreenNotaryU deployed to ${hre.network.name} at ${ArkreenNotaryU.address} upgrade to new implementation ${NEW_IMPLEMENTATION}`);
    } 
};

func.tags = ["ArkreenN_U2_UP"];

export default func;
