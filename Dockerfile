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

# Set the environment variable to non-interactively agree to the installation prompts
ENV DFXVM_INIT_YES=true

# Install the DFINITY Canister SDK
RUN curl -fsSL https://internetcomputer.org/install.sh | sh \
    && echo "Install script exit code: $?"

# Define the DFX_PATH environment variable and add it to PATH
ENV DFX_PATH="/root/.local/share/dfx/bin"
ENV PATH="$DFX_PATH:$PATH"

# Verify dfx installation and check if moc is installed correctly
RUN curl -fsSL https://internetcomputer.org/install.sh | sh \
    && echo "Install script exit code: $?"

# Attempt to load the environment and check for `moc`
RUN bash -lc "dfx --version && find / -name moc 2>/dev/null"

# Install ic-mops globally
RUN npm install -g ic-mops

# Set the working directory in the Docker container
WORKDIR /app

# Copy your project files into the working directory
COPY . .

# Install project dependencies including Node.js packages
RUN npm install

# Use ic-mops to install Motoko package dependencies
RUN mops install

# Expose any ports your app needs (adjust as necessary)
EXPOSE 8000

# Commands to run your app
# Assuming dfx, generate, copy commands and deploy commands are needed
RUN dfx start --background --clean \
    && dfx generate \
    && cp src/declarations/users/* .dfx/local/canisters/users/ \
    && cp src/declarations/user_index/* .dfx/local/canisters/user_index/ \
    && cp src/declarations/token/* .dfx/local/canisters/token/ \
    && cp src/declarations/token_index/* .dfx/local/canisters/token_index/ \
    && cp src/declarations/agent/* .dfx/local/canisters/agent/ \
    && cp src/declarations/marketplace/* .dfx/local/canisters/marketplace/ \
    && cp src/declarations/http_service/* .dfx/local/canisters/http_service/ \
    && dfx deploy

# CMD to keep the container running
