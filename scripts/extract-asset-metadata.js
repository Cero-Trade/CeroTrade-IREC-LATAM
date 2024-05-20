let input = process.argv[2]

// Quita canisterId
input = input.replace(/canisterId = [^;]*; /, '');

// Quita los paréntesis
input = input.replace('(', '').replace(')', '');

// Quita el primer texto de 'record'
input = input.replace('assetMetadata = record ', '');

// Quita el primer y último bracket
input = input.replace('{', '').replace(/}([^}]*)$/, '$1');

// Quita la ultima comma
input = input.replace(/,([^,]*)$/, '$1');

// Quita el ultima bracket
input = input.replace(/;([^;]*)$/, '$1');

console.log(input);