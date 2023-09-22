import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
//import { CONTRACTS } from "../constants";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {

    const SVG_image = "SVG_image"

    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log(`Driect Deploying: ${SVG_image} from ${deployer}`); 
    const svg_image = await deploy(SVG_image, {
        from: deployer,
        // args: [authorizer],
        args:[],
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log("SVG_image deployed to %s at %s: ", hre.network.name, svg_image.address);
};

func.tags = ["SVG_image_D"];

export default func;