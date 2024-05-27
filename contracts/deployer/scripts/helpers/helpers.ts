import { ContractFactory, providers, ethers } from "ethers";
import { LedgerSigner } from "./ledger_signer";
import * as fs from "fs";
import util from 'util';
const exec = util.promisify(require('child_process').exec);

export function delay(time: number) {
    return new Promise(resolve => setTimeout(resolve, time));
}

export function requireEnv(envName: string) {
    let val = process.env[envName];
    if (val == null || val == "") {
        throw(envName + " not set!");
    }
    if (!envName.includes("SECRET")) {
        console.log(envName + ": ", val);
    } else {
        console.log(envName + " is set.");
    }
    return val
}

export async function waitForReceipt(txHash: string, provider: providers.JsonRpcProvider) {
    let receipt;
    while (receipt == null) {
        receipt = await provider.getTransactionReceipt(txHash)
        await exports.delay(1000);
    }
    console.log("Receipt: " + JSON.stringify(receipt, null, 2));
    if (receipt.status != 1) {
        throw("Fail to execute: " + txHash);
    }
    console.log("Tx " + txHash + " succeed.");
}

export async function waitForConfirmation() {
    if (process.env["SKIP_WAIT_FOR_CONFIRMATION"] == null) {
        for (let i = 10; i >= 0; i--) {
            console.log(i)
            await exports.delay(1000);
        }
    }
}

export async function getFee(provider: providers.JsonRpcProvider) {
    let feeData = await provider.getFeeData();
    let baseFee = feeData.lastBaseFeePerGas;
    let gasPrice = feeData.gasPrice;
    let priorityFee;
    let maxFee;
    if (gasPrice && baseFee) {
        priorityFee = gasPrice.mul(150).div(100);
        maxFee = baseFee.mul(113).div(100).add(priorityFee);
    } else {
        priorityFee = ethers.utils.parseUnits("110", "gwei");
        maxFee = ethers.utils.parseUnits("120", "gwei");
    }
    return [priorityFee, maxFee];
}

export async function requireNonEmptyCode(provider: providers.JsonRpcProvider, addr: string) {
    if (await provider.getCode(addr) == "0x") {
        throw(addr + " has empty code!");
    }
    console.log(addr + " has code.");
}

export function hasDuplicates(array: string[]) {
    return (new Set(array)).size !== array.length;
}

function getContractObj(contract: string): string {
    if (contract.includes("AccessControlledDeployer")) {
        return fs.readFileSync(`../../../../artifacts/contracts/deployer/${contract}.sol/${contract}.json`, 'utf8')
    } else if (contract.includes("Create2")) {
        return fs.readFileSync(`../../../../artifacts/contracts/deployer/create2/${contract}.sol/${contract}.json`, 'utf8')
    } else if (contract.includes("Create3")) {
        return fs.readFileSync(`../../../../artifacts/contracts/deployer/create3/${contract}.sol/${contract}.json`, 'utf8')
    } else {
        return fs.readFileSync(`../../out/${contract}.sol/${contract}.json`, 'utf8')
    }
}

export async function deployChildContract(contract: string, adminWallet: ethers.Wallet | LedgerSigner, reservedNonce: number | null, ...args: any) {
    let contractObj = JSON.parse(getContractObj(contract));
    let [priorityFee, maxFee] = await exports.getFee(adminWallet);
    let factory = new ContractFactory(contractObj.abi, contractObj.bytecode, adminWallet);
    let overrides;
    if (reservedNonce != null) {
        overrides = {
            maxPriorityFeePerGas: priorityFee,
            maxFeePerGas: maxFee,
            nonce: reservedNonce,
        }
    } else {
        overrides = {
            maxPriorityFeePerGas: priorityFee,
            maxFeePerGas: maxFee,
        }
    }
    return await factory.deploy(...args, overrides);
}

export async function deployRootContract(contract: string, adminWallet: ethers.Wallet | LedgerSigner, reservedNonce: number | null, ...args: any) {
    let contractObj = JSON.parse(getContractObj(contract));
    let factory = new ContractFactory(contractObj.abi, contractObj.bytecode, adminWallet);
    if (reservedNonce == null) {
        return await factory.deploy(...args);
    } else {
        return await factory.deploy(...args, {
            nonce: reservedNonce,
        })
    }
}

export function getContract(contract: string, contractAddr: string, provider: providers.JsonRpcProvider) {
    let contractObj = JSON.parse(getContractObj(contract));
    return new ethers.Contract(contractAddr, contractObj.abi, provider);
}

