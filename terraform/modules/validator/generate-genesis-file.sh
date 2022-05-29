#!/usr/bin/env bash

set -x
set -e

cd ~/basset
THIS_NODE_ID=$(build/bassetd tendermint show-node-id)
for f in ~/.basset/config/gentx/gentx-*.json; do
    base=$(basename ${f})
    if [[ "${base}" != "gentx-${THIS_NODE_ID}.json" ]]; then
        ADDRESS=$(cat ${f} | jq -r '.body.messages[0].delegator_address')
        AMOUNT=$(cat ${f} | jq -r '.body.messages[0].value.amount')
        DENOM=$(cat ${f} | jq -r '.body.messages[0].value.denom')
        build/bassetd add-genesis-account ${ADDRESS} ${AMOUNT}${DENOM}
    fi
done
build/bassetd collect-gentxs
