import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
//import { CONTRACTS } from "../constants";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {

    const greenBTC = "GreenBTC"

    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log(`Driect Deploying: ${greenBTC} from ${deployer}`); 
    const GreenBTC = await deploy(greenBTC, {
        from: deployer,
        args: ["green btc", "GBTC"],
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log("GreenBTC deployed to %s at %s: ", hre.network.name, GreenBTC.address);
};

func.tags = ["GreenBTC_D"];

export default func;