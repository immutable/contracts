// Deploy child contracts
import * as dotenv from "dotenv";
dotenv.config();
import { ethers } from "ethers";
import { requireEnv } from "../helpers/helpers";
import * as fs from "fs";

export async function run() {
    // Check environment variables
    let create3Owner = requireEnv("CHILD_CREATE3_OWNER");

    let contractObj = JSON.parse(fs.readFileSync(`../../../../foundry-out/OwnableCreate3Deployer.sol/OwnableCreate3Deployer.json`, 'utf8'));
    let result = ethers.utils.defaultAbiCoder.encode(["address"], [create3Owner]);
    result = ethers.utils.solidityPack(["bytes", "bytes"], [contractObj.bytecode.object, result]);

    console.log("bytecode: ", result);
}
run();