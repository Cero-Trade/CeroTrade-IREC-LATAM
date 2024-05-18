// put this line on package.json to can run this script
// "type": "module",

import fs from 'fs/promises';

const args = process.argv.slice(2),
moduleName = args.find(arg => arg.startsWith('module=')).split('=')[1],
wasmFile = `.dfx/local/canisters/${moduleName}/${moduleName}.wasm.gz`;

const data = await fs.readFile(wasmFile),
nat8Array = Array.from(data);

const jsonFile = `./wasm_modules/${moduleName}.json`;
await fs.writeFile(jsonFile, JSON.stringify(nat8Array));

console.log(`${moduleName} Array has been generated in ${jsonFile}`);