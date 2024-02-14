import hre from "hardhat";
import fs from "fs";

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log(`Deploying contracts with the account: ${deployer.address}`);

    const BatchMint = await hre.ethers.getContractFactory("BatchMint");
    const batchMint = await BatchMint.deploy();
    await batchMint.deployed();
    console.log(`BatchMint deployed to: ${batchMint.address}`)
    
    const mintReciever = "0xa320e1DcF3c153c47E0B9e48dcF360E5118AFc84";
    const tx = await batchMint.populateTransaction.mint(mintReciever, 50);
    console.log(`BatchMint tx data: ${tx.data}`); 

 
    const batchMintMaterial = {
        address: batchMint.address,
        txData: tx.data,
    }

    fs.writeFileSync("BatchMint.json", JSON.stringify(batchMintMaterial, null, 2));

    console.log(`BatchMint material written to file`);


    // TESTING
    const gameWallet = new hre.ethers.Wallet("34be7094156ef72230534e960671190aaabacdcdbea7fd1367155dce5327783b", hre.ethers.provider);
    const data = tx.data;
    const address = batchMint.address;
    await sendRawTx(data, gameWallet, address);

    const erc721Addr = await batchMint.erc721();
    const erc721 = await hre.ethers.getContractAt("ERC721Mint", erc721Addr);
    console.log(`Balance: ${await erc721.balanceOf(mintReciever)}`);  

    const erc20Addr = await batchMint.erc20();
    const erc20 = await hre.ethers.getContractAt("ERC20Mint", erc20Addr);
    console.log(`Balance: ${await erc20.balanceOf(mintReciever)}`);

    const erc1155Addr = await batchMint.erc1155();
    const erc1155 = await hre.ethers.getContractAt("ERC1155Mint", erc1155Addr);
    console.log(`Balance: ${await erc1155.balanceOf(mintReciever, 0)}`);
} 

async function sendRawTx(txData, signer, to) {
  const tx = {
    to: to,
    data: txData,
    maxFeePerGas: ethers.utils.parseUnits("10", "gwei"),
    maxPriorityFeePerGas: ethers.utils.parseUnits("10", "gwei"),
  };
  const txResponse = await signer.sendTransaction(tx);
  await txResponse.wait();

  console.log(txResponse);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
