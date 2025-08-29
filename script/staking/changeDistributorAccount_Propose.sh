#!/bin/bash
FUNCTION_TO_EXECUTE='proposeChangeDistributor()'
STAKEHOLDER_TYPE=ANY
script=script/staking/ChangeDistributor.t.sol:ChangeDistributor
# Set-up variables and execute forge
source $(dirname "$0")/common.sh
