#!/bin/bash

set -e

echo "====-cero_trade_project_frontend-===="
dfx canister status cero_trade_project_frontend --network ic

echo "====-agent-===="
dfx canister status agent --network ic

echo "====-http_service-===="
dfx canister status http_service --network ic

echo "====-user_index-===="
dfx canister status user_index --network ic

echo "====-token_index-===="
dfx canister status token_index --network ic

echo "====-notification_index-===="
dfx canister status notification_index --network ic

echo "====-transaction_index-===="
dfx canister status transaction_index --network ic

echo "====-bucket_index-===="
dfx canister status bucket_index --network ic

echo "====-marketplace-===="
dfx canister status marketplace --network ic

echo "====-statistics-===="
dfx canister status statistics --network ic
