# Random Number Generation

This directory contains contracts that provide random number generation capability using on-chain and off-chain sources. 

The reasons for using these contracts are that:

* Enables you to leverage a random number generation system designed by Immutable's cryptographers.
* Allows you to build your game against an API that won't change.
* The quality of the random numbers generated will improve as new capabilities are added to the platform. That is, the migration from ```block.hash``` to ```block.prevrandao``` when the BFT fork occurs will be seemless.
* For off-chain randomness, allows you to leverage the random number provider that Immutable has agreements with.

# Status

Contract audits:

| Description               | Date             |Version Audited  | Link to Report |
|---------------------------|------------------|-----------------|----------------|
| Not audited               | -                | -               | -              |

Deployments:

| Location                  | Version Deployed | Address |
|---------------------------|------------------|---------|
| Immutable zkEVM Testnet   | Not deployed     | -       |
| Immutable zkEVM Mainnet   | Not deployed     | -       |

## Architecture

The Random Number Generation system on the immutable platform is shown in the diagram below.

![Random number genration](./random-architecture.png)

Game contracts extend ```RandomValues.sol```. This contract interacts with the ```RandomSeedProvider.sol``` contract to request and retreive random seed values. 

There is one ```RandomSeedProvider.sol``` contract deployed per chain. Each game has its own instance of ```RandomValues.sol``` as this contract is integrated directly into the game contract. 

The ```RandomSeedProvider.sol``` operates behind a transparent proxy, ```TransparentUpgradeProxy.sol``` that is controlled by ```ProxyAdmin.sol```. Using an upgradeable pattern allows the random manager contract to be upgraded to extend its feature set and resolve issues. 

The ```RandomSeedProvider.sol``` contract can be configured to use an off-chain random number source. This source is accessed via the ```IOffchainRandomSource.sol``` interface. To allow the flexibility to switch between off-chain random sources, there is an adaptor contract between the offchain random source contract and the random seed provider.

The architecture diagram shows a ChainLink VRF source and a Supra VRF source. This is purely to show the possibility of integrating with one off-chain service and then, at a later point choosing to switch to an alternative off-chain source. At present, there is no agreement to use any specific off-chain source.



## Process of Requesting a Random Number

The process for requesting a random number is shown below. Players do actions requiring a random number. They purchase, or commit to the random value, which is later revealed. 

![Random number genration](./random-sequence.png)

The steps are:

* The game contract calls ```_requestRandomValueCreation```.
The ```_requestRandomValueCreation``` returns a value ```_randomRequestId```. This value is supplied later to fetch the random value once it has been generated. The function ```_requestRandomValueCreation``` executes a call to the ```RandomSeedProvider``` contract requesting a seed value be produced.
* The game contract calls ```_isRandomValueReady```, passing in the ```_randomRequestId```. The returns ```true``` if the value is ready to be returned.
* The game contract calls ```_fetchRandom```, passing in the ```_randomRequestId```. The random seed is returned to the RandomValue.sol, which then customises the value prior returning it to the game.


# Notes

Sequence diagram source [here](https://sequencediagram.org/index.html#initialData=title%20Random%20Number%20Generation%0A%0Aparticipant%20%22Game.sol%22%20as%20Game%0Aparticipant%20%22RandomValue.sol%22%20as%20RV%0Aparticipant%20%22RandomSeedProvider.sol%22%20as%20RM%0A%0Agroup%20Player%20purchases%20a%20random%20action%0AGame-%3ERV%3A%20_requestRandomValueCreation()%0ARV-%3ERM%3A%20requestRandomSeed()%0ARV%3C--RM%3A%20_seedRequestId%2C%20_source%0AGame%3C--RV%3A%20_randomRequestId%0Aend%0A%0Anote%20over%20Game%2CRM%3AWait%20for%20a%20block%20to%20be%20produced%20or%20an%20off-chain%20random%20to%20be%20delivered.%0A%0Agroup%20Check%20random%20value%20is%20ready%0AGame-%3ERV%3A%20isRandomValueReady(_randomRequestId)%0ARV-%3ERM%3A%20isRandomSeedReady(%5Cn_seedRequestId%2C%20_source)%0ARV%3C--RM%3A%20true%0AGame%3C--RV%3A%20true%0Aend%0A%0Agroup%20Game%20delivers%20%2F%20reveals%20random%20action%0AGame-%3ERV%3A%20fetchRandom(_randomRequestId)%0ARV-%3ERM%3A%20getRandomSeed(%5Cn_seedRequestId%2C%20_source)%0ARV%3C--RM%3A%20_randomSeed%0ARV-%3ERV%3A%20Personalise%20random%20number%20%5Cnby%20game%2C%20player%2C%20and%20request%5Cnnumber.%0AGame%3C--RV%3A%20_randomValue%0Aend%0A%0A%0A%0A%0A%0A).