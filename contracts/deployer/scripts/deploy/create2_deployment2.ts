// Deploy child contracts
import * as dotenv from "dotenv";
dotenv.config();
import { ethers } from "ethers";
import { requireEnv } from "../helpers/helpers";
import * as fs from "fs";

export async function run() {
    // Check environment variables
    let create2Owner = requireEnv("CHILD_CREATE2_OWNER");

    let contractObj = JSON.parse(fs.readFileSync(`../../../../foundry-out/OwnableCreate2Deployer.sol/OwnableCreate2Deployer.json`, 'utf8'));
    let result = ethers.utils.defaultAbiCoder.encode(["address"], [create2Owner]);
    result = ethers.utils.solidityPack(["bytes", "bytes"], [contractObj.bytecode.object, result]);

    console.log("bytecode: ", result);
}
run();