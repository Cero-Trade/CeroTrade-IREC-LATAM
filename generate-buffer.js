import fs from 'fs/promises';
import clipboardy from 'clipboardy';
const wasmFile = '.dfx/local/canisters/token/token.wasm';

const data = await fs.readFile(wasmFile);
const nat8Array = Array.from(data);
await clipboardy.write(JSON.stringify(nat8Array));
console.log('Array has been copied to clipboard');

// put this line on package.json to can run this script
// "type": "module",