#!/bin/bash

# Start the local Internet Computer network
echo "Starting the local Internet Computer network..."
dfx start --background --clean

# Check dfx version
echo "DFX version:"
dfx --version

# This command prevents the container from exiting by tailing a file indefinitely.
echo "Container is running. To stop, use docker stop <container_id>"
tail -f /dev/null
