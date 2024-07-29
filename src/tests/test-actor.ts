import { Actor, HttpAgent } from "@dfinity/agent";
import fetch from "isomorphic-fetch";
import canisterIds from ".dfx/local/canister_ids.json";
import { idlFactory } from "../declarations/agent/agent.did.js";

const createActor = async (canisterId: any, options: any) => {
  const agent = new HttpAgent({ ...options?.agentOptions });
  await agent.fetchRootKey();

  // Creates an actor with using the candid interface and the HttpAgent
  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
    ...options?.actorOptions,
  });
};

export const agentCanister = canisterIds.agent.local;

export const agentActor = createActor(agentCanister, {
  agentOptions: { host: "http://127.0.0.1:8080", fetch },
});