export function getChildContracts() {
    let childContracts;
    if (fs.existsSync(".child.bridge.contracts.json")) {
        let data = fs.readFileSync(".child.bridge.contracts.json", 'utf-8');
        childContracts = JSON.parse(data);
    } else {
        childContracts = {
            CHILD_PROXY_ADMIN: "",
            CHILD_BRIDGE_IMPL_ADDRESS: "",
            CHILD_BRIDGE_PROXY_ADDRESS: "",
            CHILD_BRIDGE_ADDRESS: "",
            CHILD_ADAPTOR_IMPL_ADDRESS: "",
            CHILD_ADAPTOR_PROXY_ADDRESS: "",
            CHILD_ADAPTOR_ADDRESS: "",
            CHILD_TOKEN_TEMPLATE: "",
            WRAPPED_IMX_ADDRESS: "",
            CHILD_TEST_CUSTOM_TOKEN: "",
        };
    }
    return childContracts;
}

export function saveChildContracts(contractData: any) {
    fs.writeFileSync(".child.bridge.contracts.json", JSON.stringify(contractData, null, 2));
}

export function getRootContracts() {
    let rootContracts;
    if (fs.existsSync(".root.bridge.contracts.json")) {
        let data = fs.readFileSync(".root.bridge.contracts.json", 'utf-8');
        rootContracts = JSON.parse(data);
    } else {
        rootContracts = {
            ROOT_PROXY_ADMIN: "",
            ROOT_BRIDGE_IMPL_ADDRESS: "",
            ROOT_BRIDGE_PROXY_ADDRESS: "",
            ROOT_BRIDGE_ADDRESS: "",
            ROOT_ADAPTOR_IMPL_ADDRESS: "",
            ROOT_ADAPTOR_PROXY_ADDRESS: "",
            ROOT_ADAPTOR_ADDRESS: "",
            ROOT_TOKEN_TEMPLATE: "",
            ROOT_TEST_CUSTOM_TOKEN: "",
        };
    }
    return rootContracts;
}

export function saveRootContracts(contractData: any) {
    fs.writeFileSync(".root.bridge.contracts.json", JSON.stringify(contractData, null, 2));
}

export async function waitUntilSucceed(axelarURL: string, txHash: any) {
    if (axelarURL == "skip") {
        return;
    }
    console.log("Wait until succeed... tx hash: ", txHash)
    let response;
    let req = '{"method": "searchGMP", "txHash": "' + txHash + '"}'
    while (true) {
        response = await fetch(axelarURL, {
            method: 'POST',
            body: req,
            headers: {'Content-Type': 'application/json; charset=UTF-8'} });
        if (!response.ok) {}
        if (response.body !== null) {
            const asString = new TextDecoder("utf-8").decode(await response.arrayBuffer());
            const asJSON = JSON.parse(asString);
            if (asJSON.data[0] == undefined) {
                console.log("Waiting for " + txHash + " to become available...");
            } else {
                console.log("Current status of " + txHash + ": " + asJSON.data[0].status);
                if (asJSON.data[0].status == "executed") {
                    console.log("Done");
                    return;
                }
            }
        }
        await delay(60000);
    }
}

export async function verifyChildContract(contract: string, contractAddr: string) {
    console.log("Verifying " + contract + " at " + contractAddr + " on child chain...");
    let url = process.env["CHILD_CHAIN_BLOCKSCOUT_API_URL"];
    if (url == null || url == "") {
        console.log("CHILD_CHAIN_BLOCKSCOUT_API_URL not set, skip contract verification...");
        return; 
    }
    let cmd = `forge verify-contract --verifier blockscout --verifier-url ${url} ${contractAddr} ${contract}`;
    const { stdout, stderr } = await exec(cmd);
    if (stderr != "") {
        throw(stderr);
    }
    console.log(stdout);
}

export async function verifyRootContract(contract: string, contractAddr: string, args: string | null) {
    console.log("Verifying " + contract + " at " + contractAddr + " on root chain...");
    let key = process.env["ROOT_CHAIN_ETHERSCAN_API_KEY"];
    if (key == null || key == "") {
        console.log("ROOT_CHAIN_ETHERSCAN_API_KEY not set, skip contract verification...");
        return;
    }
    let chainID = requireEnv("ROOT_CHAIN_ID");
    let cmd = `ETHERSCAN_API_KEY=${key} forge verify-contract ${contractAddr} ${contract} --chain-id ${chainID}`;
    if (args != null) {
        cmd += ` --constructor-args $(cast abi-encode ${args})`
    }
    const { stdout, stderr } = await exec(cmd);
    if (stderr != "") {
        throw(stderr);
    }
    console.log(stdout);
}