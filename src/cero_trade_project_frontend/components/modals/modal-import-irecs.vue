<template>
  <v-dialog v-model="model" :persistent="windowStep !== 3" content-class="modal-import-irecs">
    <v-card
      class="card card-dialog-company"
      :style="windowStep === 2 ? 'width: min(100%, 644px) !important' : 'width: min(100%, 390px) !important'"
    >
      <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="model = false">

      <img
        v-if="windowStep === 3"
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

          <p>Submit your Evident account number so we can look for any asset transactions that haven’t been added to our marketplace.</p>


          <v-chip
            v-if="!transactions"
            color="var(--loader-bg-color)"
            class="loader-chip"
            style="width: 100% !important; border-radius: 12px !important;"
          >
            <img src="@/assets/sources/icons/loader-orange.svg" alt="loader orange" class="rotate-infinite" style="translate: 0 -10px;">

            <div class="d-flex flex-column ml-2">
              <span>Verifying information</span>
              <span>Looking for your transactions.</span>
            </div>
          </v-chip>


          <v-form v-model="formValid" @submit.prevent>
            <label for="account-number">Account number</label>
            <v-text-field
              id="account-number"
              v-model="accountNumber"
              placeholder="Enter Account Number"
              variant="outlined"
              density="compact"
              :rules="[globalRules.required]"
              @keyup="({ key }) => { if (key === 'Enter') getTransactions() }"
            >
              <template #append-inner>
                <v-tooltip location="top">
                  <template #activator="{ props }">
                    <img src="@/assets/sources/icons/help-circle.svg" alt="info icon" v-bind="props">
                  </template>

                  <span>This is your account identifier number from evident</span>
                </v-tooltip>
              </template>
            </v-text-field>
          </v-form>

          <v-btn
            :disabled="!formValid"
            :loading="!transactions"
            class="btn mt-4" style="border: none!important;width: 100% !important;"
            @click="getTransactions"
          >Submit</v-btn>
        </v-window-item>


        <v-window-item :value="2">
          <h5>Import your IRECs</h5>

          <p>Select the assets that you wish to add to your portafolio.</p>

          <v-data-table
            :headers="headers"
            :items="transactions"
            :loading="!transactions"
            class="mt-6 my-data-table hide-footer"
            density="compact"
          >
            <template #[`item.checkbox`]="{ item }">
              <v-checkbox
                v-model="item.checkbox"
                hide-details
                density="compact"
                class="mx-auto"
                style="max-width: 22px!important; min-width: 22px!important;"
              >
                <template #input="{ model }">
                  <img
                    :src="model.value ? checkboxCheckedIcon : checkboxBaseIcon"
                    alt="checkbox icon"
                    style="width: 22px"
                    @click="model.value = !model.value"
                  >
                </template>
              </v-checkbox>
            </template>

            <template #[`item.asset_id`]="{ item }">
              <span class="acenter bold" style="color: #475467;">{{ item.asset_id }} </span>
            </template>

            <template #[`item.energy_source`]="{ item }">
              <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                <img :src="energies[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
                {{ item.energy_source }} Energy
              </span>
            </template>

            <template #[`item.mwh`]="{ item }">
              <span class="divrow acenter">
                <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon">
                {{ item.mwh }}
              </span>
            </template>

            <template #[`item.country`]="{ item }">
              <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                <img :src="countriesImg[item.country]" :alt="`${item.country} Icon`" style="width: 20px;">
                {{ item.country }}
              </span>
            </template>
          </v-data-table>


          <v-btn
            :disabled="!selectedTxs.length"
            :loading="loadingIrecs"
            class="btn mt-4" style="border: none!important;width: 100% !important;"
            @click="importIrecs"
          >Submit</v-btn>
        </v-window-item>


        <v-window-item :value="3">
          <h5>Import successful</h5>

          <p>Your assets were succesfully tokenized and linked to your account. You can find them in your portafolio.</p>

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
import checkboxCheckedIcon from '@/assets/sources/icons/checkbox-checked.svg'
import checkboxBaseIcon from '@/assets/sources/icons/checkbox-base.svg'
import HydroEnergyIcon from '@/assets/sources/energies/hydro-color.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar-color.svg'
import ChileIcon from '@/assets/sources/icons/CL.svg'
import variables from '@/mixins/variables';
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router';
import { useToast } from 'vue-toastification';

const
  router = useRouter(),
  toast = useToast(),
  { globalRules } = variables,

model = ref(false),
windowStep = ref(1),
formValid = ref(false),
accountNumber = ref(null),

energies = {
  hydro: HydroEnergyIcon,
  ocean: OceanEnergyIcon,
  geothermal: GeothermalEnergyIcon,
  biome: BiomeEnergyIcon,
  wind: WindEnergyIcon,
  sun: SolarEnergyIcon,
},
countriesImg = {
  CL: ChileIcon
},
headers = [
  { sortable: false, key: 'checkbox', align: "center" },
  { title: 'Date', sortable: false, key: 'date'},
  { title: 'Asset ID', sortable: false, key: 'asset_id'},
  { title: 'Energy source', sortable: false, key: 'energy_source'},
  { title: 'MWh', key: 'mwh', sortable: false },
  { title: 'Country', key: 'country', sortable: false },
],
transactions = ref([]),
selectedTxs = computed(() => transactions.value.filter(e => e.checkbox)),
loadingIrecs = ref(false)

defineExpose({ model })


watch(model, (value) => {
  if (value) return

  accountNumber.value = null
  transactions.value = []
  windowStep.value = 1
})

async function getTransactions() {
  transactions.value = null

  try {
    setTimeout(() => {
      transactions.value = [
        {
          checkbox: false,
          date: new Date().toDateString(),
          asset_id: "1",
          energy_source: "hydro",
          mwh: 100,
          country: "CL",
        },
        {
          checkbox: false,
          date: new Date().toDateString(),
          asset_id: "2",
          energy_source: "ocean",
          mwh: 100,
          country: "CL",
        },
      ]

      windowStep.value++
    }, 1000)
  } catch (error) {
    transactions.value = []
    toast.error(error.toString())
  }
}

async function importIrecs() {
  if (!selectedTxs.value.length || loadingIrecs.value) return
  loadingIrecs.value = true

  setTimeout(() => {
    try {
      console.log(selectedTxs.value);
      windowStep.value++
    } catch (error) {
      toast.error(error.toString())
    }

    loadingIrecs.value = false
  }, 1000);
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
