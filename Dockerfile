# Use a specific version of the Node.js base image to ensure consistency
FROM node:16-slim

# Set work directory
WORKDIR /app

# Set environment variables that are unlikely to change frequently
ENV DFXVM_INIT_YES=true \
    DFX_VERSION="0.15.2" \
    DFX_PATH="/root/.local/share/dfx/bin" \
    PATH="$DFX_PATH:$PATH"

# Install system dependencies required for the DFINITY Canister SDK and general development
# Group commands to reduce layers and use clean-up in the same layer to reduce image size
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    cmake \
    libunwind8 \
    && curl -fsSL https://internetcomputer.org/install.sh | sh \
    && dfx cache install \
    && rm -rf /var/lib/apt/lists/* \
    && echo "Install script exit code: $?"

# Install global npm packages
RUN npm install -g ic-mops

# Copy only the necessary dependency files
COPY package*.json ./

# Install Node.js dependencies
RUN npm install

# Copy the rest of your project files into the working directory
COPY . .

# Give execute permissions to the build script
RUN chmod +x build_script.sh

# Expose any ports your app needs
EXPOSE 8000

CMD ["/app/build_script.sh"]
