# Cero Trade

## Project setup

```
# init ic background replica
dfx start

# install dependencies
npm install

# install mops dependencies if havent
npm i -g ic-mops

# generate declarations
dfx generate

cp src/declarations/users/* .dfx/local/canisters/users/
cp src/declarations/user_index/* .dfx/local/canisters/user_index/
cp src/declarations/token/* .dfx/local/canisters/token/
cp src/declarations/token_index/* .dfx/local/canisters/token_index/
cp src/declarations/agent/* .dfx/local/canisters/agent/
cp src/declarations/marketplace/* .dfx/local/canisters/marketplace/
cp src/declarations/http_service/* .dfx/local/canisters/http_service/

# deploy canisters
dfx deploy

# reinstall token canister using [canister_id] and requested [token_id]
dfx canister install canister_id --argument '(opt "token_id")' --mode reinstall

# initialize token canister from token_index
dfx canister call token_index initToken '("token_id")'
```

### Deploying only backend canisters

```
dfx deploy users
dfx deploy user_index
dfx deploy token
dfx deploy token_index
dfx deploy agent
dfx deploy marketplace
dfx deploy http_service
```

### Compiles and hot-reloads for development

```
npm run dev
```

### Customize configuration

See [Configuration Reference](https://vitejs.dev/config/).


### Guides

#### Vue frontend
https://internetcomputer.org/docs/current/developer-docs/frontend/vue-frontend

#### Internet identity integration
https://internetcomputer.org/docs/current/developer-docs/integrations/internet-identity/integrate-identity

#### how to Cycles faucet
https://internetcomputer.org/docs/current/developer-docs/setup/cycles/cycles-faucet

#### How to export and import identities between devices
* export: `dfx identity export <identity_name> > exported_identity.pem`

* import: `dfx identity import <new_identity_name> <exported_identity_root_file.pem>`

#### Mainnet deploy
https://internetcomputer.org/docs/current/developer-docs/setup/deploy-mainnet

### Mops site url
https://mops.one/