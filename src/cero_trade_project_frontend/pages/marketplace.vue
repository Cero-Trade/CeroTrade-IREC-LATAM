<template>
  <div id="marketplace">
    <span class="mb-4 acenter" style="color:#475467 ;font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span style="color: #00555B;">Marketplace</span>
    </span>
    <h3>Marketplace</h3>
    <span class="mbb16 mb-6" style="color:#475467;">Select any type of tokenized asset you want to buy. Every asset represents an amount of clean energy, made into an IREC. There can be multiple sellers for each asset, click on the action button to access the single IREC view.</span>

    <div class="divrow jspace">
      <div class="divrow" style="gap: 15px;">

        <v-btn class="btn" @click="dialogFilters = true">
          <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
          Add filter
        </v-btn>
      </div>

      <div class="divrow jcenter acenter" style="gap: 5px;">
        <v-btn-toggle class="center deletemobile" rounded="1" v-model="toggle">
          <v-btn class="btn-toggle" @click="windowStep = 1"><img src="@/assets/sources/icons/table-view.svg" alt="Table icon"></v-btn>
          <v-btn class="btn-toggle" @click="windowStep = 2"><img src="@/assets/sources/icons/card-view.svg" alt="Card icon"></v-btn>
        </v-btn-toggle>
      </div>
    </div>

    <v-window v-model="windowStep">
      <v-window-item :value="1">
        <v-data-table
        v-model:items-per-page="itemsPerPage"
        :items-per-page-options="[
          {value: 10, title: '10'},
          {value: 25, title: '25'},
          {value: 50, title: '50'},
        ]"
        :headers="headers"
        :items="dataMarketplace"
        :items-length="totalPages"
        :loading="loading"
        class="mt-6 my-data-table"
        density="compact"
        @update:options="getData"
        >
          <template #[`item.token_id`]="{ item }">
            <span class="acenter bold" style="color: #475467;">
              {{ item.token_id }} 
            </span>
          </template>

          <template #[`item.energy_source`]="{ item }">
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energies[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
              {{ item.energy_source }}
            </span>
          </template>

          <template #[`item.price`]="{ item }">
            <span class="divrow jspace acenter">
              {{ item.price }} <v-sheet class="chip-currency bold">ICP</v-sheet>
            </span>
          </template>

          <template #[`item.country`]="{ item }">
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="countriesImg[item.country]" :alt="`${item.country} Icon`" style="width: 20px;">
              {{ item.country }}
            </span>
          </template>

          <template #[`item.mwh`]="{ item }">
            <span class="divrow acenter">
              <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon">
              {{ item.mwh }}
            </span>
          </template>

          <template #[`item.actions`]="{ item }">
            <v-chip @click="goDetails(item)" color="white" class="chip-table mr-1" style="border-radius: 10px!important;">
              <img src="@/assets/sources/icons/wallet.svg" alt="wallet">
            </v-chip>
          </template>
        </v-data-table>
      </v-window-item>


      <v-window-item :value="2" class="pa-2">
        <v-row class="mt-6">
          <v-progress-circular
            v-if="loading"
            indeterminate
            size="60"
            color="rgb(var(--v-theme-primary))"
            class="mx-auto my-16"
          ></v-progress-circular>

          <span v-else-if="!dataMarketplace.length" class="text-center mx-auto my-16">No data available</span>

          <v-col v-else v-for="(item,index) in dataMarketplace" :key="index" xl="3" lg="3" md="4" sm="6" cols="12">
            <v-card class="card cards-marketplace">
              <div class="divrow jspace acenter mb-6">
                <div class="divcol astart" style="gap: 5px;">
                  <span style="color: #475467;">Asset id</span>
                  <h6 class="mb-0 font700">{{ item.token_id }}</h6>
                </div>

                <v-btn class="btn" @click="goDetails(item)">
                  <img src="@/assets/sources/icons/wallet.svg" alt="wallet">
                </v-btn>
              </div>

              <div class="jspace divrow mb-1">
                <span>Price</span>
                <span style="color: #475467;">{{ item.currency }} {{ item.price }}</span>
              </div>

              <div class="jspace divrow mb-1">
                <span>Energy source</span>
                <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap; color: #475467;">
                  <img :src="energies[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
                  {{ item.energy_source }}
                </span>
              </div>

              <div class="jspace divrow mb-1">
                <span>Country</span>
                <span style="color: #475467;" class="acenter text-capitalize">
                  <img :src="countriesImg[item.country]" alt="icon" class="mr-1" style="width: 20px;"> {{ item.country }}
                </span>
              </div>

              <div class="jspace divrow mb-1">
                <span>MWh</span>
                <span class="d-flex flex-acenter mr-1" style="color: #475467;">
                  <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon" style="width: 20px">
                {{ item.mwh }}</span>
              </div>

              <div class="jspace divrow mb-1">
                <span>Volume</span>
                <span style="color: #475467;">{{ item.volume }}</span>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </v-window-item>
    </v-window>


    <v-pagination
      v-model="currentPage"
      :length="totalPages"
      :disabled="loading"
      class="mt-4"
      @update:model-value="getData()"
    ></v-pagination>



    <!-- Dialog Filters -->
    <v-dialog v-model="dialogFilters" persistent width="100%" min-width="290" max-width="500">
      <v-card class="card dialog-card-detokenize d-flex flex-column" style="min-width: 100% !important">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogFilters = false">

        <div class="d-flex mb-2 align-center" style="gap: 10px">
          <v-sheet class="double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon" style="width: 22px">
            </v-sheet>
          </v-sheet>

          <h6 class="mb-0">Filters</h6>
        </div>


        <v-btn
          class="btn mb-4 ml-auto"
          style="background-color: #fff !important; width: max-content !important"
          @click="Object.keys(filters).forEach(e => filters[e] = null)"
        >clear all</v-btn>

        <v-autocomplete
          v-model="filters.country"
          :items="countries"
          variant="outlined"
          flat elevation="0"
          item-title="name"
          item-value="name"
          label="country"
          class="select mb-4"
        ></v-autocomplete>

        <v-range-slider
          v-model="filters.priceRange"
          :min="0"
          :max="1000"
          :step="1"
          variant="solo"
          elevation="0"
          label="Price range"
          :thumb-label="filters.priceRange ? 'always' : false"
          class="align-center mt-3"
        ></v-range-slider>

        <label>Asset types</label>
        <v-chip-group
          v-model="filters.assetTypes"
          column
          multiple
        >
          <v-chip
            v-for="(value, key, i) in energies" :key="i"
            variant="outlined"
            rounded="50"
            filter
          >
            <img :src="value" :alt="`${key} energy`" class="mr-2"> {{ key }}
          </v-chip>
        </v-chip-group>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogFilters = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogFilters = false; getData()" style="border: none!important;">Apply</v-btn>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup>
import '@/assets/styles/pages/marketplace.scss'
import countries from '@/assets/sources/json/countries-all.json'
import HydroEnergyIcon from '@/assets/sources/energies/hydro-color.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar-color.svg'
import ChileIcon from '@/assets/sources/icons/CL.svg'
import { useRouter } from 'vue-router'
import { computed, onBeforeMount, watch, ref } from 'vue'
import { useToast } from 'vue-toastification'
import { AgentCanister } from '@/repository/agent-canister'

const
  router = useRouter(),
  toast = useToast(),

tabsMobile = ref(1),
windowStep = ref(undefined),
allItems = ref('All items'),
items = ref(['All items', 'Items']),
items_timeline = ref(['Timeline', 'Others']),
timeline = ref('Timeline'),
toggle = ref(0),

energies = {
  "Solar": SolarEnergyIcon,
  "Wind": WindEnergyIcon,
  "Hydro-Electric": HydroEnergyIcon,
  "Thermal": GeothermalEnergyIcon,
},
countriesImg = {
  CL: ChileIcon
},

dialogFilters = ref(false),
filters = ref({
  country: null,
  assetTypes: null,
  priceRange: null,
}),

headers = [
  { title: 'Asset ID', key: 'token_id', sortable: false },
  { title: 'Energy source', key: 'energy_source', sortable: false },
  { title: 'Country', key: 'country', sortable: false },
  { title: 'Price (ICP)', key: 'price', sortable: false },
  { title: 'MWh', key: 'mwh', sortable: false },
  { title: 'Volume Produced', key: 'volume', sortable: false },
  { title: 'Actions', key: 'actions', sortable: false, align: 'center'},
],
dataMarketplace = ref([]),
loading = ref(true),
currentPage = ref(1),
itemsPerPage = ref(50),
totalPages = ref(1),


windowStepComputed = computed(() => {
  if (window.innerWidth > 960) {
    return 1;
  } else {
    return 2;
  }
})


watch(windowStepComputed, (value) => windowStep.value = value)


onBeforeMount(() => {
  windowStep.value = windowStepComputed.value;
  getData()
})


async function getData() {
  loading.value = true

  // map asset types
  const assetTypes = []
  for (const index of filters.value.assetTypes ?? []) assetTypes.push(Object.keys(energies)[index])

  try {
    // get getMarketplace
    const { data: marketplace, totalPages: pages } = await AgentCanister.getMarketplace({
      page: currentPage.value,
      length: itemsPerPage.value,
      country: filters.value.country?.toLowerCase(),
      assetTypes,
      priceRange: filters.value.priceRange,
    }),
    list = []

    // build dataMarketplace
    for (const item of marketplace) {
      list.push({
        token_id: item.tokenId,
        energy_source: item.assetInfo.deviceDetails.deviceType,
        country: item.assetInfo.specifications.country,
        price: item.lowerPriceE8S === item.higherPriceE8S ? item.higherPriceE8S : `${item.lowerPriceE8S} - ${item.higherPriceE8S}`,
        mwh: item.mwh,
        volume: item.assetInfo.volumeProduced,
      })
    }

    dataMarketplace.value = list.sort((a, b) => a.token_id - b.token_id)
    totalPages.value = pages > 5 ? 5 : pages
  } catch (error) {
    toast.error(error)
  }

  loading.value = false
}

function goDetails({ token_id: tokenId }, input) {
  const query = { tokenId }
  if (input) query.input = input

  router.push({ path: '/token-details', query })
}
</script>
