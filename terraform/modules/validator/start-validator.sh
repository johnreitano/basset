#!/usr/bin/env bash

set -x
set -e

INDEX=$1

if [[ "${INDEX}" = "0" ]]; then
    MONIKER="red"
elif [[ "${INDEX}" = "1" ]]; then
    MONIKER="blue"
else
    MONIKER="green"
fi
echo MONIKER=$MONIKER

cd ~/basset
if [[ "${INDEX}" = "0" ]]; then
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
fi
# nohup ignite chain serve --verbose >basset.out 2>&1 </dev/null &
nohup build/bassetd start >basset.out 2>&1 </dev/null &
sleep 2
echo "Started validator node ${MONIKER} with index ${INDEX} and id ${build/bassetd tendermint show-node-id /}"
