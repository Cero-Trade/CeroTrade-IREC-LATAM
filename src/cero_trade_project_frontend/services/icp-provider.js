import { Actor, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";
import { app as vueApp } from "@/main";

// canisters
import * as agentCanister from "../../../.dfx/local/canisters/agent"


export const canisterImpl = { canisterId: process.env.CANISTER_ID_CERO_TRADE_PROJECT_FRONTEND }

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

// default texts
const rejectCode = 'Reject code: ',
rejectText = 'Reject text: ',
httpStatus = 'Http status: ',
httpBody = 'Http body: '

export const getCanisterRejectCode = (error) => {
  if (!error.message.includes(rejectCode)) return error.message

  return Number(error.message.split(rejectCode)[1].split(rejectText)[0].trim())
}

export const getStatusCode = (error) => {
  if (!error.message.includes(rejectText)) return error.message

  const message = error.message.split(rejectText)[1].trim()
  if (!message.includes(httpStatus)) return error.message

  return Number(message.split(httpStatus)[1].split(httpBody)[0].trim())
}

export const getErrorMessage = (error) => {
  if (!error.message.includes(rejectText)) return error.message

  const message = error.message.split(rejectText)[1].trim()
  if (!message.includes(httpBody)) return message

  return message.split(httpBody)[1].trim()
}


export const useAgentCanister = () => createActor(agentCanister.canisterId, agentCanister.idlFactory)

export const useAuthClient = () => vueApp._context.provides.authClient

export default async (app) => {
  const authClient = await AuthClient.create()
  app.provide('authClient', authClient)
}