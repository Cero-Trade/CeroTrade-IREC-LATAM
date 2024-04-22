# Use a specific version of the Node.js base image to ensure consistency
FROM node:16-bullseye

# Install system dependencies required for the DFINITY Canister SDK and general development
# Install system dependencies required for the DFINITY Canister SDK and general development
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    libssl-dev \
    pkg-config \
    cmake \
    libunwind8 \ 
    && rm -rf /var/lib/apt/lists/*

# Set the environment variable to non-interactively agree to the installation prompts
ENV DFXVM_INIT_YES=true
ENV DFX_VERSION="0.15.2"

# Install the DFINITY Canister SDK
RUN sh -ci "$(curl -fsSL https://internetcomputer.org/install.sh)"

# Define the DFX_PATH environment variable and add it to PATH
ENV DFX_PATH="/root/.local/share/dfx/bin"
ENV PATH="$DFX_PATH:$PATH"

# Verify dfx installation and check if moc is installed correctly
RUN dfx cache install

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

# Copy the build script to the container
COPY build_script.sh /app/build_script.sh

# Give execute permissions to the build script
RUN chmod +x /app/build_script.sh

WORKDIR /app

CMD ["bash", "/app/build_script.sh"]

#CMD ["tail", "-f", "/dev/null"]