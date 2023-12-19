# Random Number Generation

This directory contains contracts that provide on-chain random number generation.

## Architecture

The Random Number Generation system on the immutable platform is shown in the diagram below.

![Random number genration](./random-architecture.png)

Game contracts extend ```RandomValues.sol```. This contract interacts with the ```RandomManager.sol``` contract to request and retreive random numbers. 

There is one ```RandomManager.sol``` contract deployed per chain. Each game has its own instance of ```RandomValues.sol``` as this contract is integrated directly into the game contract. 

The ```RandomManager.sol``` operates behind a transparent proxy, ```TransparentUpgradeProxy.sol``` that is controlled by ```ProxyAdmin.sol```. Using an upgradeable pattern allows the random manager contract to be upgraded to extend its feature set and resolve issues. 

The ```RandomManager.sol``` contract can be configured to use an off-chain random number source. This source is accessed via the ```IOffchainRandomSource.sol``` interface. To allow the flexibility to switch off-chain random sources, there is an adaptor contract between the offchain random source contract and the random manager. 

Initially, no offchain random source will be used. As such, the ```RandomSourceAdaptor.sol``` contract has not been implemented at this time.


## Random Number Request and Retreival Flow
