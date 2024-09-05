<template>
  <div id="my-portfolio">
    <span class="mb-4 acenter" style="color:#475467; font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1"> 
      My portfolio
    </span>
    <h3>My portfolio</h3>
    <div class="jspace wrap mb-16" style="gap: 10px;">    
      <span style="color:#475467; max-width: 640px">
        Overview and management of your tokenized assets. Track performance, manage sales, and view asset redemption status in one convenient location.
      </span>

      <div class="flex-center" style="gap: 20px;">
        <v-btn class="btn2" style="--bg: rgb(var(--v-theme-primary))" @click="$router.push('/my-transactions')">My Transactions</v-btn>

        <v-btn class="btn2" @click="$router.push({ path: '/settings', query: { editProfile: true } })">
          <img src="@/assets/sources/icons/pencil.svg" alt="pencil icon">
          Edit profile information
        </v-btn>
      </div>
    </div>

    <v-row>
      <v-col lg="9" md="8" cols="12">
        <v-card class="card" style="min-height: 100%!important;">
          <h6>Renewable sources</h6>
          <renewable-chart
            height="250"
            :series="series"
            :categories="categories"
          />
        </v-card>
      </v-col>

      <v-col xl="2" lg="2" md="4" cols="12" class="delete-mobile d-flex flex-column" style="gap: 20px;">
        <v-card class="card card-mwh d-flex flex-column-jcenter flex-grow-1">
          <h6>Total MWh</h6>
          <h5 >{{ totalMwh }} MWh</h5>
        </v-card>

        <v-card class="card card-mwh d-flex flex-column-jcenter flex-grow-1">
          <h6>Redeemed MWh</h6>
          <h5>{{ totalRedeemed }} MWh</h5>
        </v-card>
      </v-col>
    </v-row>

    <div class="divrow jspace mt-4">
      <div class="divrow" style="gap: 15px;">
        <v-btn class="btn" @click="dialogFilters = true">
          <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
          Add filter
        </v-btn>
      </div>

      <div class="divrow jcenter acenter" style="gap: 5px;">
        <v-btn-toggle class="center delete-mobile" rounded="1" v-model="toggle">
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
        :items="dataPortfolio"
        :items-length="totalPages"
        :loading="loadingPortfolio"
        class="mt-6 my-data-table"
        density="compact"
        @update:options="getData"
        >
          <template #[`item.actions`]="{ item }">
            <v-chip @click="goDetails(item)" color="white" class="chip-table" style="border-radius: 10px!important;">
              <img src="@/assets/sources/icons/wallet.svg" alt="wallet">
            </v-chip>
          </template>

          <template #[`item.asset_id`]="{ item }">
            <span class="acenter bold" style="color: #475467;">
              {{ item.asset_id }} 
            </span>
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
      </v-window-item>

      <v-window-item :value="2" class="pa-2">
        <v-row class="mt-6">
          <v-progress-circular
            v-if="loadingPortfolio"
            indeterminate
            size="60"
            color="rgb(var(--v-theme-primary))"
            class="mx-auto my-16"
          ></v-progress-circular>

          <span v-else-if="!dataPortfolio.length" class="text-center mx-auto my-16">No data available</span>

          <v-col v-else v-for="(item,index) in dataPortfolio" :key="index" xl="3" lg="3" md="4" sm="6" cols="12">
            <v-card class="card cards-marketplace">
              <div class="divrow jspace acenter mb-6">
                <div class="divrow center" style="gap: 5px;">
                  <h6 class="mb-0 font700" :title="item.token_id">Asset # {{ shortString(item.token_id, {}) }}</h6>
                </div>

                <v-chip @click="goDetails(item)" color="white" class="chip-table" style="border-radius: 10px!important;">
                  <img src="@/assets/sources/icons/wallet.svg" alt="wallet">
                </v-chip>
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

              <!-- <div class="jspace divrow mb-1">
                <span>Assets ID</span>
                <span style="color: #475467;">#{{ item.id }}</span>
              </div> -->

              <div class="jspace divrow mb-1">
                <span>MWh</span>
                <span class="d-flex flex-acenter mr-1" style="color: #475467;">
                  <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon" style="width: 20px">
                {{ item.mwh }}</span>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </v-window-item>
    </v-window>


    <v-pagination
      v-model="currentPage"
      :length="totalPages"
      :disabled="loadingPortfolio"
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
          v-model="filters.mwhRange"
          :min="0"
          :max="1000"
          :step="1"
          variant="solo"
          elevation="0"
          label="Mwh range"
          :thumb-label="filters.mwhRange ? 'always' : false"
          class="align-center mt-3"
          hide-details
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
import '@/assets/styles/pages/my-portfolio.scss'
import countries from '@/assets/sources/json/countries-all.json'
import RenewableChart from "@/components/renewable-chart.vue"
import HydroEnergyIcon from '@/assets/sources/energies/hydro-color.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar-color.svg'
import ChileIcon from '@/assets/sources/icons/CL.svg'
import WalletIcon from '@/assets/sources/icons/wallet-light.svg'
import TokenizedIcon from '@/assets/sources/icons/tokenized-table.svg'
import RedeemedIcon from '@/assets/sources/icons/redeemed-table.svg'
import { AgentCanister } from '@/repository/agent-canister'
import { ref, computed, watch, onBeforeMount } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import { formatAmount, shortString } from '@/plugins/functions'
// import { closeLoader, showLoader } from '@/plugins/functions'

