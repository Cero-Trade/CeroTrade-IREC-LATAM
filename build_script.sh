#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Start the local Internet Computer network
echo "Starting the local Internet Computer network..."
dfx start --background --clean

# Check dfx version
echo "DFX version:"
dfx --version

# Generate necessary files
echo "Generating necessary files..."
dfx generate

# Copy the generated declarations to the respective directories
echo "Copying declarations..."
cp -R src/declarations/users/* .dfx/local/canisters/users/
cp -R src/declarations/user_index/* .dfx/local/canisters/user_index/
cp -R src/declarations/token/* .dfx/local/canisters/token/
cp -R src/declarations/token_index/* .dfx/local/canisters/token_index/
cp -R src/declarations/agent/* .dfx/local/canisters/agent/
cp -R src/declarations/marketplace/* .dfx/local/canisters/marketplace/
cp -R src/declarations/http_service/* .dfx/local/canisters/http_service/

# Deploy canisters
echo "Deploying canisters..."
dfx deploy

# This command prevents the container from exiting by tailing a file indefinitely.
echo "Container is running. To stop, use docker stop <container_id>"
tail -f /dev/null
