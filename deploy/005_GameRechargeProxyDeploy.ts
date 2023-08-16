import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";


const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {

    const gameRecharge = "GameRecharge"

    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log(`Proxy deploying: ${gameRecharge} from ${deployer}`);  
    const GameRecharge = await deploy(gameRecharge, {
        from: deployer,
        proxy: {
          proxyContract: "UUPSProxy",     //use UUPSProxy contract as proxy contract
          execute: {
            init: {
              methodName: "initialize",   // Function to call when deployed first time.
              args: []
            },
          },
        },
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log("GameRecharge deployed to %s at %s ", hre.network.name, GameRecharge.address);
  
};

func.tags = ["GameRecharge_P"];

export default func;