#!/bin/bash

# Define module name
moduleName=$1

# Define wasm file root
wasmFile=".dfx/local/canisters/${moduleName}/${moduleName}.wasm.gz"

# Read wasm file and convert to array
data=$(node -e "const fs = require('fs'); const data = fs.readFileSync('${wasmFile}'); console.log(JSON.stringify(Array.from(data)));")

# Define json file root
jsonFile="./wasm_modules/${moduleName}.json"

# Write array into json file
echo $data > $jsonFile

# Print success message
echo "${moduleName} Array has been generated in ${jsonFile}"
