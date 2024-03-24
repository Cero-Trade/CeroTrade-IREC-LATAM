import { Actor, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { app as vueApp } from "@/main";

// canisters
import * as marketplace from "../../../.dfx/local/canisters/marketplace"
import * as token from "../../../.dfx/local/canisters/token"
import * as token_index from "../../../.dfx/local/canisters/token_index"
import * as agent from "../../../.dfx/local/canisters/agent"
import * as user from "../../../.dfx/local/canisters/user"
import * as user_index from "../../../.dfx/local/canisters/user_index"


export const canisterImpl = { canisterId: process.env.CERO_TRADE_PROJECT_FRONTEND_CANISTER_ID }

export const ICP_PROVIDE_COLLECTION = {
  authClient: 'authClient'
}
export const createActor = (canisterId, idlFactory, options) => {
  const isDevelopment = process.env.DFX_NETWORK !== "ic",
  identity = vueApp._instance.provides.authClient.getIdentity(),
  agent = new HttpAgent({ identity: isDevelopment ? null : identity, ...options?.agentOptions });
  
  // Fetch root key for certificate validation during development
  if (isDevelopment) {
    agent.fetchRootKey().catch(err=>{
      console.warn("Unable to fetch root key. Check to ensure that your local replica is running");
      console.error(err);
    });
  }

  // Creates an actor with using the candid interface and the HttpAgent
  return Actor.createActor(idlFactory, {
    agent,
    canisterId,
    ...options?.actorOptions,
  });
}

export const useMarketplaceCanister = () => createActor(marketplace.canisterId, marketplace.idlFactory)
export const useTokenCanister = () => createActor(token.canisterId, token.idlFactory)
export const useTokenIndexCanister = () => createActor(token_index.canisterId, token_index.idlFactory)
export const useAgentCanister = () => createActor(agent.canisterId, agent.idlFactory)
export const useUserCanister = () => createActor(user.canisterId, user.idlFactory)
export const useUserIndexCanister = () => createActor(user_index.canisterId, user_index.idlFactory)

export default async (app) => {
  const authClient = await AuthClient.create()
  app.provide('authClient', authClient)
}