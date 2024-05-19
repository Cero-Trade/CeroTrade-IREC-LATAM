#!/bin/bash

# Install ic-mops globally
npm i -g ic-mops

# Set longer timeout for mops
export NODE_OPTIONS="--max-old-space-size=4096"

# Retry function
function retry_mops_install {
  local max_attempts=5
  local attempt=1
  local exit_code=0

  until [ $attempt -ge $max_attempts ]; do
    mops install && break
    exit_code=$?
    echo "Attempt $attempt failed. Retrying in $((attempt * 2)) seconds..."
    sleep $((attempt * 2))
    attempt=$((attempt + 1))
  done

  return $exit_code
}

# Use Node.js version 16
. ~/.nvm/nvm.sh && nvm use 16

# Start dfx
dfx start --background --clean

# Attempt to install Motoko packages
retry_mops_install

# Create canisters
dfx canister create --all

# Generate canister types
dfx generate

# Copy declaration files
cp src/declarations/users/* .dfx/local/canisters/users/
cp src/declarations/user_index/* .dfx/local/canisters/user_index/
cp src/declarations/token/* .dfx/local/canisters/token/
cp src/declarations/token_index/* .dfx/local/canisters/token_index/
cp src/declarations/transactions/* .dfx/local/canisters/transactions/
cp src/declarations/transaction_index/* .dfx/local/canisters/transaction_index/
cp src/declarations/agent/* .dfx/local/canisters/agent/
cp src/declarations/marketplace/* .dfx/local/canisters/marketplace/
cp src/declarations/http_service/* .dfx/local/canisters/http_service/

# Deploy all canisters
dfx deploy

# Keep the container running
tail -f /dev/null
