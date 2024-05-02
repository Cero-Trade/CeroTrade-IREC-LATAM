# Cero Trade

## Project setup
Init ic background replica

`dfx start`

Install dependencies

`npm install`

Install mops dependencies globally if havent
`npm i -g ic-mops`

Otherwise install mops proyect dependencies
`mops install`

If .did are not created correctly

`dfx canister create --all`
`dfx build`

Generate declarations
```
dfx generate
cp src/declarations/users/* .dfx/local/canisters/users/
cp src/declarations/user_index/* .dfx/local/canisters/user_index/
cp src/declarations/token/* .dfx/local/canisters/token/
cp src/declarations/token_index/* .dfx/local/canisters/token_index/
cp src/declarations/transactions/* .dfx/local/canisters/transactions/
cp src/declarations/transaction_index/* .dfx/local/canisters/transaction_index/
cp src/declarations/agent/* .dfx/local/canisters/agent/
cp src/declarations/marketplace/* .dfx/local/canisters/marketplace/
cp src/declarations/http_service/* .dfx/local/canisters/http_service/
```

Deploy canisters

`dfx deploy`

To deploy only backend canisters run

`dfx deploy agent`

### Generate wasm modules (Note: only cero-devs)
```
dfx canister create token
dfx build token
dfx canister create users
dfx build users
dfx canister create transactions
dfx build transactions
cp .dfx/local/canisters/token/token.wasm wasm_modules/token.wasm
cp .dfx/local/canisters/users/users.wasm wasm_modules/users.wasm
cp .dfx/local/canisters/transactions/transactions.wasm wasm_modules/transactions.wasm
```
To generate the wasm module like array run command below

Note: must to add package.json field -> "type": "module",

Provide respective MODULE_NAME in argument
`npm run generate-wasm -- module={MODULE_NAME}`

Later push the current ./wasm_modules commit folder to github


To register wasm module into backend canisters must to run:

`
dfx canister call token_index registerWasmArray
dfx canister call user_index registerWasmArray
dfx canister call transaction_index registerWasmArray
`

### Deploying token canisters
`dfx canister call token_index registerToken '("token_id")'`

### Compiles and hot-reloads for development
`npm run dev`

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