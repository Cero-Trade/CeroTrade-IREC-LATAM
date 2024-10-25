#!/bin/bash

# Define optional modules argument
flag=$1

# Change identity to `default`
echo "====-Change identity to default and branch to develop-===="
git checkout develop
dfx identity use default

# Deploy nns canisters
if [ "$flag" = "clean" ]; then
  echo "====-Deploy nns canisters-===="
  dfx nns install
  dfx nns import

  # Deploy internet identity canister
  echo "====-Deploy internet identity canister-===="
  dfx deploy internet_identity
fi

# Generate declarations
echo "====-Generate declarations-===="
mkdir -p .dfx/local/canisters/cero_trade_project_frontend && cp assetstorage.did .dfx/local/canisters/cero_trade_project_frontend/assetstorage.did
dfx generate
cp src/declarations/users/* .dfx/local/canisters/users/
cp src/declarations/user_index/* .dfx/local/canisters/user_index/
cp src/declarations/token/* .dfx/local/canisters/token/
cp src/declarations/token_index/* .dfx/local/canisters/token_index/
cp src/declarations/transactions/* .dfx/local/canisters/transactions/
cp src/declarations/transaction_index/* .dfx/local/canisters/transaction_index/
cp src/declarations/agent/* .dfx/local/canisters/agent/
cp src/declarations/marketplace/* .dfx/local/canisters/marketplace/
cp src/declarations/http_service/* .dfx/local/canisters/http_service/
cp src/declarations/statistics/* .dfx/local/canisters/statistics/
cp src/declarations/bucket/* .dfx/local/canisters/bucket/
cp src/declarations/bucket_index/* .dfx/local/canisters/bucket_index/

# Generate env.mo and deploy canisters
echo "====-Generate env.mo and deploy canisters-===="
if [ "$flag" = "clean" ]; then
  npm install
fi
dfx canister create --all --with-cycles 5000000000000
dfx build cero_trade_project_frontend
if [ "$flag" = "clean" ]; then
  dfx canister install cero_trade_project_frontend

  echo "====-setting cycles to token_index canister-===="
  dfx canister deposit-cycles 9_000_000_000_000 token_index
else
  dfx canister install cero_trade_project_frontend --mode upgrade
fi
dfx deploy http_service
dfx deploy agent

# Update canister controllers
echo "====-Update canister controllers-===="
npm run upgrade-controllers $(dfx identity get-principal)

if [ "$flag" = "modules" ] || [ "$flag" = "clean" ]; then
  # Register wasm modules
  echo "====-Register wasm modules-===="
  dfx canister create token
  dfx build token
  dfx canister create users
  dfx build users
  dfx canister create transactions
  dfx build transactions
  dfx canister create bucket
  dfx build bucket

  # Generate the wasm module like array
  echo "====-Generate the wasm module like array-===="
  npm run generate-wasm token local
  npm run generate-wasm users local
  npm run generate-wasm transactions local
  npm run generate-wasm bucket local

  # Push the current ./wasm_modules commit folder to github
  echo "====-Push the current ./wasm_modules commit folder to github-===="
  git pull
  git add ./wasm_modules
  git commit -m "config/new-wasm-modules"
  git push
fi

# Register wasm module into backend canisters
echo "====-Register wasm module into backend canisters-===="
dfx canister call agent registerWasmModule '(variant { "token" = "token" })'
dfx canister call agent registerWasmModule '(variant { "users" = "users" })'
dfx canister call agent registerWasmModule '(variant { "transactions" = "transactions" })'
dfx canister call agent registerWasmModule '(variant { "bucket" = "bucket" })'