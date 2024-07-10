#!/bin/bash

# Define optional modules argument
firstArg=$1
secondArg=$2

# Change identity to `default`
echo "====-Change identity to default and branch to develop-===="
git checkout develop
dfx identity use default

# Deploy nns canisters
if [ "$firstArg" = "nns" ] || [ "$secondArg" = "nns" ]; then
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
cp src/declarations/notifications/* .dfx/local/canisters/notifications/
cp src/declarations/notification_index/* .dfx/local/canisters/notification_index/

# Generate env.mo and deploy canisters
echo "====-Generate env.mo and deploy canisters-===="
dfx canister create --all
dfx build cero_trade_project_frontend
dfx canister install cero_trade_project_frontend
dfx deploy agent

# Update canister controllers
echo "====-Update canister controllers-===="
npm run upgrade-controllers $(dfx identity get-principal)

if [ "$firstArg" = "modules" ] || [ "$secondArg" = "modules" ]; then
  # Register wasm modules
  echo "====-Register wasm modules-===="
  dfx canister create token
  dfx build token
  dfx canister create users
  dfx build users
  dfx canister create transactions
  dfx build transactions
  dfx canister create notifications
  dfx build notifications

  # Generate the wasm module like array
  echo "====-Generate the wasm module like array-===="
  npm run generate-wasm token
  npm run generate-wasm users
  npm run generate-wasm transactions
  npm run generate-wasm notifications

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
dfx canister call agent registerWasmModule '(variant { "notifications" = "notifications" })'