const
  router = useRouter(),
  toast = useToast(),

windowStep = ref(undefined),
tabsWindow = ref(0),

dialogFilters = ref(),
filters = ref({
  country: null,
  mwhRange: null,
  assetTypes: null,
}),

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
  { title: 'Token ID', key: 'token_id', sortable: false, align: "center" },
  { title: 'Energy source', key: 'energy_source', sortable: false },
  { title: 'Country', key: 'country', sortable: false },
  // { title: 'Asset ID', key: 'asset_id', sortable: false },
  { title: 'MWh', key: 'mwh', sortable: false },
  { title: 'Details', key: 'actions', sortable: false, align: 'center'},
],
dataPortfolio = ref([
  // { 
  //   token_id: 1,
  //   // asset_id: '1234567',
  //   price: 125.00,
  //   energy_source: 'hydro energy',
  //   country: 'chile',
  //   mwh: 32,
  //   volume: 7654,
  //   checkbox: false,
  // },
]),
loadingPortfolio = ref(true),
currentPage = ref(1),
itemsPerPage = ref(50),
totalPages = ref(1),
totalRedeemed = ref(0),

allItems = 'All items',
items = ['All items', 'Items'],
items_timeline = ['Timeline', 'Others'],
timeline = 'Timeline',
toggle = ref(0),

series = ref(undefined),
categories = ref(undefined),


windowStepComputed = computed(() => {
  if (window.innerWidth > 960) {
    return 1;
  } else {
    return 2;
  }
}),
totalMwh = computed(() => {
  if (!series.value) return 0
  const data = series.value[0].data
  return formatAmount(data.reduce((acc, item) => acc + item, 0), { compact: true })
})


watch(windowStepComputed, (newVal) => windowStep.value = newVal)


onBeforeMount(() => {
  windowStep.value = windowStepComputed.value;
  getData()
})


async function getData() {
  loadingPortfolio.value = true

  // map asset types
  const assetTypes = []
  for (const index of filters.value.assetTypes ?? []) assetTypes.push(Object.keys(energies)[index])

  try {
    // get getPortfolio
    const { data, totalPages: pages } = await AgentCanister.getPortfolio({
      length: itemsPerPage.value,
      country: filters.value.country?.toLowerCase(),
      mwhRange: filters.value.mwhRange,
      assetTypes,
      page: currentPage.value,
    }),
    list = []

    for (const item of data) {
      list.push({
        token_id: item.tokenInfo.tokenId,
        energy_source: item.tokenInfo.assetInfo.deviceDetails.deviceType,
        country: item.tokenInfo.assetInfo.specifications.country,
        mwh: item.tokenInfo.totalAmount,
        redemptions: item.redemptions,
      })
    }

    dataPortfolio.value = list.sort((a, b) => a.token_id - b.token_id)
    totalPages.value = pages

    const groupedTokens = list.reduce((acc, item) => {
      let existenceElement = acc.find(elem => elem.energy_source === item.energy_source);

      if (existenceElement) {
        existenceElement.mwh += item.mwh;
        existenceElement.redeemed ??= 0
        existenceElement.redeemed += item.redemptions.reduce((acc, value) => acc + value, 0)
      } else {
        acc.push({ ...item, redeemed: item.redemptions.reduce((acc, value) => acc + value, 0) });
      }
      return acc;
    }, []),
    groupedRedemptions = groupedTokens.map(e => formatAmount(e.redeemed ?? 0, { compact: true }))

    series.value = [
      {
        name: 'MWh',
        data: groupedTokens.map(e => formatAmount(e.mwh ?? 0, { compact: true }))
      },
      {
        name: 'Redeemed',
        data: groupedRedemptions
      }
    ]
    if (groupedTokens.length) categories.value = groupedTokens.map(e => e.energy_source)

    totalRedeemed.value = formatAmount(groupedRedemptions.reduce((acc, item) => acc + item, 0) ?? 0, { compact: true })
  } catch (error) {
    console.error(error);
    toast.error(error)
  }

  loadingPortfolio.value = false
}

function goDetails({ token_id: tokenId }) {
  router.push({ path: '/token-details', query: { tokenId } })
}
</script>