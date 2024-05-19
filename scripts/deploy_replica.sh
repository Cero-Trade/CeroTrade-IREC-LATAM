# Define optional modules argument
arg=$1

# Generate declarations
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

# Generate env.mo and deploy canisters
dfx deploy cero_trade_project_frontend
dfx deploy agent

if [ "$arg" = "modules" ]; then
  # Register wasm modules
  dfx canister create token
  dfx build token
  dfx canister create users
  dfx build users
  dfx canister create transactions
  dfx build transactions

  # Generate the wasm module like array
  npm run generate-wasm token
  npm run generate-wasm users
  npm run generate-wasm transactions

  # Push the current ./wasm_modules commit folder to github
  git pull
  git add ./wasm_modules
  git commit -m "config/new-wasm-modules"
  git push

  # Register wasm module into backend canisters
  dfx canister call agent registerWasmModule '(variant { "token" = "token" })'
  dfx canister call agent registerWasmModule '(variant { "users" = "users" })'
  dfx canister call agent registerWasmModule '(variant { "transactions" = "transactions" })'
fi