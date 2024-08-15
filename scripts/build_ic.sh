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