# Copyright (c) Immutable Pty Ltd 2018 - 2023
# Generates WalletProxy bytecode that is stored in Wallet.sol
solc --strict-assembly src/contracts/WalletProxy.yul --optimize --bin --optimize-runs=1000
