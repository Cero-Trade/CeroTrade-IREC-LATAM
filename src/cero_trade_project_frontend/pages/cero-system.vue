<template>
  <div id="cero-system">
    <h6>Register Wasm Module</h6>
    <v-form class="mb-6" @submit.prevent>
      <v-btn :loading="loadingWasmModule" @click="registerWasmModule('token')">Register TOKEN module</v-btn>
      <v-btn :loading="loadingWasmModule" @click="registerWasmModule('users')">Register USERS module</v-btn>
      <v-btn :loading="loadingWasmModule" @click="registerWasmModule('transactions')">Register transactions module</v-btn>
    </v-form>


    <h6>Register Token Module</h6>
    <v-form ref="registerTokenFormRef" @submit.prevent="registerTokenCall">
      <v-text-field
        v-model="registerTokenForm.tokenId"
        label="Token ID"
        variant="outlined"
        density="compact"
        :rules="[globalRules.required]"
        @keyup="({ key }) => { if (key === 'Enter') registerTokenCall() }"
      ></v-text-field>
    </v-form>
    <v-btn
      width="150px"
      :loading="loadingRegisterTokenForm"
      class="mb-6"
      @click="registerTokenCall"
    >Call</v-btn>


    <h6>Mint To User Module</h6>
    <v-form ref="mintToUserFormRef" @submit.prevent="mintToUserCall">
      <v-text-field
        v-model="mintToUserForm.user"
        label="User to mint"
        variant="outlined"
        density="compact"
        :rules="[globalRules.required]"
        @keyup="({ key }) => { if (key === 'Enter') mintToUserCall() }"
      ></v-text-field>
      <v-text-field
        v-model="mintToUserForm.tokenId"
        label="Token id to mint"
        variant="outlined"
        density="compact"
        :rules="[globalRules.required]"
        @keyup="({ key }) => { if (key === 'Enter') mintToUserCall() }"
      ></v-text-field>
      <v-text-field
        v-model="mintToUserForm.tokenAmount"
        label="Amount to mint"
        variant="outlined"
        density="compact"
        :rules="[globalRules.required]"
        @keyup="({ key }) => { if (key === 'Enter') mintToUserCall() }"
      ></v-text-field>
    </v-form>
    <v-btn
      width="150px"
      :loading="loadingMintToUserForm"
      class="mb-6"
      @click="mintToUserCall"
    >Call</v-btn>
  </div>
</template>

<script setup>
import variables from '@/mixins/variables';
import { AuthClientApi } from '@/repository/auth-client-api';
import { CeroSystemApi } from '@/repository/cero-system-api';
import { onBeforeMount, ref } from 'vue'
import { useRouter } from 'vue-router';
import { useToast } from 'vue-toastification'

const
  router = useRouter(),
  toast = useToast(),
  { globalRules } = variables,

// wasm module
loadingWasmModule = ref(false),

// register token module
registerTokenFormRef = ref(),
loadingRegisterTokenForm = ref(false),
registerTokenForm = ref({ tokenId: null }),

// mint to user module
mintToUserFormRef = ref(),
loadingMintToUserForm = ref(false),
mintToUserForm = ref({
  user: null,
  tokenId: null,
  tokenAmount: null,
})


onBeforeMount(() => {
  if (process.env.DFX_NETWORK === 'ic' && ![
    process.env.CERO_ADMIN_1,
    process.env.CERO_ADMIN_2,
  ].includes(AuthClientApi.getPrincipal().toString())) return router.back()
})


async function registerWasmModule(input) {
  if (loadingWasmModule.value) return
  loadingWasmModule.value = true

  try {
    await CeroSystemApi.registerWasmModule(input)

    toast.success(`Wasm module registered: ${input} `)
  } catch (error) {
    toast.error(error)
  }

  loadingWasmModule.value = false
}

async function registerTokenCall() {
  if (!(await registerTokenFormRef.value.validate()).valid || loadingRegisterTokenForm.value) return
  loadingRegisterTokenForm.value = true

  try {
    const res = await CeroSystemApi.registerToken(registerTokenForm.value.tokenId)
    console.log(res);

    toast.success("Token minted")
  } catch (error) {
    toast.error(error)
  }

  loadingRegisterTokenForm.value = false
}

async function mintToUserCall() {
  if (!(await mintToUserFormRef.value.validate()).valid || loadingMintToUserForm.value) return
  loadingMintToUserForm.value = true

  try {
    mintToUserForm.value.tokenAmount = Number(mintToUserForm.value.tokenAmount)
    await CeroSystemApi.mintTokenToUser(mintToUserForm.value)

    toast.success(`Token minted to user ${mintToUserForm.value.user}`)
  } catch (error) {
    toast.error(error)
  }

  loadingMintToUserForm.value = false
}
</script>

<style lang="scss">
#cero-system {
  max-width: 800px;
  margin-top: 60px;
  margin-inline: auto;

  .v-form {
    display: flex;
    flex-wrap: wrap;
    column-gap: 10px;
  }
}
</style>
