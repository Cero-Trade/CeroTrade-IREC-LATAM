# Cero Trade

Cero Trade is a platform built on the DFINITY Internet Computer, offering robust blockchain solutions. This README outlines the steps for setting up the development environment, making changes, and redeploying canisters.

## Table of Contents
- [Project Setup](#project-setup)
- [Deployment Instructions](#deployment-instructions)
- [Development Tools](#development-tools)
- [Additional Resources](#additional-resources)

## Project Setup

### Building the Docker Image
To build the Docker image, run the following command:
```bash
docker build -t cerotrade .
```

### Running the Docker Container
To execute the Docker container and map the necessary ports:
```bash
docker run -d -p 8000:8000 --name cerotrade-container cerotrade
```

### Accessing the Docker Container
For making changes or manual deployments within the Docker environment, access the container using:
```bash
docker exec -it cerotrade-container /bin/bash
```

## Deployment Instructions

### Canister Creation and Building
If `.did` files are not created correctly, run the following commands:
```bash
dfx create --all
dfx build
```

### Generate Declarations
To generate and copy the canister declarations:
```bash
dfx generate
cp src/declarations/users/* .dfx/local/canisters/users/
cp src/declarations/user_index/* .dfx/local/canisters/user_index/
cp src/declarations/token/* .dfx/local/canisters/token/
cp src/declarations/token_index/* .dfx/local/canisters/token_index/
cp src/declarations/agent/* .dfx/local/canisters/agent/
cp src/declarations/marketplace/* .dfx/local/canisters/marketplace/
cp src/declarations/http_service/* .dfx/local/canisters/http_service/
```

### Deploying Canisters
To deploy all canisters:
```bash
dfx deploy
```
To deploy only backend canisters:
```bash
dfx deploy agent
```

### Generating Token Wasm Module
Create and build the token wasm module:
```bash
dfx canister create token
dfx build token
```
To generate the wasm module like array, ensure `"type": "module",` is added to `package.json` and run:
```bash
npm run generate-buffer
```

### Deploying Token Canisters
Register a new token with the token index canister:
```bash
dfx canister call token_index registerToken '("token_id")'
```

## Development Tools

### Compiles and Hot-reloads for Development
For live development with hot-reload, execute:
```bash
npm run dev
```

## Additional Resources

### Customize Configuration
See the [Vite Configuration Reference](https://vitejs.dev/config/) for advanced settings.

### Guides
- [Vue Frontend](https://internetcomputer.org/docs/current/developer-docs/frontend/vue-frontend)
- [Internet Identity Integration](https://internetcomputer.org/docs/current/developer-docs/integrations/internet-identity/integrate-identity)
- [Cycles Faucet](https://internetcomputer.org/docs/current/developer-docs/setup/cycles/cycles-faucet)
- [Export and Import Identities](https://internetcomputer.org/docs/current/developer-docs/setup/deploy-mainnet)
    - export: `dfx identity export <identity_name> > exported_identity.pem`
    - import: `dfx identity import <new_identity_name> <exported_identity_root_file.pem>`

### Mainnet Deploy
For deploying to the mainnet, follow the instructions provided [here](https://internetcomputer.org/docs/current/developer-docs/setup/deploy-mainnet).

### Mops Site URL
For additional tools and resources, visit [Mops](https://mops.one/).
