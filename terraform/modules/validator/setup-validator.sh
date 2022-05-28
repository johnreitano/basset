#!/usr/bin/env bash

set -x
set -e

INDEX=$1

VALIDATOR_IPS_STR=$2
VALIDATOR_IPS=(${VALIDATOR_IPS_STR//,/ })
VALIDATOR_P2P_KEYS=(7b23bfaa390d84699812fb709957a9222a7eb519 547217a2c7449d7c6f779e07b011aa27e61673fc 7aaf162f245915711940148fe5d0206e2b456457)

P2P_EXTERNAL_ADDRESS="tcp://${VALIDATOR_IPS[$INDEX]}:26656"

P2P_PERSISTENT_PEERS=""
N=${#VALIDATOR_IPS[@]}
N_MINUS_1=$(($N - 1))
for i in $(seq 0 $N_MINUS_1); do
    if [[ "${i}" != "${INDEX}" ]]; then
        P2P_PERSISTENT_PEERS="${P2P_PERSISTENT_PEERS}${VALIDATOR_P2P_KEYS[$i]}@${VALIDATOR_IPS[$i]}:26656,"
    fi
done

if [[ "${INDEX}" = "0" ]]; then
    MONIKER="red"
elif [[ "${INDEX}" = "1" ]]; then
    MONIKER="blue"
else
    MONIKER="green"
fi

echo MONIKER=$MONIKER
echo P2P_EXTERNAL_ADDRESS=$P2P_EXTERNAL_ADDRESS
echo P2P_PERSISTENT_PEERS=$P2P_PERSISTENT_PEERS

ulimit -n 4096 # set maximum number of open files to 4096

if [[ -z "$(which make)" ]]; then
    sudo apt install -y make
fi
if [[ -z "$(which go)" ]]; then
    sudo snap install go --classic
fi
if [[ -z "$(which dasel)" ]]; then
    sudo wget -qO /usr/local/bin/dasel https://github.com/TomWright/dasel/releases/latest/download/dasel_linux_amd64
    sudo chmod a+x /usr/local/bin/dasel
fi
if [[ -z "$(which ignite)" ]]; then
    sudo curl https://get.ignite.com/cli! | sudo bash
fi

# pkill ignite || : # if failed, ignite wasn't running
pkill bassetd || : # if failed, ignite wasn't running
sleep 1
cd ~/basset
# ignite chain build --output build
make build-basset-linux

rm -rf ~/.basset
build/bassetd init $MONIKER --chain-id basset-test-1

# add some keys
yes | build/bassetd keys delete alice --keyring-backend test 2>/dev/null || :
build/bassetd keys add alice --keyring-backend test --recover <<EOF
gun quick banner word mutual pet sort run illness behind pull stock crazy talk actor icon help gym young census decorate swamp two plunge
EOF
yes | build/bassetd keys delete bob --keyring-backend test 2>/dev/null || :
build/bassetd keys add bob --keyring-backend test --recover <<EOF
mule multiply combine frown aim window top weekend frown cancel turn token canoe thumb attitude flame execute purpose chest design winner enable coconut retire
EOF
yes | build/bassetd keys delete sandra --keyring-backend test 2>/dev/null || :
build/bassetd keys add sandra --keyring-backend test --recover <<EOF
business bless fuel joy lady volcano odor tribe virus have effort rate mouse disease general view mention evoke lend expect frozen trend shrimp flavor
EOF
yes | build/bassetd keys delete preston --keyring-backend test 2>/dev/null || :
build/bassetd keys add preston --keyring-backend test --recover <<EOF
chase prepare swift battle help test people disease uphold camp manual kitten skill burger much tool gap fan rival assist usual brown attack never
EOF

cp terraform/node_key_validator_${INDEX}.json ~/.basset/config/node_key.json
if [[ "${INDEX}" = "0" ]]; then
    build/bassetd add-genesis-account $(build/bassetd keys show alice -a --keyring-backend test) 100000000000stake
    # build/bassetd export > ~/genesis_export.json
    build/bassetd gentx alice 100000000stake --chain-id basset-test-1 --moniker="genesis" --keyring-backend test
    build/bassetd collect-gentxs
else
    cp terraform/genesis.json ~/.basset/config/genesis.json
    sleep 30 # give primary validator node head start validating
fi

dasel put string -f ~/.basset/config/config.toml -p toml ".p2p.external_address" "${P2P_EXTERNAL_ADDRESS}"
dasel put string -f ~/.basset/config/config.toml -p toml ".p2p.persistent_peers" "${P2P_PERSISTENT_PEERS}"

echo Validator node ${INDEX} has id $(build/bassetd tendermint show-node-id)

# nohup ignite chain serve --verbose >basset.out 2>&1 </dev/null &
nohup build/bassetd start >basset.out 2>&1 </dev/null &
sleep 2