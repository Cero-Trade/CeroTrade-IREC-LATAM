<!-- TODO subdomain integration with `cerotrade.cl/alfa` -->
<!-- TODO make new arquitecture to backend -->
<!-- TODO change delete canister function to inactivate canister and can be reused when create other user -->

# Cero Trade

Public frontend url: https://z2mgf-dqaaa-aaaak-qihbq-cai.icp0.io?canisterId=z2mgf-dqaaa-aaaak-qihbq-cai

Public candid url: https://a4gq6-oaaaa-aaaab-qaa4q-cai.raw.icp0.io/?id=<canister_id>

## Deployment Commands

`npm run deploy`: used to upgrade all canisters excluding dynamic canisters.

`npm run deploy modules`: used to upgrade all canisters including dynamic canisters.

`npm run deploy clean`: used to deploy canisters from zero, useful when run dfx start --clean.

## Project setup

If you havent nns extension installed run:
`dfx extension install nns`

* You can run this proyect locally by run below script:
```
dfx start
npm run deploy clean
```


* Also can try manually following these steps:

Init ic background replica

`dfx start`

Install dependencies

`npm install`

Install mops dependencies globally if havent
`npm i -g ic-mops`

Otherwise install mops proyect dependencies
`mops install`


deploy internet identity canister

`dfx deploy internet_identity`

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
cp src/declarations/statistics/* .dfx/local/canisters/statistics/
cp src/declarations/notifications/* .dfx/local/canisters/notifications/
cp src/declarations/notification_index/* .dfx/local/canisters/notification_index/
cp src/declarations/bucket/* .dfx/local/canisters/bucket/
cp src/declarations/bucket_index/* .dfx/local/canisters/bucket_index/
```

Generate env.mo and deploy canisters

```
dfx canister create --all
dfx build cero_trade_project_frontend
dfx canister install cero_trade_project_frontend
dfx deploy http_service
dfx deploy agent
```

Update canister controllers

`
npm run upgrade-controllers <[principal]>
`

### Register wasm modules

Register wasm module into backend canisters by run:
```
dfx canister call agent registerWasmModule '(variant { "token" = "token" })'
dfx canister call agent registerWasmModule '(variant { "users" = "users" })'
dfx canister call agent registerWasmModule '(variant { "transactions" = "transactions" })'
dfx canister call agent registerWasmModule '(variant { "notifications" = "notifications" })'
```

### Deploying token canisters
`
dfx canister call agent registerToken '("<token_id>" "<name>" "<symbol>" "<logo>")'
`

### Minting tokens to users
`
dfx canister call agent mintTokenToUser '("<recipent>", "<tokenId>", <tokenAmount>)'
`

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

```
npm run generate-wasm token
npm run generate-wasm users
npm run generate-wasm transactions
npm run generate-wasm notifications
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

### How to setup Internet Identity locally to development
https://github.com/dfinity/internet-identity/blob/main/demos/using-dev-build/README.md

#### How to add canister controllers
https://internetcomputer.org/docs/current/developer-docs/smart-contracts/maintain/control#setting-the-controllers-of-a-canister

#### Mainnet deploy
https://internetcomputer.org/docs/current/developer-docs/setup/deploy-mainnet

### IC Management Canister docs
https://internetcomputer.org/docs/current/references/ic-interface-spec#ic-management-canister

### Mops site url
https://mops.one/

### ICRC Standard Implementation
* ICRC Fungible: https://github.com/PanIndustrial-Org/ICRC_fungible

* ICRC Types: https://github.com/NatLabs/icrc1/blob/main/src/ICRC1/Types.mo

### NNS local deployment
* url: https://internetcomputer.org/docs/current/developer-docs/developer-tools/cli-tools/cli-reference/dfx-nns

* convert principal to account-id: https://k7gat-daaaa-aaaae-qaahq-cai.raw.ic0.app/docs/

### Custom domain configuration
https://internetcomputer.org/docs/current/developer-docs/web-apps/custom-domains/using-custom-domains#custom-domains-on-the-boundary-nodes

### found canister
dfx canister deposit-cycles 20_860_000_000 --network ic http_service