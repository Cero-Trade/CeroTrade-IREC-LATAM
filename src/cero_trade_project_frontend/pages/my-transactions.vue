<template>
  <div id="my-transactions">
    <span class="mb-4 acenter" style="color:#475467 ;font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span>My porfolio</span>
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span style="color: #00555B;">Transactions</span>
    </span>
    <h3>My Transactions</h3>
    <span class="mbb16 mb-6" style="color:#475467;">Here are your transactions: all your redemptions, sales, and purchases done in the platform.</span>

    <v-tabs
      v-model="tab"
      bg-color="transparent"
      color="basil"
      class="mt-2 mb-2"
      :disabled="loading"
      @update:model-value="getData"
    >
      <v-tab
        v-for="(item, i) in tabs" :key="i"
        style="border: none!important; border-bottom: 2px solid rgba(0,0,0,0.25)!important; border-radius: 0px!important;"
      >{{ item.text }}</v-tab>
    </v-tabs>

    <div class="divrow jspace flex-wrap" style="row-gap: 10px;">
      <div class="divrow" style="gap: 15px;">

        <v-btn class="btn" @click="dialogFilters = true">
          <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
          Add filter
        </v-btn>
      </div>
    </div>

    <v-data-table
      v-model:items-per-page="itemsPerPage"
      :items-per-page-options="[
        {value: 10, title: '10'},
        {value: 25, title: '25'},
        {value: 50, title: '50'},
      ]"
      :headers="headers"
      :items="dataTransactions"
      :items-length="totalPages"
      :loading="loading"
      class="mt-6 my-data-table"
      @update:options="getData"
    >
      <template #[`item.transaction_id`]="{ item }">
        <span class="flex-center wbold" style="color: #475467;">{{ item.transaction_id }}</span>
      </template>

      <template #item.type="{ item }">
        <span class="text-capitalize w700" :style="`
          color: ${item.type === TxType.transfer ? '#00555B'
          : item.type === TxType.redemption ? '#5A02CA'
          : '#2970FF'
        } !important`">{{ item.type }}</span>
      </template>
      
      <template #[`item.recipentName`]="{ item }">
        <span class="flex-acenter" style="gap: 5px; text-wrap: nowrap">
          <v-img-load
            :src="item.recipentLogo"
            :alt="`${item.recipentName} logo`"
            cover
            sizes="20px"
            rounded="50%"
            class="flex-grow-0"
          />
          {{ item.recipentName }}
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

      <template #[`item.date`]="{ item }">
        <span class="divrow jspace acenter" style="min-width: 100px;">{{ item.date }}</span>
      </template>

      <template #[`item.country`]="{ item }">
        <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
          <img :src="countriesImg[item.country]" :alt="`${item.country} Icon`" style="width: 20px;">
          {{ item.country }}
        </span>
      </template>

      <template #[`item.mwh`]="{ item }">
        <span class="flex-acenter">
          <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon">
          {{ item.mwh }}
        </span>
      </template>
      
      <template #item.via="{ item }">
        <span style="text-wrap: nowrap">{{ item.via }}</span>
      </template>
    </v-data-table>


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
          label="Mwh range"
          :thumb-label="filters.priceRange ? 'always' : false"
          class="align-center mt-3"
          hide-details
        ></v-range-slider>

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

        <v-select
          v-model="filters.method"
          :items="txMethodValues"
          variant="outlined"
          flat elevation="0"
          item-title="name"
          item-value="name"
          label="Via"
          class="select mt-3 mb-3"
          hide-details
        ></v-select>

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
import '@/assets/styles/pages/my-transactions.scss'
import countries from '@/assets/sources/json/countries-all.json'
import SphereIcon from '@/assets/sources/companies/sphere.svg'
import KapidagIcon from '@/assets/sources/companies/kapidag.svg'
import SisyphusIcon from '@/assets/sources/companies/sisyphus.svg'
import FocalPointIcon from '@/assets/sources/companies/focal-point.svg'
import SilverStoneIcon from '@/assets/sources/companies/silverstone.svg'
import GeneralElectricIcon from '@/assets/sources/companies/general-electric.svg'
import BlueSkyIcon from '@/assets/sources/companies/bluesky.svg'
import ZenithIcon from '@/assets/sources/companies/zenith.svg'
import LibertyIcon from '@/assets/sources/companies/liberty.svg'
import SunshineIcon from '@/assets/sources/companies/sunshine.svg'
import PrimeIcon from '@/assets/sources/companies/prime.svg'

import HydroEnergyIcon from '@/assets/sources/energies/hydro.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar.svg'
import ChileIcon from '@/assets/sources/icons/CL.svg'
import { ref, computed, watch, onBeforeMount } from 'vue'
import { AgentCanister } from '@/repository/agent-canister'
import { TxType, TxMethod } from '@/models/transaction-model'
import { useToast } from 'vue-toastification'
import { useRouter } from 'vue-router'

const
  router = useRouter(),
  toast = useToast(),

tabsMobile = ref(1),
windowStep = ref(undefined),
allItems = 'All items',
items = ['All items', 'Items'],
items_timeline = ['Timeline', 'Others'],
timeline = 'Timeline',
toggle = ref(0),

tab = ref(0),
tabs = [
  { text: "All", value: null, },
  { text: "Transfer", value: TxType.transfer },
  { text: "Redemption", value: TxType.redemption }
],

companies = {
  'Sphere': SphereIcon,
  'KAPIDAĞ RES': KapidagIcon,
  'Sisyphus': SisyphusIcon,
  'Focal Point': FocalPointIcon,
  'SIlverstone': SilverStoneIcon,
  'General Electric': GeneralElectricIcon,
  'BlueSky': BlueSkyIcon,
  'Zenith': ZenithIcon,
  'Liberty': LibertyIcon,
  'Sunshine': SunshineIcon,
  'Prime': PrimeIcon,
},
energies = {
  hydro: HydroEnergyIcon,
  ocean: OceanEnergyIcon,
  geothermal: GeothermalEnergyIcon,
  biome: BiomeEnergyIcon,
  wind: WindEnergyIcon,
  sun: SolarEnergyIcon,
},
countriesImg = {
  chile: ChileIcon
},

  headers = [
  // { title: '', key: 'checkbox', sortable: false, align: 'center'},
  { title: 'Transaction ID', key: 'transaction_id', align: 'center', sortable: false },
  { title: 'Type', key: 'type', sortable: false },
  { title: 'Asset ID', key: 'asset_id', sortable: false },
  { title: 'Energy source', key: 'energy_source', sortable: false },
  { title: 'Price (ICP)', key: 'price', align: 'center', sortable: false },
  { title: 'Country', key: 'country', sortable: false },
  { title: 'Recipent', key: 'recipentName', sortable: false },
  { title: 'MWh', key: 'mwh', sortable: false },
  { title: 'Date', key: 'date', sortable: false },
  { title: 'Via', key: 'via', align: 'center', sortable: false },
],
dataTransactions = ref([]),
loading = ref(true),
currentPage = ref(1),
itemsPerPage = ref(50),
totalPages = ref(1),

txMethodValues = [
  TxMethod.bankTransfer,
  TxMethod.blockchainTransfer
],

dialogFilters = ref(),
filters = ref({
  country: null,
  priceRange: null,
  mwhRange: null,
  assetTypes: null,
  method: null,
}),


windowStepComputed = computed(() => {
  if (window.innerWidth > 960) {
    return 1;
  } else {
    return 2;
  }
})


watch(windowStepComputed, (newVal) => {
  windowStep.value = newVal;

  getData()
})


onBeforeMount(() => {
  windowStep.value = windowStepComputed.value;
})


async function getData() {
  loading.value = true

  // map asset types
  const assetTypes = []
  for (const index of filters.value.assetTypes ?? []) assetTypes.push(Object.keys(energies)[index])

  try {
    // get getPortfolio
    const { data, total } = await AgentCanister.getTransactions({
      length: itemsPerPage.value,
      page: currentPage.value,
      txType: tabs[tab.value].value,
      country: filters.value.country,
      priceRange: filters.value.priceRange,
      mwhRange: filters.value.mwhRange,
      assetTypes,
      method: filters.value.method,
    }),
    list = []

    for (const item of data) {
      list.push({
        transaction_id: item.transactionId,
        type: item.txType,
        recipentName: item.recipentProfile.companyName,
        recipentLogo: item.recipentProfile.companyLogo,
        energy_source: item.assetInfo.assetType,
        country: item.assetInfo.specifications.country,
        mwh: item.tokenAmount,
        asset_id: item.assetInfo.tokenId,
        date: item.date.toDateString(),
        price: item.priceICP.e8s,
        via: item.method,
      })
    }

    dataTransactions.value = list.sort((a, b) => a.transaction_id - b.transaction_id)
    totalPages.value = total
  } catch (error) {
    console.error(error);
    toast.error(error)
  }

  loading.value = false
}

function goDetails(){
  router.push('/rec-single-my-transactions')
}
</script>
