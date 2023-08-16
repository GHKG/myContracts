import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";


const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {

    const arkreenReward_V1 = "ArkreenRewardV1"

     // Need to check and update !!!!!
    const AKRE_TOKEN_ADDRESS    = "0xc83DEd2B70F25C0EB0ef1cDE993DEaA3fAE91314"  
    const VALIDATOR_ADDRESS     = "0x8C4D62477F70C7Ea628B52dbF37DcC2E5e4043E2"  //deployer or 

    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log(`Proxy Deploying: ${arkreenReward_V1} from ${deployer}`);  
    const ArkreenRewardV1 = await deploy(arkreenReward_V1, {
        from: deployer,
        proxy: {
          proxyContract: "UUPSProxy",
          execute: {
            init: {
              methodName: "initialize",   // Function to call when deployed first time.
              args: [AKRE_TOKEN_ADDRESS, VALIDATOR_ADDRESS]
            },
          },
        },
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log("ArkreenRewardV1 deployed to %s: ", hre.network.name, ArkreenRewardV1.address);
};

func.tags = ["ArkreenR_P"];

export default func;
