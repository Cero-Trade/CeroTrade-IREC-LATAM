// dfxCommands.js
const { exec } = require('child_process');

const dfxPath = process.env.DFX_PATH || '/root/.local/share/dfx/bin'; // Fallback to the default path
const dfxExecutable = `${dfxPath}/dfx`;

// Function to execute a dfx command
function executeDfxCommand(command, callback) {
    exec(`${dfxExecutable} ${command}`, callback);
}

// Other functions that use dfx can be defined here...

module.exports = {
    executeDfxCommand,
    // export other functions...
};
