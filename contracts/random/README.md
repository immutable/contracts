# Random Number Generation

Immutable has thoroughly investigated on-chain random number generation and use of off-chain random 
providers such as Supra and Chainlink. To create a secure on-chain random source requires an off-chain service to inteact with the chain regularly. At present, there is not sufficient demand for on-chain random for Immutable to invest in creating such a service. The source code, tests, and threat model from the investigation are contained in the [random2 branch](https://github.com/immutable/contracts/tree/random2).
In particular, teams considering using on-chain random number generation should read the [threat model document](https://github.com/immutable/contracts/blob/random2/audits/random/202403-threat-model-random.md) as this describes in detail how on-chain randon number generation can be used securely.

