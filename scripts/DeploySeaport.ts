import { deployImmutableContracts } from "../test/seaport/utils/deploy-immutable-contracts";
import hre from "hardhat";
import { getItemETH } from "../test/seaport/utils/encoding";
import { createOrder, generateSip7Signature } from "../test/seaport/utils/order";
import { getTestItem721 } from "../test/seaport/utils/erc721";
import { Wallet } from "ethers";
import fs from "fs";
import { send } from "process";

function readL1KeysFromFile(filePath: string): Promise<string[]> {
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

export async function main() {
  // Get chainId
  const chainId = (await ethers.provider.getNetwork()).chainId;
  console.log(`CHAIN ID ${chainId}`);

  // Get private keys
  const l1Keys = await readL1KeysFromFile("l1_keys.json");
  const l1Wallets = l1Keys.map((key) => new Wallet(key, hre.ethers.provider));

  // Get accountse
  const [conduit, serverSigner, gameWallet] = await hre.ethers.getSigners();

  // Deploy Seaport
  const { immutableSeaport, immutableSignedZone, conduitKey, conduitAddress } = await deployImmutableContracts(
    serverSigner.address,
  );
  console.log(`Deployed Seaport at ${immutableSeaport.address}`);

  // Deploy ERC721
  const ERC721Mint = await hre.ethers.getContractFactory("ERC721Mint");
  const erc721Mint = await ERC721Mint.deploy();
  await erc721Mint.deployed();
  console.log(`Deployed ERC721 at ${erc721Mint.address}`);

  // Save addresses
  console.log(`Writing addresses to file`);
  const addresses = {
    immutableSeaport: immutableSeaport.address,
    immutableSignedZone: immutableSignedZone.address,
    conduitAddress: conduitAddress,
    erc721Mint: erc721Mint.address,
    conduitKey: conduitKey,
  };
  fs.writeFileSync("dev_addresses.json", JSON.stringify(addresses, null, 2));

  // Mint
  // 3600/2 = 1800 blocks
  // 80 trades per block
  // Total NFT mints = 1800 * 80 = 144000 (make this more to ensure we hit the target)
  const mintCount = 10000;
  const txCount = 10;
  const mintTxCount = mintCount/txCount; // Max mints per tx?

  console.log(`Minting ${mintCount} NFTs from tokenId ${await erc721Mint.tokenId()}`);
  for (let i = 1; i <= txCount; i++) {
    await erc721Mint.mint(gameWallet.address, mintTxCount);
    // await mintTx.wait();
    console.log(`${i*mintTxCount}/${mintCount}`)
  }

  while ((await erc721Mint.tokenId()) < mintCount) {
    console.log(`Waiting for mint to complete. Current tokenId: ${await erc721Mint.tokenId()}`);
    await new Promise((resolve) => setTimeout(resolve, 10000));
  }
  console.log(`Minted ${mintCount} NFTs to tokenId ${await erc721Mint.tokenId()}`);

  // Approve
  const approveTx = await erc721Mint.connect(gameWallet).setApprovalForAll(conduitAddress, true);
  await approveTx.wait();
  console.log(`Approved ${conduitAddress} for all NFTs`)

  if (!(await erc721Mint.isApprovedForAll(gameWallet.address, conduitAddress))) {
    throw new Error("Approval failed");
  }

  // Get domain seperator
  const { domainSeparator } = await immutableSeaport.information();

  // Generate orders
  const buyAmount = ethers.utils.parseEther("0.0000001");
  let orders : any[] = [];
  console.log(`Generating ${mintCount} orders`)
  for (let i = 0; i <= mintCount; i++) {
    const buyer = l1Wallets[i % l1Wallets.length];
    const order = await generateOrder(
      erc721Mint.address,
      i,
      gameWallet,
      immutableSeaport,
      immutableSignedZone,
      conduitKey,
      buyer,
      serverSigner,
      buyAmount,
      chainId,
      domainSeparator,
    );

    const tx = await immutableSeaport.populateTransaction.fulfillAdvancedOrder(order, [], conduitKey, buyer.address, {value: buyAmount});
    // await sendRawTx(tx.data, buyer, immutableSeaport, buyAmount);
    
    orders.push({[buyer.address] : tx.data});  
    console.log(`Order ${i}/${mintCount}`);
    // // const tx = await immutableSeaport.connect(buyer).fulfillAdvancedOrder(order, [], conduitKey, buyer.address, {
    // //   value: buyAmount,
    // // });
    // // await tx.wait();

  }
  // console.log(`Buyer 721 Balance: ${await erc721Mint.balanceOf(buyer.address)}`);
  console.log(`Oders generated. Saving`);
  fs.writeFileSync("orders.json", JSON.stringify(orders, null, 2));
}

async function sendRawTx(txData, signer, immutableSeaport, value) {
  const tx = {
    to: immutableSeaport.address,
    data: txData,
    maxFeePerGas: ethers.utils.parseUnits("10", "gwei"),
    maxPriorityFeePerGas: ethers.utils.parseUnits("10", "gwei"),
    value, 
  };
  const txResponse = await signer.sendTransaction(tx);
  await txResponse.wait();
}

async function generateOrder(
  erc721Addr,
  tokenId,
  seller,
  immutableSeaport,
  immutableSignedZone,
  conduitKey,
  buyer,
  immutableSigner,
  buyAmount,
  chainId,
  domainSeparator,
) {
  const offer = await getTestItem721(erc721Addr, tokenId);
  const consideration = [getItemETH(buyAmount, buyAmount, seller.address)];
  const { order, orderHash, value } = await createOrder(
    immutableSeaport,
    seller,
    immutableSignedZone,
    [offer],
    consideration,
    2, // FULL_RESTRICTED
    chainId,
    domainSeparator,
    undefined,
    undefined,
    undefined,
    conduitKey,
  );

  const extraData = await generateSip7Signature(
    consideration,
    orderHash,
    buyer.address,
    immutableSignedZone.address,
    immutableSigner,
    chainId,
  );

  // sign the orderHash with immutableSigner
  order.extraData = extraData;

  // console.log(`Generated order: ${JSON.stringify(order)}, with value: ${value}`);
  return order;
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
