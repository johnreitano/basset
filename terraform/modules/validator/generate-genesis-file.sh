#!/usr/bin/env bash

set -x
set -e

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
build/bassetd init genesis --chain-id basset-test-1

build/bassetd add-genesis-account $(build/bassetd keys show alice -a --keyring-backend test) 100000000000stake
# build/bassetd export > ~/genesis_export.json
build/bassetd gentx alice 100000000stake --chain-id basset-test-1 --moniker="genesis" --keyring-backend test
build/bassetd collect-gentxs
