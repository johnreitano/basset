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
    build/bassetd collect-gentxs
fi
# nohup ignite chain serve --verbose >basset.out 2>&1 </dev/null &
nohup build/bassetd start >basset.out 2>&1 </dev/null &
sleep 2
echo "Started validator node ${MONIKER} with index ${INDEX} and id ${build/bassetd tendermint show-node-id /}"
