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

### Register wasm modules

Register wasm module into backend canisters by run:
```
dfx canister call agent registerWasmModule '(variant { "token" = "token" })'
dfx canister call agent registerWasmModule '(variant { "users" = "users" })'
dfx canister call agent registerWasmModule '(variant { "transactions" = "transactions" })'
```

### Deploying token canisters
`dfx canister call agent registerToken '("token_id")'`

### Minting tokens to users
`dfx canister call agent mintTokenToUser '("recipent", "TokenId", TokenAmount)'`

### Generate wasm modules (Note: only cero-devs)
```
dfx canister create token
dfx build token
dfx canister create users
dfx build users
dfx canister create transactions
dfx build transactions
```

Generate the wasm module like array run command below

Note: must to add package.json field -> "type": "module",
```
npm run generate-wasm -- module=token
npm run generate-wasm -- module=users
npm run generate-wasm -- module=transactions
```

Push the current ./wasm_modules commit folder to github
```
git pull
git add ./wasm_modules
git commit -m "config/new-wasm-modules"
git push
```

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

### Anonymous principal
2vxsx-fae