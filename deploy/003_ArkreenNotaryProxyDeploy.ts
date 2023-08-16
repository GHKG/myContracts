import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";


const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {

    const arkreenNotaryU = "ArkreenNotaryU"
    const dataManager = "0x1AD49E84283E5418175985908459daccD5E60ec8"//mumbai
    // const dataManager = "0x8a13a3614c2c0b91f4c4506fb80bb85db711db0b"//polygon

    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log(`Proxy deploying: ${arkreenNotaryU} from ${deployer}`);  
    const ArkreenNotaryU = await deploy(arkreenNotaryU, {
        from: deployer,
        proxy: {
          proxyContract: "UUPSProxy",     //use UUPSProxy contract as proxy contract
          execute: {
            init: {
              methodName: "initialize",   // Function to call when deployed first time.
              args: [dataManager]
            },
          },
        },
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log("ArkreenNotaryU deployed to %s: ", hre.network.name, ArkreenNotaryU.address);
  
};

func.tags = ["ArkreenN_P"];

export default func;