import { deployImmutableContracts } from "../test/seaport/utils/deploy-immutable-contracts";
import hre from "hardhat";
import { getItemETH } from "../test/seaport/utils/encoding";
import { createOrder, generateSip7Signature } from "../test/seaport/utils/order";
import { getTestItem721 } from "../test/seaport/utils/erc721";
import { Wallet } from "ethers";
import fs from "fs";
import { decodeError } from 'ethers-decode-error'

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

async function deployContracts(serverSignerAddr: string) {
  console.log(`Deploying contracts`);
  // Deploy Seaport
  const { immutableSeaport, immutableSignedZone, conduitKey, conduitAddress } =
    await deployImmutableContracts(serverSignerAddr);
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
  fs.writeFileSync("loadtest_addresses.json", JSON.stringify(addresses, null, 2));

  return { immutableSeaport, immutableSignedZone, conduitKey, conduitAddress, erc721Mint };
}

async function loadContracts() {
  console.log(`Loading contracts`);
  // const immutableSeaport = await hre.ethers.getContractAt("ImmutableSeaport", "0xb1456aF8cFf6869B8558939616E35F3fC031A48a");
  // const immutableSignedZone = await hre.ethers.getContractAt("ImmutableSignedZone", "0x95e47a59667cc902b9d1de9c8831e63174de227c");
  // const erc721Mint = await hre.ethers.getContractAt("ERC721Mint", "0xC74534cc9207457F11078a0Fe3241C4f01D0FaF8");
  // const conduitKey = "0xf755537198510B674AF40e1ca509d85A1BC3DC8a000000000000000000000000";
  const addresses = JSON.parse(fs.readFileSync("loadtest_addresses.json", "utf8"));
  console.log(`Loaded addresses ${JSON.stringify(addresses, null, 2)}`);
  const immutableSeaport = await hre.ethers.getContractAt("ImmutableSeaport", addresses.immutableSeaport);
  const immutableSignedZone = await hre.ethers.getContractAt("ImmutableSignedZone", addresses.immutableSignedZone);
  const erc721Mint = await hre.ethers.getContractAt("ERC721Mint", addresses.erc721Mint);
  const conduitKey = addresses.conduitKey;
  const conduitAddress = addresses.conduitAddress;
  return { immutableSeaport, immutableSignedZone, conduitKey, conduitAddress, erc721Mint };
}

export async function main() {
  // Get chainId
  const chainId = (await ethers.provider.getNetwork()).chainId;
  console.log(`CHAIN ID ${chainId}`);

  // Get private keys
  const l1Keys = await readL1KeysFromFile("l1_keys.json");
  const l1Wallets = l1Keys.map((key) => new Wallet(key, hre.ethers.provider));

  // Get accounts
  const [conduit, serverSigner, gameWallet] = await hre.ethers.getSigners();

  // // Deploy Contracts
  // const {immutableSeaport, immutableSignedZone, conduitKey, conduitAddress, erc721Mint} = await deployContracts(serverSigner.address);
  // Approve
  // const approveTx = await erc721Mint.connect(gameWallet).setApprovalForAll(conduitAddress, true);
  // await approveTx.wait();
  // console.log(`Approved ${conduitAddress} for all NFTs`)

  // Load Contracts
  const { immutableSeaport, immutableSignedZone, conduitKey, conduitAddress, erc721Mint } = await loadContracts();

  if (!(await erc721Mint.isApprovedForAll(gameWallet.address, conduitAddress))) {
    throw new Error("Approval failed. Must approve conduit on token contract.");
  }

  // Get current tokenID
  const currTokenId = await erc721Mint.tokenId();
  console.log(`Current tokenId: ${currTokenId}`);

  const txCount = 40;
  const mintCount = 40000;
  const mintTxCount = mintCount / txCount;

  for (let i = 0; i < txCount; i++) {
    await erc721Mint.mint(gameWallet.address, mintTxCount);
    console.log(`${i * mintTxCount}/${mintCount}`);
  }

  while ((await erc721Mint.tokenId()) < mintCount + Number(currTokenId) - 1) {
    console.log(`Waiting for mint to complete. Current tokenId: ${await erc721Mint.tokenId()}`);
    await new Promise((resolve) => setTimeout(resolve, 10000));
  }

  const postTokenID = await erc721Mint.tokenId();

  // Get domain seperator
  const { domainSeparator } = await immutableSeaport.information();

  // Generate orders
  const buyAmount = ethers.utils.parseEther("0.0000001");
  let orders: any[] = [];
  console.log(`Generating ${mintCount} orders`);
  for (let i = Number(currTokenId); i < Number(postTokenID); i++) {
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

    // const estimation = await immutableSeaport.connect(buyer).estimateGas.fulfillAdvancedOrder(order, [], conduitKey, buyer.address, {value: buyAmount});
    // console.log(estimation)

    const txPop = await immutableSeaport
      .connect(buyer)
      .populateTransaction.fulfillAdvancedOrder(order, [], conduitKey, buyer.address, { value: buyAmount });
    orders.push({ [buyer.address]: txPop.data });
    // console.log(`Order ${i - currTokenId + 1}/${mintCount}`);

    // const txPop = await immutableSeaport.populateTransaction.fulfillAdvancedOrder(
    //   order,
    //   [],
    //   conduitKey,
    //   buyer.address,
    //   { value: buyAmount },
    // );

    // await sendRawTx(txPop.data, buyer, immutableSeaport, buyAmount);
    // const tx = await immutableSeaport.connect(buyer).fulfillAdvancedOrder(order, [], conduitKey, buyer.address, {
    //   value: buyAmount, maxFeePerGas: ethers.utils.parseUnits("10", "gwei"), maxPriorityFeePerGas: ethers.utils.parseUnits("10", "gwei")
    // });
    // await tx.wait(1);
    // if (txPop.data !== tx.data) {
    //   throw new Error("Data mismatch");
    // }
    // console.log((await ethers.provider.getTransactionReceipt(tx.hash)).status);
  }

  const fileName = "orders01.json";
  console.log(`Orders generated. Saving ${fileName}`);
  fs.writeFileSync(`${fileName}`, JSON.stringify(orders, null, 2));
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
  await txResponse.wait(1);

  console.log((await ethers.provider.getTransactionReceipt(txResponse.hash)));
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
