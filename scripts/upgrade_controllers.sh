#!/bin/bash

set -e

# Get controllers
for controller in "$@"
do
  # Set controllers
  dfx canister update-settings agent --add-controller $controller
  dfx canister update-settings token_index --add-controller $controller
  dfx canister update-settings user_index --add-controller $controller
  dfx canister update-settings transaction_index --add-controller $controller
done

# Register controllers into canisters
dfx canister call agent registerControllers