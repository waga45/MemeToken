#!/bin/bash
source ../.env
forge create src/MemeSunToken.sol:MemeSunToken \
    --rpc-url ${DEV_GANACHE_URL}:${DEV_GANACHE_PORT} \
    --private-key ${DEV_GANACHE_PK} \
    --constructor-args "MemeSun" "MST" 1000000000000000000000000 \
    # --broadcast \