
# Forks

This directory contains submodules pointing at repositories maintained by Immutable as forks of other smart contract projects. The `contracts` folders of these projects will be extracted by `yarn build` and merged into the main `contracts` folder.  

To add a new fork, first add it into the `forks` folder as a git submodule. Then, add the configuration for the fork into `forks.json` file. 

## Dependency Management

If the forked repository has dependencies for their smart contracts, add them to the `dependencies` array.  