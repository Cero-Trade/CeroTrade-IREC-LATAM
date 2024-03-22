<template>
  <Connect2ICProvider :client="client">
    <test-canister />
    <test-login />
    <slot />
  </Connect2ICProvider>
</template>

<script setup>
import TestCanister from '@/components/connect2ic-canister-test.vue'
import TestLogin from '@/components/connect2ic-login-test.vue'
/*
 * Connect2ic provides essential utilities for IC app development
 */
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider } from "@connect2ic/vue"
/*
 * Import canister definitions like this:
 */
import * as user from "../../.dfx/local/canisters/user"
import * as user_index from "../../.dfx/local/canisters/user_index"
import * as token from "../../.dfx/local/canisters/token"
import * as token_index from "../../.dfx/local/canisters/token_index"
import * as agent from "../../.dfx/local/canisters/agent"
import * as marketplace from "../../.dfx/local/canisters/marketplace"

const client = createClient({
  canisters: {
    user,
    user_index,
    token,
    token_index,
    agent,
    marketplace,
  },
  providers: defaultProviders,
  globalProviderConfig: {
    dev: import.meta.env.DEV,
  },
})
</script>
