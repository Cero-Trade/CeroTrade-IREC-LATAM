#!/bin/bash

tokenId=$1
name=$2
symbol=$3
logo=$4

# Register token
canisterResult=$(dfx canister call agent registerToken "(\"$tokenId\", \"$name\", \"$symbol\", \"$logo\")")

# Extrae el canisterId de la salida
canisterId=$(echo $canisterResult | grep -o 'canisterId = principal "[^"]*"' | awk '{print $4}' | tr -d '"')

assetMetadata=$(node scripts/extract-asset-metadata "$canisterResult")

# update wasm
dfx canister install $canisterId --wasm .dfx/local/canisters/token/token.wasm --mode upgrade --argument "(record { name = \"$name\"; symbol = \"$symbol\"; logo = \"$logo\"; assetMetadata = $assetMetadata })"

# Initialize canister
dfx canister call $canisterId admin_init
