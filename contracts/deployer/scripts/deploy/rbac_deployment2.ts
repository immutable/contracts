// Deploy child contracts
import * as dotenv from "dotenv";
dotenv.config();
import { ethers } from "ethers";
import { requireEnv } from "../helpers/helpers";
import * as fs from "fs";

export async function run() {
    // Check environment variables
    let rbacAdmin = requireEnv("CHILD_RBAC_DEPLOYER_ADMIN");
    let rbacOwnerMgr = requireEnv("CHILD_RBAC_DEPLOYER_OWNER_MANAGER");
    let rbacPauser = requireEnv("CHILD_RBAC_DEPLOYER_PAUSER");
    let rbacUnpauser = requireEnv("CHILD_RBAC_DEPLOYER_UNPAUSER");

    let contractObj = JSON.parse(fs.readFileSync(`../../../../foundry-out/AccessControlledDeployer.sol/AccessControlledDeployer.json`, 'utf8'));
    let result = ethers.utils.defaultAbiCoder.encode(["address", "address", "address", "address"], [rbacAdmin, rbacOwnerMgr, rbacPauser, rbacUnpauser]);
    result = ethers.utils.solidityPack(["bytes", "bytes"], [contractObj.bytecode.object, result]);

    console.log("bytecode: ", result);
}
run();