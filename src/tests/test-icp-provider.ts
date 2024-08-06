import { Actor, HttpAgent } from "@dfinity/agent";
import fetch from "isomorphic-fetch";
import canisterIds from ".dfx/local/canister_ids.json";
import { Secp256k1KeyIdentity } from "@dfinity/identity";
import hdkey from "hdkey";
import bip39 from "bip39";

// candid declarations
import { idlFactory } from "../declarations/agent/agent.did.js";

const createActor = async (canisterId: string, options: any) => {
  const agent = new HttpAgent({ ...options?.agentOptions });
  await agent.fetchRootKey();

  // Creates an actor with using the candid interface and the HttpAgent
  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
    ...options?.actorOptions,
  });
};

export const agentCanisterId = canisterIds.agent.local;

export const agentActor = createActor(agentCanisterId, {
  agentOptions: { host: "http://127.0.0.1:8080", fetch },
});


// Completely insecure seed phrase. Do not use for any purpose other than testing.
// Resolves to "wnkwv-wdqb5-7wlzr-azfpw-5e5n5-dyxrf-uug7x-qxb55-mkmpa-5jqik-tqe"
const seed =
  "peacock peacock peacock peacock peacock peacock peacock peacock peacock peacock peacock peacock";

export const identityFromSeed = async (phrase: string) => {
  const seed = await bip39.mnemonicToSeed(phrase),
  root = hdkey.fromMasterSeed(seed),
  addrnode = root.derive("m/44'/223'/0'/0/0")

  return Secp256k1KeyIdentity.fromSecretKey(addrnode.privateKey);
};

export const identity = identityFromSeed(seed);