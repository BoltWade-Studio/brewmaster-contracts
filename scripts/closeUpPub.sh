#!/bin/bash
set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')
export SYSTEM_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[0].address')

# owner address
export OWNER_ADDRESS=0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca;
export OWNER_PK=0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a;

#player address
export OTHER_PLAYER_ADDRESS=0xe29882a1fcba1e7e10cad46212257fea5c752a4f9b1b1ec683c503a2cf5c8a;
export OTHER_PLAYER_PK=0x14d6672dcb4b77ca36a887e9a11cd9d637d5012468175829e9c6e770c61642;

export TREASURY=120;
export POINTS=1000;
export CLOSED_AT=1724834939;

export SIGNATURE_R=0x4bcb4df7a57e203e736e9bebab10a389aa8557f2f5e5d2b8e67bcb07fad529d;
export SIGNATURE_S=0x3be8fcda54ceb278134c257d2ac3c13f49bb34ab45312b8d7729d11404d8dd2;

# sozo execute --world <WORLD_ADDRESS> <CONTRACT> <ENTRYPOINT>
sozo execute --world $WORLD_ADDRESS $SYSTEM_ADDRESS closingUpPub -c $TREASURY,0,$POINTS,0,$CLOSED_AT,2,$SIGNATURE_R,$SIGNATURE_S --account-address $OTHER_PLAYER_ADDRESS --private-key $OTHER_PLAYER_PK --wait

echo "Closing up pub success with player $OTHER_PLAYER_ADDRESS."