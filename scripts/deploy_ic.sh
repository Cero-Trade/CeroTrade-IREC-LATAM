#!/bin/bash

set -e

# Define optional modules argument
flag=$1

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
cp src/declarations/bucket/* .dfx/local/canisters/bucket/
cp src/declarations/bucket_index/* .dfx/local/canisters/bucket_index/

# Generate env.mo and build canisters
if [ "$flag" != "backend" ]; then
  echo "====-Generate env.mo and build canisters-===="
  npm install
  dfx build cero_trade_project_frontend --network ic
else
  echo "====-Build backend canisters-===="
fi
dfx build http_service --network ic
dfx build agent --network ic

# Install canisters code
echo "====-Install canisters code-===="
if [ "$flag" != "backend" ]; then
  dfx canister install cero_trade_project_frontend --mode upgrade --network ic
fi
dfx canister install http_service --mode upgrade --network ic
dfx canister install user_index --mode upgrade --network ic
dfx canister install token_index --mode upgrade --network ic
dfx canister install notification_index --mode upgrade --network ic
dfx canister install transaction_index --mode upgrade --network ic
dfx canister install bucket_index --mode upgrade --network ic
dfx canister install marketplace --mode upgrade --network ic
dfx canister install statistics --mode upgrade --network ic
dfx canister install agent --mode upgrade --network ic

# Update canister controllers
echo "====-Update canister controllers-===="
controller=$(dfx identity get-principal)

dfx canister update-settings agent --add-controller $controller --network ic
dfx canister update-settings token_index --add-controller $controller --network ic
dfx canister update-settings user_index --add-controller $controller --network ic
dfx canister update-settings transaction_index --add-controller $controller --network ic
dfx canister update-settings notification_index --add-controller $controller --network ic
dfx canister update-settings bucket_index --add-controller $controller --network ic

dfx canister call agent registerControllers --network ic

# Register wasm module into backend canisters
echo "====-Register wasm module into backend canisters-===="
dfx canister call agent registerWasmModule '(variant { "token" = "token" })' --network ic
dfx canister call agent registerWasmModule '(variant { "users" = "users" })' --network ic
dfx canister call agent registerWasmModule '(variant { "transactions" = "transactions" })' --network ic
dfx canister call agent registerWasmModule '(variant { "notifications" = "notifications" })' --network ic
dfx canister call agent registerWasmModule '(variant { "bucket" = "bucket" })' --network ic