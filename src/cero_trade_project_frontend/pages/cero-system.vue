<template>
  <div id="cero-system">
    <h6>Mint Module</h6>
    <v-form ref="mintFormRef" @submit.prevent="mintCall">
      <v-text-field
        v-model="mintForm.user"
        label="User to mint"
        variant="outlined"
        density="compact"
        :rules="[globalRules.required]"
        @keyup="({ key }) => { if (key === 'Enter') mintCall() }"
      ></v-text-field>
      <v-text-field
        v-model="mintForm.tokenId"
        label="Token id to mint"
        variant="outlined"
        density="compact"
        :rules="[globalRules.required]"
        @keyup="({ key }) => { if (key === 'Enter') mintCall() }"
      ></v-text-field>
      <v-text-field
        v-model="mintForm.tokenAmount"
        label="Amount to mint"
        variant="outlined"
        density="compact"
        :rules="[globalRules.required]"
        @keyup="({ key }) => { if (key === 'Enter') mintCall() }"
      ></v-text-field>
    </v-form>
    <v-btn
      width="150px"
      :loading="loadingMintForm"
      class="mb-6"
      @click="mintCall"
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

// mint module
mintFormRef = ref(),
loadingMintForm = ref(false),
mintForm = ref({
  user: null,
  tokenId: null,
  tokenAmount: null,
})


onBeforeMount(() => {
  if (AuthClientApi.getPrincipal().toString() !== process.env.CERO_ADMIN)
    return toast.error("You are not admin user")
    // return router.back()
})

async function mintCall() {
  if (!(await mintFormRef.value.validate()).valid || loadingMintForm.value) return
  loadingMintForm.value = true

  try {
    mintForm.value.tokenAmount = Number(mintForm.value.tokenAmount)
    await CeroSystemApi.mintToken(mintForm.value)

    toast.success(`token minted to user ${mintForm.value.user}`)
  } catch (error) {
    toast.error(error)
  }

  loadingMintForm.value = false
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
