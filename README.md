# Cero Trade

Public url: https://z2mgf-dqaaa-aaaak-qihbq-cai.icp0.io?canisterId=z2mgf-dqaaa-aaaak-qihbq-cai

## Project setup
Init ic background replica

`dfx start`

Install dependencies

`npm install`

Install mops dependencies globally if havent
`npm i -g ic-mops`

Otherwise install mops proyect dependencies
`mops install`

Generate declarations
```
mkdir -p .dfx/local/canisters/cero_trade_project_frontend && cp assetstorage.did .dfx/local/canisters/cero_trade_project_frontend/assetstorage.did
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

Generate env.mo and deploy canisters

```
dfx deploy
dfx deploy agent
```

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
`dfx canister call agent mintTokenToUser '("recipent", "tokenId", tokenAmount)'`

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

#### how to get Cycles

Can supply a cycle faucet here:

https://internetcomputer.org/docs/current/developer-docs/setup/cycles/cycles-faucet

or convert ICP balance to Cycles (TC) by run:

`dfx ledger top-up <wallet_id> --icp <icp_amount> --network ic`

#### How to export and import identities between devices
* export: `dfx identity export <identity_name> > exported_identity.pem`

* import: `dfx identity import <new_identity_name> <exported_identity_root_file.pem>`

#### How to add canister controllers
https://internetcomputer.org/docs/current/developer-docs/smart-contracts/maintain/control#setting-the-controllers-of-a-canister

#### Mainnet deploy
https://internetcomputer.org/docs/current/developer-docs/setup/deploy-mainnet

### IC Management Canister docs
https://internetcomputer.org/docs/current/references/ic-interface-spec#ic-management-canister

### Mops site url
https://mops.one/

### Anonymous principal
2vxsx-fae