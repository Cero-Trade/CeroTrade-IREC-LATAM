import fs from 'fs/promises';
import clipboardy from 'clipboardy';


const args = process.argv.slice(2),
moduleName = args.find(arg => arg.startsWith('module=')).split('=')[1],
wasmFile = `.dfx/local/canisters/${moduleName}/${moduleName}.wasm`;

const data = await fs.readFile(wasmFile),
nat8Array = Array.from(data);

await clipboardy.write(JSON.stringify(nat8Array));
console.log(`${moduleName} Array has been copied to clipboard`);

// put this line on package.json to can run this script
// "type": "module",