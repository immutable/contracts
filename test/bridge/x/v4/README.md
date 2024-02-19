# Test Plan for Starkex Registration V4 contracts

## [RegistrationV4.t.sol](./RegistrationV4.t.sol)

Initialize testing:

| Test name                       | Description                                                | Happy Case | Implemented |
|---------------------------------|------------------------------------------------------------|------------|-------------|
| testGetVersion                  | Checks if the tests are using the correct starkex version. | Yes        | Yes         |


Operational tests:

| Test name                                                      | Description                                                                                                                                                                               | Happy Case | Implemented |
|----------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------|-------------|
| testCompleteWithdrawalAll_WhenUserIsRegistered                 | Test path where user can claim 2 withdrawals that were prepared using different ownerKeys (ethKey and starkKey) all at once for a registered user.                                        | Yes        | Yes         |
| testShouldFailWithdrawalAll_WhenUserIsNotRegistered            | Test path that reverts if user tries to claim 2 withdrawals that were prepared using different ownerKeys (ethKey and starkKey) for an unregistered starkKey.                              | No         | Yes         |
| testShouldFailWithdrawalAll_WhenUserDoesNotHaveFundsToWithdraw | Test path that reverts if user tries to claim 2 withdrawals that were never prepared.                                                                                                     | No         | Yes         |
| testCompleteWithdrawalV4_WhenUserIsNotRegistered               | Test path where user tries to claim a withdrawal that were prepared using their ethKey as their ownerKey unregistered user starkKey.                                                      | Yes        | Yes         |
| testRegisterAndCompleteWithdrawalAll_WhenUserIsNotRegistered   | Test path where user can perform on-chain registration and claim 2 withdrawals that were prepared using different ownerKeys (ethKey and starkKey) all at once for an unregistered user.   | Yes        | Yes         |
| testRegister_WhenUserIsNotRegistered                           | Test path where user can perform on-chain registration for an unregistered user.                                                                                                          | Yes        | Yes         |
| testRegisterAndCompleteWithdrawalAll_WhenUserIsRegistered      | Test path where user can perform on-chain registration and claim 2 withdrawals that were prepared using different ownerKeys (ethKey and starkKey) all at once for a registered user.      | Yes        | Yes         |
| testRegisterAndWithdrawalNFT_WhenUserIsNotRegistered           | Test path where user can perform on-chain registration and claim an NFT withdrawal all at once for an unregistered user.                                                                  | Yes        | Yes         |
| testRegisterAndWithdrawalNFT_WhenUserIsRegistered              | Test path where user can perform on-chain registration and claim an NFT withdrawal all at once for a registered user.                                                                     | Yes        | Yes         |
| testRegisterWithdrawalAndMintNFT_WhenUserIsNotRegistered       | Test path where user can perform on-chain registration, claim an NFT Minting and withdrawal all at once for an unregistered user.                                                         | Yes        | Yes         |

