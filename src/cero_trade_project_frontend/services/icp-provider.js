import { Actor, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { app as vueApp } from "@/main";

// canisters
import * as agentCanister from "../../../.dfx/local/canisters/agent"


export const canisterImpl = { canisterId: process.env.CERO_TRADE_PROJECT_FRONTEND_CANISTER_ID }

export const createActor = (canisterId, idlFactory, options) => {
  const isDevelopment = process.env.DFX_NETWORK !== "ic",
  identity = vueApp._context.provides.authClient.getIdentity(),
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

export const getErrorStatus = (error) => Number(error.message.split('Reject code: ')[1].split('Reject text: ')[0].trim())

export const getErrorMessage = (error) => error.message.split('Reject text: ')[1].trim()


export const useAgentCanister = () => createActor(agentCanister.canisterId, agentCanister.idlFactory)

export const useAuthClient = () => vueApp._context.provides.authClient

export default async (app) => {
  const authClient = await AuthClient.create()
  app.provide('authClient', authClient)
}