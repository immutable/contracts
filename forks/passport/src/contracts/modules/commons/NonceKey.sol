
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

library NonceKey {
  // Randomly generated to avoid collisions, with:
  // xxd -len 32 -plain -cols 32 /dev/urandom
  bytes32 internal constant NONCE_KEY = bytes32(0xc40e2218089ef03fc40794d84d38778f688da53b98c9236b084936bfafc9a601);
}
