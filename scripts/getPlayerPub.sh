#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')
export SYSTEM_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[0].address')

export OTHER_PLAYER_ADDRESS=0xe29882a1fcba1e7e10cad46212257fea5c752a4f9b1b1ec683c503a2cf5c8a;
export OTHER_PLAYER_PK=0x14d6672dcb4b77ca36a887e9a11cd9d637d5012468175829e9c6e770c61642;
# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>
sozo call --world $WORLD_ADDRESS $SYSTEM_ADDRESS getPlayerPub -c $OTHER_PLAYER_ADDRESS
