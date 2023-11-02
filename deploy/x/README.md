# Asset Contract Deployment

How to deploy the Asset contract to allow minting on Immutable X.

1. Install project dependencies:

    ```shell
    yarn install
    ```

2. Make a copy of `.env.examples` and rename the copy to `.env`:

    ```shell
    cp .env.example .env
    ```

3. Update the environment variables in `.env`. You will need the following:

    - [An Etherscan API key](https://docs.etherscan.io/getting-started/viewing-api-usage-statistics).
    - [Alchemy API keys for Sepolia and Mainnet](https://docs.alchemy.com/docs/alchemy-quickstart-guide#1key-create-an-alchemy-key).
    - Private key for a wallet with enough ETH to deploy the contract.

4. Generate contract artifacts

    ```shell
    yarn compile
    ```

5. Deploy the Asset contract

    ```shell
    yarn hardhat deploy:x:asset --network sepolia --name "<contract_name>" --symbol <symbol>
    ```

The deploy task will deploy the contract to the specified network, wait 5 mins to allow time for the contract to deploy, then verify the contract.
