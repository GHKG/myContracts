import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";


const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {

    const greenBTC_U = "GreenBTC"
    const authorizer = "0x2df522C2bF3E570caA22FBBd06d1A120B4Dc29a8"//mumbai
    const arkreenBuilder = "0xA05A9677a9216401CF6800d28005b227F7A3cFae"
    const exchangeART = "0x0999AFb673944a7B8E1Ef8eb0a7c6FFDc0b43E31"


    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    console.log(`Proxy deploying: ${greenBTC_U} from ${deployer}`);  
    const GreenBTC_U = await deploy(greenBTC_U, {
        from: deployer,
        proxy: {
          proxyContract: "UUPSProxy",     //use UUPSProxy contract as proxy contract
          execute: {
            init: {
              methodName: "initialize",   // Function to call when deployed first time.
              args: [authorizer, arkreenBuilder, exchangeART]
            },
          },
        },
        log: true,
        skipIfAlreadyDeployed: false,
    });

    console.log("GreenBTC deployed to %s at %s ", hre.network.name, GreenBTC_U.address);
  
};

func.tags = ["GreenBTC_V2_P"];

export default func;