import { Secp256k1KeyIdentity } from "@dfinity/identity";
import hdkey from "hdkey";
import bip39 from "bip39";
// Completely insecure seed phrase. Do not use for any purpose other than testing.
// Resolves to "wnkwv-wdqb5-7wlzr-azfpw-5e5n5-dyxrf-uug7x-qxb55-mkmpa-5jqik-tqe"
const seed =
  "peacock peacock peacock peacock peacock peacock peacock peacock peacock peacock peacock peacock"

const identityFromSeed = async (phrase: string) => {
  const seed = await bip39.mnemonicToSeed(phrase),
  root = hdkey.fromMasterSeed(seed),
  addrnode = root.derive("m/44'/223'/0'/0/0");

  return Secp256k1KeyIdentity.fromSecretKey(addrnode.privateKey);
};

export const identity = identityFromSeed(seed);