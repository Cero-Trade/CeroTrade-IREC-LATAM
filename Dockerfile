# Start with the official Node.js base image to get the latest npm along with Node.js
FROM node:latest

# Install system dependencies required for the DFINITY Canister SDK and general development
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    cmake \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables for DFINITY Canister SDK version
ENV DFX_VERSION=0.9.3

# Install the DFINITY Canister SDK
RUN sh -ci "$(curl -fsSL https://sdk.dfinity.org/install.sh)" "" --version $DFX_VERSION

# Verify dfx installation
RUN dfx --version

# Install ic-mops globally
RUN npm install -g ic-mops

# Set the working directory in the Docker container
WORKDIR /app

# Copy your project files into the working directory
COPY . .

# Install project dependencies including Node.js packages
# Note: This assumes your project has a package.json file at its root
RUN npm install

# Use ic-mops to install Motoko package dependencies
# Note: This command assumes you have a mops.toml file in your project root
# Adjust the command as necessary based on your project's setup
RUN ic-mops install

# Expose any ports your app needs (adjust as necessary)
# EXPOSE 8000

# Command to run your app (adjust according to your project's needs)
# For example, to start a development server:
# CMD ["npm", "run", "start"]
# Or, to keep the container running without an explicit task, use:
CMD ["sleep", "infinity"]
