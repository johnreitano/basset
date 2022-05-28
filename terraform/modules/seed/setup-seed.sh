#!/usr/bin/env bash

set -x
set -e

INDEX=$1

SEED_IPS_STR=$2
SEED_IPS=(${SEED_IPS_STR//,/ })
SEED_P2P_KEYS=(9038832904699724f0b62188e088a86acb629fad de77ff9811178b9b14507dae3cde3ffa0df68130 192fd886732afb466690f1e098ddd62cfe7a63e4)

VALIDATOR_IPS_STR=$3
VALIDATOR_IPS=(${VALIDATOR_IPS_STR//,/ })
VALIDATOR_P2P_KEYS=(7b23bfaa390d84699812fb709957a9222a7eb519 547217a2c7449d7c6f779e07b011aa27e61673fc 7aaf162f245915711940148fe5d0206e2b456457)

P2P_EXTERNAL_ADDRESS="tcp://${SEED_IPS[$INDEX]}:26656"

P2P_PERSISTENT_PEERS=""
N=${#VALIDATOR_IPS[@]}
N_MINUS_1=$(($N - 1))
for i in $(seq 0 $N_MINUS_1); do
    P2P_PERSISTENT_PEERS="${P2P_PERSISTENT_PEERS}${VALIDATOR_P2P_KEYS[$i]}@${VALIDATOR_IPS[$i]}:26656,"
done

if [[ "${INDEX}" = "0" ]]; then
    MONIKER="black"
elif [[ "${INDEX}" = "1" ]]; then
    MONIKER="white"
else
    MONIKER="gray"
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

cp terraform/node_key_seed_${INDEX}.json ~/.basset/config/node_key.json
cp terraform/genesis.json ~/.basset/config/genesis.json

dasel put string -f ~/.basset/config/config.toml -p toml ".p2p.external_address" "${P2P_EXTERNAL_ADDRESS}"
dasel put string -f ~/.basset/config/config.toml -p toml ".p2p.persistent_peers" "${P2P_PERSISTENT_PEERS}"

# nohup ignite chain serve --verbose >basset.out 2>&1 </dev/null &
nohup build/bassetd start >basset.out 2>&1 </dev/null &
sleep 2
echo Started seed node ${INDEX} with id $(build/bassetd tendermint show-node-id)
