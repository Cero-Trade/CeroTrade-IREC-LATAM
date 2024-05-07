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
          <h5 >{{ totalMwh }}MWh</h5>
        </v-card>

        <v-card class="card card-mwh d-flex flex-column-jcenter flex-grow-1">
          <h6>Redeemed MWh</h6>
          <h5>{{ totalRedeemed }}MWh</h5>
        </v-card>
      </v-col>
    </v-row>

    <div class="divrow jspace mt-4">
      <!-- TODO implements filter to portfolio -->
      <!-- <div class="divrow" style="gap: 15px;">
        <v-btn class="btn">
          <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
          Add filter
        </v-btn>
      </div> -->

      <div class="divrow jcenter acenter ml-auto" style="gap: 5px;">
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
        :headers="headers"
        :items="dataPortfolio"
        class="mt-6 my-data-table hide-footer"
        density="compact"
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
              <img :src="countries[item.country]" :alt="`${item.country} Icon`" style="width: 20px;">
              {{ item.country }}
            </span>
          </template>
        </v-data-table>
      </v-window-item>

      <v-window-item :value="2" class="pa-2">
        <v-row class="mt-6">
          <v-col v-for="(item,index) in dataPortfolio" :key="index" xl="3" lg="3" md="4" sm="6" cols="12">
            <v-card class="card cards-marketplace">
              <div class="divrow jspace acenter mb-6">
                <div class="divrow center" style="gap: 5px;">
                  <h6 class="mb-0 font700">Asset # {{ item.token_id }}</h6>
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
                  <img :src="countries[item.country]" alt="icon" class="mr-1" style="width: 20px;"> {{ item.country }}
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
  </div>
</template>

<script setup>
import '@/assets/styles/pages/my-portfolio.scss'
import checkboxCheckedIcon from '@/assets/sources/icons/checkbox-checked.svg'
import checkboxBaseIcon from '@/assets/sources/icons/checkbox-base.svg'
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
// import { closeLoader, showLoader } from '@/plugins/functions'

const
  router = useRouter(),
  toast = useToast(),

windowStep = ref(undefined),
tabsWindow = ref(0),

energies = {
  hydro: HydroEnergyIcon,
  ocean: OceanEnergyIcon,
  geothermal: GeothermalEnergyIcon,
  biome: BiomeEnergyIcon,
  wind: WindEnergyIcon,
  sun: SolarEnergyIcon,
},
countries = {
  chile: ChileIcon
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
  return data.reduce((acc, item) => acc + item, 0)
})


watch(windowStepComputed, (newVal) => windowStep.value = newVal)


onBeforeMount(() => {
  windowStep.value = windowStepComputed.value;
  getData()
})


async function getData() {
  try {
    const { tokensInfo, tokensRedemption } = await AgentCanister.getPortfolio(),
    list = []

    for (const item of tokensInfo) {
      list.push({
        token_id: item.tokenId,
        energy_source: item.assetInfo.assetType,
        country: item.assetInfo.specifications.country,
        mwh: item.totalAmount,
      })
    }

    dataPortfolio.value = list.sort((a, b) => a.token_id - b.token_id)

    const groupedTokens = list.reduce((acc, item) => {
      let existenceElement = acc.find(elem => elem.energy_source === item.energy_source);

      if (existenceElement) {
        existenceElement.mwh += item.mwh;
      } else {
        acc.push({ ...item });
      }
      return acc;
    }, []);

    const groupedRedemptions = tokensRedemption.reduce((acc, item) => {
      let existenceElement = acc.find(elem => elem.tokenId === item.tokenId);

      if (existenceElement) {
        existenceElement.tokenAmount += item.tokenAmount;
      } else {
        acc.push({ ...item });
      }
      return acc;
    }, []);


    series.value = [
      {
        name: 'MWh',
        data: groupedTokens.map(e => e.mwh || 0)
      },
      {
        name: 'Redeemed',
        data: groupedRedemptions.map(e => e.tokenAmount || 0)
      }
    ]
    if (groupedTokens.length) categories.value = groupedTokens.map(e => e.energy_source)

    totalRedeemed.value = groupedRedemptions.reduce((acc, item) => acc + item.tokenAmount, 0) || 0
  } catch (error) {
    console.error(error);
    toast.error(error)
  }
}

function goDetails({ token_id: tokenId }) {
  router.push({ path: '/token-details', query: { tokenId } })
}
</script>