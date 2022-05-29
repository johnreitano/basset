#!/usr/bin/env bash

set -x
set -e

NODE_INDEX=$1
if [[ "${NODE_INDEX}" = "0" ]]; then
    MONIKER="red"
elif [[ "${NODE_INDEX}" = "1" ]]; then
    MONIKER="blue"
else
    MONIKER="green"
fi

VALIDATOR_IPS_STR=$2
VALIDATOR_IPS=(${VALIDATOR_IPS_STR//,/ })
VALIDATOR_P2P_KEYS=(7b23bfaa390d84699812fb709957a9222a7eb519 547217a2c7449d7c6f779e07b011aa27e61673fc 7aaf162f245915711940148fe5d0206e2b456457)

P2P_EXTERNAL_ADDRESS="tcp://${VALIDATOR_IPS[$NODE_INDEX]}:26656"

P2P_PERSISTENT_PEERS=""
N=${#VALIDATOR_IPS[@]}
N_MINUS_1=$(($N - 1))
for i in $(seq 0 $N_MINUS_1); do
    if [[ "${i}" != "${NODE_INDEX}" ]]; then
        P2P_PERSISTENT_PEERS="${P2P_PERSISTENT_PEERS}${VALIDATOR_P2P_KEYS[$i]}@${VALIDATOR_IPS[$i]}:26656,"
    fi
done

rm -rf ~/.basset
build/bassetd init $MONIKER --chain-id basset-test-1
cp terraform/node_key_validator_${NODE_INDEX}.json ~/.basset/config/node_key.json
dasel put string -f ~/.basset/config/config.toml -p toml ".p2p.external_address" "${P2P_EXTERNAL_ADDRESS}"
dasel put string -f ~/.basset/config/config.toml -p toml ".p2p.persistent_peers" "${P2P_PERSISTENT_PEERS}"
