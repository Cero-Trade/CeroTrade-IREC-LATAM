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

        <v-btn class="btn ml-auto" to="/transactions-audit">
          Transactions audit
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
      <template #[`item.tx_id`]="{ item }">
        <span class="flex-center wbold" style="color: #475467;">{{ item.tx_id }}</span>
      </template>

      <template #item.type="{ item }">
        <span class="text-capitalize w700" :style="`
          color: ${item.type === TxType.purchase ? '#00555B'
          : item.type === TxType.redemption ? '#5A02CA'
          : '#2970FF'
        } !important`">{{ item.type }}</span>
      </template>

      <template #[`item.recipent`]="{ item }">
        <v-menu :close-on-content-click="false" location="bottom center">
          <template #activator="{ props }">
            <a v-bind="props" class="flex-acenter pointer" style="gap: 5px; text-wrap: nowrap; text-decoration: underline !important;">{{ item.recipent.name }}</a>
          </template>

          <v-card class="px-4 py-2 bg-secondary">
            <span>id: {{ item.recipent.principal.toString() }}</span>
          </v-card>
        </v-menu>
      </template>

      <template #[`item.sender`]="{ item }">
        <v-menu :close-on-content-click="false" location="bottom center">
          <template #activator="{ props }">
            <a v-bind="props" class="flex-acenter pointer" style="gap: 5px; text-wrap: nowrap; text-decoration: underline !important;">{{ item.sender.name }}</a>
          </template>

          <v-card class="px-4 py-2 bg-secondary">
            <span>id: {{ item.sender.principal.toString() }}</span>
          </v-card>
        </v-menu>
      </template>

      <template #[`item.energy_source`]="{ item }">
        <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
          <img :src="energies[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
          {{ item.energy_source }}
        </span>
      </template>

      <template #[`item.asset_id`]="{ item }">
        <span class="acenter" :title="item.asset_id">{{ shortString(item.asset_id, {}) }} </span>
      </template>

      <template #[`item.price`]="{ item }">
        <span v-if="!item.price">---</span>

        <span v-else class="flex-center">
          {{ exponentToString(item.price) }} <v-sheet class="chip-currency bold">ICP</v-sheet>
        </span>
      </template>

      <template #[`item.date`]="{ item }">
        <span class="divrow jspace acenter" style="min-width: 100px;">{{ item.date }}</span>
      </template>

      <template #[`item.country`]="{ item }">
        <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
          <img :src="countries[item.country].flag" :alt="`${item.country} Icon`" style="width: 20px;">
          {{ item.country }}
        </span>
      </template>

      <template #[`item.mwh`]="{ item }">
        <span class="flex-acenter">
          <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon">
          {{ exponentToString(item.mwh) }}
        </span>
      </template>
      
      <template #item.via="{ item }">
        <span style="text-wrap: nowrap">{{ item.via }}</span>
      </template>

      <template #[`item.token_tx_index`]="{ item }">
        <span v-if="!item.token_tx_index">---</span>

        <span v-else class="pointer acenter" :title="item.token_tx_index" @click="item.token_tx_index.copyToClipboard('Token Tx Block copied')">
          {{ shortString(item.token_tx_index, {}) }}
          <img src="@/assets/sources/icons/copy.svg" alt="copy icon" class="ml-2" style="width: 18px">
        </span>
      </template>

      <template #[`item.ledger_tx_hash`]="{ item }">
        <span v-if="!item.ledger_tx_hash">---</span>

        <a v-else :title="item.ledger_tx_hash" :href="`${ICPExplorerUrl}/${item.ledger_tx_hash}`" target="_blank" class="text-label flex-center" style="gap: 5px">
          {{ shortString(item.ledger_tx_hash, {}) }}
          <img src="@/assets/sources/icons/share.svg" alt="explorer icon" style="width: 16px">
        </a>
      </template>

      <template #[`item.comission_tx_hash`]="{ item }">
        <span v-if="!item.comission_tx_hash">---</span>

        <a v-else :title="item.comission_tx_hash" :href="`${ICPExplorerUrl}/${item.comission_tx_hash}`" target="_blank" class="text-label flex-center" style="gap: 5px">
          {{ shortString(item.comission_tx_hash, {}) }}
          <img src="@/assets/sources/icons/share.svg" alt="explorer icon" style="width: 16px">
        </a>
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
            :items="Object.values(countries)"
            variant="outlined"
            flat elevation="0"
            menu-icon=""
            item-title="name"
            item-value="code"
            label="country"
            class="select mb-4"
          >
          <template #append-inner="{ isFocused }">
            <img
              src="@/assets/sources/icons/chevron-down.svg"
              alt="chevron-down icon"
              :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
            >
          </template>

          <template #selection="{ item }">
            <v-img-load
              :src="item.raw.flag.toString()"
              :alt="`${item.raw.name} logo`"
              cover
              sizes="25px"
              rounded="50%"
              class="flex-grow-0"
            />
            <span class="bold ml-2 ellipsis-text">{{ item.raw.name }}</span>
          </template>

          <template #item="{ item, props }">
            <v-list-item v-bind="props" title=" ">
              <div class="d-flex align-center">
                <v-img-load
                  :src="item.raw.flag.toString()"
                  :alt="`${item.raw.name} logo`"
                  cover
                  sizes="25px"
                  rounded="50%"
                  class="flex-grow-0"
                />
                <span class="bold ml-2" style="translate: 0 1px">{{ item.raw.name }}</span>
              </div>
            </v-list-item>
          </template>
        </v-autocomplete>

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
import { exponentToString, shortPrincipalId, shortString } from '@/plugins/functions'
import variables from '@/mixins/variables'

const
  router = useRouter(),
  toast = useToast(),
  { countries, ICPExplorerUrl } = variables,

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

  headers = [
  // { title: '', key: 'checkbox', sortable: false, align: 'center'},
  { title: 'Tx ID', key: 'tx_id', align: 'center', sortable: false, width: "90px" },
  { title: 'Type', key: 'type', align: 'center', sortable: false },
  { title: 'Asset ID', key: 'asset_id', align: 'center', sortable: false },
  { title: 'Energy source', key: 'energy_source', align: 'center', sortable: false },
  { title: 'Price (ICP)', key: 'price', align: 'center', sortable: false },
  { title: 'Country', key: 'country', align: 'center', sortable: false },
  { title: 'Recipent', key: 'recipent', align: 'center', sortable: false, width: "110px" },
  { title: 'Sender', key: 'sender', align: 'center', sortable: false, width: "100px" },
  { title: 'MWh', key: 'mwh', align: 'center', sortable: false },
  { title: 'Date', key: 'date', align: 'center', sortable: false },
  { title: 'Via', key: 'via', align: 'center', sortable: false },
  { title: 'Token Tx Block', key: 'token_tx_index', align: 'center', sortable: false, width: "110px" },
  { title: 'Ledger Tx Block', key: 'ledger_tx_hash', align: 'center', sortable: false, width: "110px" },
  { title: 'Comission Tx Block', key: 'comission_tx_hash', align: 'center', sortable: false, width: "110px" },
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

previewUser = ref(null),

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
        tx_id: item.transactionId,
        type: item.txType,
        recipent: item.to || "---",
        sender: item.from || "---",
        energy_source: item.assetInfo.deviceDetails.deviceType,
        country: item.assetInfo.specifications.country,
        mwh: item.tokenAmount,
        asset_id: item.assetInfo.tokenId,
        date: item.date.toDateString(),
        price: item.priceE8S,
        via: item.method,
        token_tx_index: item.tokenTxIndex,
        comission_tx_hash: item.comissionTxHash,
        ledger_tx_hash: item.ledgerTxHash,
      })
    }

    dataTransactions.value = list.sort((a, b) => a.tx_id - b.tx_id)
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
