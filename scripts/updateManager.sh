set -euo pipefail
pushd $(dirname "$0")/..

export RPC_URL="http://localhost:5050";

export WORLD_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.world.address')
export SYSTEM_ADDRESS=$(cat ./manifests/dev/manifest.json | jq -r '.contracts[0].address')

export OWNER_ADDRESS=0xb3ff441a68610b30fd5e2abbf3a1548eb6ba6f3559f2862bf2dc757e5828ca;
export OWNER_PK=0x2bbf4f9fd0bbb2e60b0316c1fe0b76cf7a4d0198bd493ced9b8df2a3a24d68a;

#player address
export OTHER_PLAYER_ADDRESS=0xe29882a1fcba1e7e10cad46212257fea5c752a4f9b1b1ec683c503a2cf5c8a;
export OTHER_PLAYER_PK=0x14d6672dcb4b77ca36a887e9a11cd9d637d5012468175829e9c6e770c61642;

sozo execute --world $WORLD_ADDRESS $SYSTEM_ADDRESS updateSystemManager -c $OWNER_ADDRESS --rpc-url $RPC_URL --account-address $OWNER_ADDRESS --private-key $OWNER_PK --wait
echo "Update new system manager success."