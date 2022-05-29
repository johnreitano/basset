#!/usr/bin/env bash

set -x
set -e

NODE_INDEX=$1
if [[ "${NODE_INDEX}" = "0" ]]; then
    MONIKER="red"
    MNEMONIC="gun quick banner word mutual pet sort run illness behind pull stock crazy talk actor icon help gym young census decorate swamp two plunge"
elif [[ "${NODE_INDEX}" = "1" ]]; then
    MONIKER="blue"
    MNEMONIC="mule multiply combine frown aim window top weekend frown cancel turn token canoe thumb attitude flame execute purpose chest design winner enable coconut retire"
else
    MONIKER="green"
    MNEMONIC="business bless fuel joy lady volcano odor tribe virus have effort rate mouse disease general view mention evoke lend expect frozen trend shrimp flavor"
fi

# generate genesis transaction for this validator
yes | build/bassetd keys delete ${MONIKER}-key --keyring-backend test 2>/dev/null || :
echo $MNEMONIC | build/bassetd keys add ${MONIKER}-key --keyring-backend test --recover
build/bassetd add-genesis-account $(build/bassetd keys show ${MONIKER}-key -a --keyring-backend test) 100000000000stake
build/bassetd gentx ${MONIKER}-key 100000000stake --chain-id basset-test-1 --moniker=${MONIKER} --keyring-backend test
