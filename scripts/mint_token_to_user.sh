# TODO this script is used to testing
#!/bin/bash

userId=$1
tokenId=$2
amount=$3

set -e

canisterId=$(dfx canister call token_index getTokenCanister "(\"$tokenId\")" | sed -n -e 's/^.*"\(.*\)".*$/\1/p')

dfx canister call $canisterId icrc1_transfer "(record {
  memo = null; 
  created_at_time = null;
  from_subaccoint = null;
  amount = $amount;
  to = record {
    owner = principal \"$userId\";
    subaccount = null;
  };
  fee = null
})"