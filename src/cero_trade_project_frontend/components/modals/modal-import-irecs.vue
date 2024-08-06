<template>
  <v-dialog v-model="model" :persistent="windowStep !== 3" content-class="modal-import-irecs">
    <v-card
      class="card card-dialog-company"
      :style="windowStep === 2 ? 'width: min(100%, 644px) !important' : 'width: min(100%, 390px) !important'"
    >
      <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="model = false">

      <img
        v-if="windowStep !== 1"
        src="@/assets/sources/icons/lightning-green-circle.svg" alt="check icon"
        class="mb-4"
        style="width: 65px; height: 66.56px;"
      >
      <v-sheet v-else class="mb-4 double-sheet">
        <v-sheet>
          <img src="@/assets/sources/icons/check-verified.svg" alt="check icon" style="width: 25px">
        </v-sheet>
      </v-sheet>


      <v-window v-model="windowStep">
        <v-window-item :value="1">
          <h5>Import your IRECs</h5>

          <p>Press check in order to verify any new IREC assets linked to your account in our Evident Platform Operator account.</p>


          <v-chip
            v-if="!assets"
            color="var(--loader-bg-color)"
            class="loader-chip"
            style="width: 100% !important; border-radius: 12px !important;"
          >
            <img src="@/assets/sources/icons/loader-orange.svg" alt="loader orange" class="rotate-infinite" style="translate: 0 -10px;">

            <div class="d-flex flex-column ml-2">
              <span>Verifying information</span>
              <span>Looking for your assets.</span>
            </div>
          </v-chip>


          <v-btn
            :loading="!assets"
            class="btn mt-4" style="border: none!important;width: 100% !important;"
            @click="importUserTokens"
          >Check</v-btn>
        </v-window-item>


        <v-window-item :value="2">
          <h5>Import successful</h5>

          <p>Your assets were succesfully tokenized and linked to your account. You can find them in your portafolio.</p>

          <v-data-table
            :headers="headers"
            :items="assets"
            :loading="!assets"
            class="mt-6 my-data-table hide-footer"
            density="compact"
          >
            <template #[`item.assetInfo.tokenId`]="{ item }">
              <span class="acenter bold" style="color: #475467;">{{ item.assetInfo.tokenId }} </span>
            </template>

            <template #[`item.assetInfo.startDate`]="{ item }">
              <span class="acenter bold" style="color: #475467; width: 150px">{{ item.assetInfo.startDate.toDateString() }}</span>
            </template>

            <template #[`item.assetInfo.deviceDetails.deviceType`]="{ item }">
              <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                <img :src="energies[item.assetInfo.deviceDetails.deviceType]" :alt="`${item.assetInfo.deviceDetails.deviceType} icon`" style="width: 20px;">
                {{ item.assetInfo.deviceDetails.deviceType }} Energy
              </span>
            </template>

            <template #[`item.mwh`]="{ item }">
              <span class="divrow acenter">
                <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon">
                {{ item.mwh }}
              </span>
            </template>

            <template #[`item.assetInfo.specifications.country`]="{ item }">
              <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                <img :src="countriesImg[item.assetInfo.specifications.country]" :alt="`${item.assetInfo.specifications.country} Icon`" style="width: 20px;">
                {{ item.assetInfo.specifications.country }}
              </span>
            </template>
          </v-data-table>


          <v-btn
            class="btn mt-4" style="border: none!important;width: 100% !important;"
            @click="router.push('/my-portfolio')"
          >Go to portfolio</v-btn>
        </v-window-item>


        <v-window-item :value="3">
          <h5>No item to be imported</h5>

          <p>You have not assets pending for tokenize. You can checkout all assets owned in portafolio.</p>

          <v-btn
            class="btn mt-4" style="border: none!important;width: 100% !important;"
            @click="router.push('/my-portfolio')"
          >Go to portfolio</v-btn>
        </v-window-item>
      </v-window>
    </v-card>
  </v-dialog>
</template>

<script setup>
import HydroEnergyIcon from '@/assets/sources/energies/hydro-color.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar-color.svg'
import ChileIcon from '@/assets/sources/icons/CL.svg'
import { ref, watch } from 'vue'
import { useRouter } from 'vue-router';
import { useToast } from 'vue-toastification';
import { AgentCanister } from '@/repository/agent-canister'

const
  router = useRouter(),
  toast = useToast(),

model = ref(false),
windowStep = ref(1),

energies = {
  "Solar": SolarEnergyIcon,
  "Wind": WindEnergyIcon,
  "Hydro-Electric": HydroEnergyIcon,
  "Thermal": GeothermalEnergyIcon,
},
countriesImg = {
  CL: ChileIcon
},
headers = [
  { title: 'Date', sortable: false, key: 'assetInfo.startDate' },
  { title: 'Asset ID', sortable: false, key: 'assetInfo.tokenId' },
  { title: 'Energy source', sortable: false, key: 'assetInfo.deviceDetails.deviceType' },
  { title: 'MWh', key: 'mwh', sortable: false },
  { title: 'Country', key: 'assetInfo.specifications.country', sortable: false },
],
assets = ref([])

defineExpose({ model })


watch(model, (value) => {
  if (value) return

  assets.value = []
  windowStep.value = 1
})


async function importUserTokens() {
  if (!assets.value) return
  assets.value = null

  try {
    const result = await AgentCanister.importUserTokens()
    assets.value = result

    if (assets.value.length) windowStep.value = 2
    else windowStep.value = 3

  } catch (error) {
    assets.value = []
    toast.error(error.toString())
  }
}
</script>

<style lang="scss">
.modal-import-irecs {
  h5 {
    font-size: 18px !important;
    font-weight: 700 !important;
    color: #101828 !important;
  }

  p {
    font-size: 14px !important;
    font-weight: 400 !important;
    color: #475467 !important;
  }
}
</style>
