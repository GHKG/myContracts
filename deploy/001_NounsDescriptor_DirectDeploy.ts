import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
//import { CONTRACTS } from "../constants";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {

    const nounsDescriptor = "NounsDescriptor"

    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log(`Driect Deploying: ${nounsDescriptor} from ${deployer}`); 
    const NounsDescriptor = await deploy(nounsDescriptor, {
        from: deployer,
        args: [],
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log("NounsDescriptor deployed to %s: ", hre.network.name, NounsDescriptor.address);
};

func.tags = ["NounsDescriptor_D"];

export default func;