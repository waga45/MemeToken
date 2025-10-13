#!/bin/bash
source ../.env
forge script ../script/MemeSunToken.s.sol:DeployMemeSunToken \
    --rpc-url https://sepolia.infura.io/v3/${TEST_SEPOLIA_INFURA_API_KEY} \
    --private-key ${PK} \
    --optimize 1000 \
    --broadcast \
    --verify \
    --etherscan-api-key ${ETHER_SCAN} \
    -vv