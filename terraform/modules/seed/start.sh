#!/usr/bin/env bash

set -x
set -e

INDEX=$1

cd ~/basset
# nohup ignite chain serve --verbose >basset.out 2>&1 </dev/null &
nohup build/bassetd start >basset.out 2>&1 </dev/null &
