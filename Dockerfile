# Dockerfile
# Use a specific version of the Ubuntu base image to ensure compatibility
FROM ubuntu:20.04

# Install system dependencies required for Node.js and the DFINITY Canister SDK
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    cmake \
    libunwind8 \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 16
RUN curl -sL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs

# Set the environment variable to non-interactively agree to the installation prompts
ENV DFXVM_INIT_YES=true
ENV DFX_VERSION="0.15.2"

# Direct download and install of DFINITY SDK
RUN curl -LO "https://github.com/dfinity/sdk/releases/download/${DFX_VERSION}/dfx-${DFX_VERSION}-x86_64-linux.tar.gz" && \
    tar -xzf dfx-${DFX_VERSION}-x86_64-linux.tar.gz -C /usr/local/bin && \
    rm dfx-${DFX_VERSION}-x86_64-linux.tar.gz

# Install ic-mops globally
RUN npm install -g ic-mops

# Set the working directory in the Docker container
WORKDIR /app

# Copy your project files into the working directory
COPY . .

# Install Node.js dependencies including Node.js packages
RUN npm install

# Expose any ports your app needs (adjust as necessary)
EXPOSE 8000

# Give execute permissions to the build script
COPY build_script.sh /app/build_script.sh
RUN chmod +x /app/build_script.sh

CMD ["bash", "/app/build_script.sh"]

