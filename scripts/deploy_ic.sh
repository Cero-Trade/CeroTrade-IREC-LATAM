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

# Generate env.mo and deploy canisters
echo "====-Generate env.mo and deploy canisters-===="
dfx build cero_trade_project_frontend
dfx build http_service
dfx build agent

dfx canister install cero_trade_project_frontend --mode upgrade
dfx canister install http_service --mode upgrade
dfx canister install user_index --mode upgrade
dfx canister install token_index --mode upgrade
dfx canister install notification_index --mode upgrade
dfx canister install transaction_index --mode upgrade
dfx canister install bucket_index --mode upgrade
dfx canister install marketplace --mode upgrade
dfx canister install statistics --mode upgrade
dfx canister install agent --mode upgrade

# Update canister controllers
echo "====-Update canister controllers-===="
controller=$(dfx identity get-principal)

dfx canister update-settings agent --add-controller $controller
dfx canister update-settings token_index --add-controller $controller
dfx canister update-settings user_index --add-controller $controller
dfx canister update-settings transaction_index --add-controller $controller
dfx canister update-settings notification_index --add-controller $controller
dfx canister update-settings bucket_index --add-controller $controller

dfx canister call agent registerControllers

# Register wasm module into backend canisters
echo "====-Register wasm module into backend canisters-===="
dfx canister call agent registerWasmModule '(variant { "token" = "token" })'
dfx canister call agent registerWasmModule '(variant { "users" = "users" })'
dfx canister call agent registerWasmModule '(variant { "transactions" = "transactions" })'
dfx canister call agent registerWasmModule '(variant { "notifications" = "notifications" })'
dfx canister call agent registerWasmModule '(variant { "bucket" = "bucket" })'