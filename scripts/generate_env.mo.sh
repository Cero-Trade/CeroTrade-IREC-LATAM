#!/bin/bash

set -e

# Define the name of the output file
outputFile="src/cero_trade_project_backend/env.mo"

# Define the name of the .env file
envFile=".env"

# Verify that the .env file exists
if [ ! -f "$envFile" ]; then
  echo "The file $envFile does not exist."
  exit 1
fi

# Initialize the declarations string
declarations="module ENV {\n"

# Read the .env file line by line
while IFS='=' read -r key value; do
  # Convert the key to uppercase
  upperKey=$(echo $key | tr '[:lower:]' '[:upper:]')

  # Verify if the key contains 'DFX', 'CANISTER' or 'VITE'
  if [[ $upperKey == *"DFX_"* ]] || [[ $upperKey == *"CANISTER_"* ]] || [[ $upperKey == *"VITE_"* ]]; then
    # Add the declaration to the declarations string
    declarations+="  public let ${upperKey}: Text = \"${value}\";\n"
  fi
done < "$envFile"

# Close the declarations string
declarations+="}"

# Write the declarations to the output file
echo -e $declarations > $outputFile

# Print a success message
echo "The file $outputFile has been successfully generated."
