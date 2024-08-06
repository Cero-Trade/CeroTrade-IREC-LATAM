<template>
  <div id="my-transactions">
    <span class="mb-4 acenter" style="color:#475467 ;font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span>My portfolio</span>
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
          color: ${item.type === TxType.purchase ? '#00555B'
          : item.type === TxType.redemption ? '#5A02CA'
          : '#2970FF'
        } !important`">{{ item.type }}</span>
      </template>

      <template #[`item.recipent`]="{ item }">
        <v-menu :close-on-content-click="false" @update:model-value="(value) => getRecipentProfile(value, item.recipent)">
          <template #activator="{ props }">
            <a v-bind="props" class="flex-acenter pointer" style="gap: 5px; text-wrap: nowrap">{{ shortPrincipalId(item.recipent?.toString()) }}</a>
          </template>

          <v-card class="px-4 py-2 bg-secondary d-flex">
            <v-progress-circular
              v-if="!previewRecipent"
              indeterminate
              color="rgb(var(--v-theme-primary))"
              class="mx-auto"
            ></v-progress-circular>

            <span v-else class="flex-acenter" style="gap: 10px; text-wrap: nowrap">
              <v-img-load
                :src="previewRecipent.companyLogo"
                :alt="`${previewRecipent.companyName} logo`"
                cover
                sizes="30px"
                rounded="50%"
                class="flex-grow-0"
              />
              {{ previewRecipent.companyName }}
            </span>
          </v-card>
        </v-menu>
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
      <v-form ref="filtersFormRef" @submit.prevent>
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

          <div class="d-flex mb-7" style="gap: 20px;">
            <v-menu v-model="fromDateMenu" :close-on-content-click="false">
              <template v-slot:activator="{ props }">
                <v-text-field
                  v-model="filters.fromDate"
                  label="Select from date"
                  readonly v-bind="props"
                  variant="outlined"
                  density="compact"
                  class="select"
                  style="flex-basis: 50%;"
                  :rules="[(v) => {
                    if (filters.toDate && !v) return 'Must to select from date'
                    return true
                  }]"
                >
                  <template #append-inner>
                    <img
                      v-if="filters.fromDate"
                      src="@/assets/sources/icons/close.svg"
                      alt="close icon"
                      class="pointer"
                      @click="filters.fromDate = null"
                    >
                  </template>
                </v-text-field>
              </template>

              <v-date-picker
                title=""
                color="rgb(var(--v-theme-secondary))"
                hide-actions
                @update:model-value="(v) => { filters.fromDate = moment(v).format('YYYY/MM/DD') }"
              >
                <template v-slot:header></template>
              </v-date-picker>
            </v-menu>


            <v-menu v-model="toDateMenu" :close-on-content-click="false">
              <template v-slot:activator="{ props }">
                <v-text-field
                  v-model="filters.toDate"
                  label="Select to date"
                  readonly v-bind="props"
                  variant="outlined"
                  density="compact"
                  class="select"
                  style="flex-basis: 50%;"
                  :rules="[(v) => {
                    if (filters.fromDate && !v) return 'Must to select to date'
                    return true
                  }]"
                >
                  <template #append-inner>
                    <img
                      v-if="filters.toDate"
                      src="@/assets/sources/icons/close.svg" alt="close icon"
                      class="pointer"
                      @click="filters.toDate = null"
                    >
                  </template>
                </v-text-field>
              </template>

              <v-date-picker
                title=""
                color="rgb(var(--v-theme-secondary))"
                hide-actions
                @update:model-value="(v) => { filters.toDate = moment(v).format('YYYY/MM/DD') }"
              >
                <template v-slot:header></template>
              </v-date-picker>
            </v-menu>
          </div>

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
            <v-btn class="btn" @click="async () => {
              if (!(await filtersFormRef.validate()).valid) return

              dialogFilters = false;
              getData()
            }" style="border: none!important;">Apply</v-btn>
          </div>
        </v-card>
      </v-form>
    </v-dialog>
  </div>
</template>

<script setup>
import '@/assets/styles/pages/my-transactions.scss'
import countries from '@/assets/sources/json/countries-all.json'

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
import moment from "moment";
import { shortPrincipalId } from '@/plugins/functions'

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
  { text: "Sell", value: TxType.putOnSale },
  { text: "Purchase", value: TxType.purchase },
  { text: "Take off Marketplace", value: TxType.takeOffMarketplace },
  { text: "Redemption", value: TxType.redemption }
],
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
  // { title: '', key: 'checkbox', sortable: false, align: 'center'},
  { title: 'Transaction ID', key: 'transaction_id', align: 'center', sortable: false },
  { title: 'Type', key: 'type', sortable: false },
  { title: 'Asset ID', key: 'asset_id', sortable: false },
  { title: 'Energy source', key: 'energy_source', sortable: false },
  { title: 'Price (ICP)', key: 'price', align: 'center', sortable: false },
  { title: 'Country', key: 'country', sortable: false },
  { title: 'Recipent ID', key: 'recipent', sortable: false },
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

previewRecipent = ref(null),

dialogFilters = ref(),
filtersFormRef = ref(),
filters = ref({
  country: null,
  priceRange: null,
  mwhRange: null,
  assetTypes: null,
  method: null,
  fromDate: null,
  toDate: null,
}),

fromDateMenu = ref(),
toDateMenu = ref(),


windowStepComputed = computed(() => {
  if (window.innerWidth > 960) {
    return 1;
  } else {
    return 2;
  }
})


watch(fromDateMenu, (value) => {
  if (!value) filtersFormRef.value.validate()
})

watch(toDateMenu, (value) => {
  if (!value) filtersFormRef.value.validate()
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

  // map dates
  let rangeDates
  if (filters.value.fromDate && filters.value.toDate)
    rangeDates = [new Date(filters.value.fromDate), new Date(filters.value.toDate)]

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
      rangeDates,
    }),
    list = []

    for (const item of data) {
      list.push({
        transaction_id: item.transactionId,
        type: item.txType,
        recipent: item.to,
        energy_source: item.assetInfo.deviceDetails.deviceType,
        country: item.assetInfo.specifications.country,
        mwh: item.tokenAmount,
        asset_id: item.assetInfo.tokenId,
        date: item.date.toDateString(),
        price: item.priceE8S,
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

async function getRecipentProfile(value, uid) {
  if (!value) previewRecipent.value = null

  try {
    previewRecipent.value = await AgentCanister.getProfile(uid)
  } catch (error) {
    toast.error(error)
  }
}

function goDetails(){
  router.push('/rec-single-my-transactions')
}
</script>
