import hre, { ethers } from "hardhat";
import fs from "fs";
import { Wallet, ethers } from "ethers";

async function readL1KeysFromFile(filePath: string): Promise<string[]> {
  return new Promise((resolve, reject) => {
    fs.readFile(filePath, "utf8", (err, data) => {
      if (err) {
        reject(err);
      } else {
        try {
          const l1Keys: string[] = JSON.parse(data);
          resolve(l1Keys);
        } catch (error) {
          reject(error);
        }
      }
    });
  });
}

export async function mainBalance() {
  // Get chainId
  let connection = {
    url : "https://rpc.dev.immutable.com",
    headers: {
      "x-api-key": "b8vqNYMRmN2XH5Jadw27l9ghGby3iIRv72xuA83Q",
      'Content-Type': 'application/json; charset=utf-8',
    }
  }
  
  const provider = new ethers.providers.JsonRpcProvider(connection);
  const chainId = (await provider.getNetwork()).chainId;
  console.log(`CHAIN ID ${chainId}`);

  // Get private keys
  const l1Keys = await readL1KeysFromFile("l1_keys.json");
  const l1Wallets = l1Keys.map((key) => new Wallet(key, provider));
  const L1PubKeys = l1Wallets.map((wallet) => wallet.address);


  // Define X (the threshold balance)
  const thresholdBalance = ethers.utils.parseEther("250000"); // Adjust this value as needed

  const lowBalances : any[] = [];
  // Check balances
  const balanceChecks = l1Wallets.map(async (wallet) => {
    const balance = await provider.getBalance(wallet.address);
    if (balance.lt(thresholdBalance)) {
      lowBalances.push(wallet.address);
    }
  });

  await Promise.all(balanceChecks);

  console.log(`Found ${lowBalances.length} wallets with low balances`);
  if (lowBalances.length === 0) {
    console.log("No wallets with low balances found");
    return;
  }


  const funderWallet = new Wallet("1f6f17db77bf966ae1bb2fa0fc32868a3d5913f1b931f085ffe6522d5966f8d3", provider);
  let funderNonce = await funderWallet.getTransactionCount();
  console.log(`Funding wallets starting from ${funderNonce} to ${funderNonce + lowBalances.length}`)
  const Transfers = l1Wallets.map(async (wallet) => {
      const nonce = funderNonce + L1PubKeys.indexOf(wallet.address);
      const tx = {
        to: wallet.address,
        value: thresholdBalance,
        maxFeePerGas: ethers.utils.parseUnits("20", "gwei"),
        maxPriorityFeePerGas: ethers.utils.parseUnits("20", "gwei"),
        type: 2,
        nonce: nonce,
      }

      await funderWallet.sendTransaction(tx);
  });

  await Promise.all(Transfers);
  
  // let i = 0;
  // for (const address of lowBalances) {
  //   const tx = {
  //     to: address,
  //     value: thresholdBalance,
  //     maxFeePerGas: ethers.utils.parseUnits("20", "gwei"),
  //     maxPriorityFeePerGas: ethers.utils.parseUnits("20", "gwei"),
  //     type: 2,
  //     nonce: funderNonce,
  //   }
  //   await funderWallet.sendTransaction(tx);
  //   funderNonce++;
  //   i++;
  //   console.log(`${i}/${lowBalances.length} funded`);
  // }
}

mainBalance()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
