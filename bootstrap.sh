#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Use pipefail to cause a pipeline to produce a failure return code if any command fails
set -o pipefail

# Define the paths to your Node.js files
file1="scripts/DeploySeaport.ts"
file2="scripts/AwsSqs.js"

# Define the number of times you want to call the Node.js files
num_iterations=6

# Loop through the iterations
for ((i=1; i<=$num_iterations; i++))
do
    echo "Iteration $i:"

    # Call the first Node.js file
    npx hardhat run "$file1" --network devnet || exit 1

    # Call the second Node.js file
    node "$file2" ./orders01.json || exit 1

    echo "Iteration $i completed."
    echo ""
done

exit 0