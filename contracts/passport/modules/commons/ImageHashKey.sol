// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

library ImageHashKey {
  // Randomly generated to avoid collisions, with:
  // xxd -len 32 -plain -cols 32 /dev/urandom
  bytes32 internal constant IMAGE_HASH_KEY = bytes32(0xad348b32c79cd46ad46d61aede26d38affaee58f9a122f91eb271e08720464bf);
}
