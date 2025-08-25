#!/bin/bash
FUNCTION_TO_EXECUTE='executeUpgradeToV2()'
STAKEHOLDER_TYPE=ANY
script=script/staking/UpgradeToWIMXV2.t.sol:UpgradeToWIMXV2
# Set-up variables and execute forge
source $(dirname "$0")/common.sh


