import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
//import { CONTRACTS } from "../constants";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {

    const GreenBTCImage = "GreenBTCImage"

    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log(`Driect Deploying: ${GreenBTCImage} from ${deployer}`); 
    const svg_image = await deploy(GreenBTCImage, {
        from: deployer,
        // args: [authorizer],
        args:[],
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log("GreenBTCImage deployed to %s at %s: ", hre.network.name, svg_image.address);
};

func.tags = ["GreenBTCImage_D"];

export default func;

//0x84d059fb3531272ab863adef40807d398a6d604b
//0x7295216A1986C65Cd6bDA5b1Af41340775E36891   可截取能量字段的小数