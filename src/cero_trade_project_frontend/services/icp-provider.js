import { Actor, HttpAgent } from "@dfinity/agent";
import { AuthClient } from "@dfinity/auth-client";

// canisters
import * as marketplace from "../../../.dfx/local/canisters/marketplace"
import * as token from "../../../.dfx/local/canisters/token"
import * as token_index from "../../../.dfx/local/canisters/token_index"
import * as agent from "../../../.dfx/local/canisters/agent"
import * as user from "../../../.dfx/local/canisters/user"
import * as user_index from "../../../.dfx/local/canisters/user_index"


export const canisterImpl = {
  // canisterId: '' // <-- prod
  canisterId: '' // <-- develop
}

export const ICP_PROVIDE_COLLECTION = {
  authClient: 'authClient',
  agent: 'agent',
  marketplace:'marketplace',
  token: 'token',
  token_index: 'token_index',
  user: 'user',
  user_index: 'user_index',
}

export default async (app) => {
  const
  authClient = await AuthClient.create(),
  identity = authClient.getIdentity(),

  // actors
  agentActor = Actor.createActor(agent.idlFactory, {
    agent: new HttpAgent({ identity }),
    canisterId: users.canisterId,
  }),
  marketplaceActor = Actor.createActor(marketplace.idlFactory, {
    agent: new HttpAgent({ identity }),
    canisterId: marketplace.canisterId,
  }),
  tokenActor = Actor.createActor(token.idlFactory, {
    agent: new HttpAgent({ identity }),
    canisterId: token.canisterId,
  }),
  token_indexActor = Actor.createActor(token_index.idlFactory, {
    agent: new HttpAgent({ identity }),
    canisterId: token_index.canisterId,
  }),
  userActor = Actor.createActor(user.idlFactory, {
    agent: new HttpAgent({ identity }),
    canisterId: user.canisterId,
  }),
  user_indexActor = Actor.createActor(user_index.idlFactory, {
    agent: new HttpAgent({ identity }),
    canisterId: user_index.canisterId,
  })
  // provide data to vue
  app
    .provide('authClient', authClient)
    .provide('agent', agentActor)
    .provide('marketplace', marketplaceActor)
    .provide('token', tokenActor)
    .provide('token_index', token_indexActor)
    .provide('user', userActor)
    .provide('user_index', user_indexActor)
}
