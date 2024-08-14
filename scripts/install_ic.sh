#!/bin/bash

set -e

# Define optional modules argument
flag=$1

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