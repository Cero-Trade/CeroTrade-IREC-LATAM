<template>
  <div id="profile">
    <span class="mb-10 acenter" style="color: #475467; font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
       Profile
    </span>
    <div class="divrow acenter mb-4">
      <div class="div-avatar-asset mr-6">
        <img src="@/assets/sources/icons/CL.svg" alt="Flag" class="flag">
      </div>
      <h3 class="mb-0">Sphere</h3>
    </div>

    <v-btn class="btn2 ml-auto mb-4" @click="$router.push({ path: '/settings', query: { editProfile: true } })">
      <img src="@/assets/sources/icons/pencil.svg" alt="pencil icon">
      <span style="font-weight: 700 !important;">Edit profile information</span>
    </v-btn>

    <v-row>
      <v-col cols="12" class="d-flex flex-wrap justify-space-between" style="gap: 20px">
        <v-card class="card relative d-flex flex-column-jcenter flex-grow-1">
          <span>Offered MWh</span>
          <h5 class="mb-0">10MWh</h5>
        </v-card>
        
        <v-card class="card relative d-flex flex-column-jcenter flex-grow-1">
          <span>Redeemed MWh</span>
          <h5 class="mb-0">10MWh</h5>
        </v-card>
      </v-col>

      <v-col cols="12" class="mb-4">
        <v-tabs
          v-model="renewableTab"
          bg-color="transparent"
          color="basil"
          class="mb-3"
        >
          <v-tab
            v-for="(item, i) in renewableTabs" :key="i"
            :value="i"
            style="border: none!important; border-radius: 0px!important;"
          >{{ item.name }}</v-tab>
        </v-tabs>

        <v-card class="card" style="min-height: 100%!important;">
          <h6>Renewable sources</h6>
          <renewable-chart height="200" :series="seriesRenewable" />
        </v-card>
      </v-col>

      <v-col cols="12" class="marketplace-styles">
        <h5 class="mb-3 bold">Redemptions</h5>
        
        <v-tabs
          v-model="redemptionTab"
          bg-color="transparent"
          color="basil"
          class="mb-3"
        >
          <v-tab
            v-for="(item, i) in redemptionTabs" :key="i"
            :value="i"
            style="border: none!important; border-radius: 0px!important;"
          >{{ item.name }}</v-tab>
        </v-tabs>
        
        <div class="divrow jspace">
          <v-btn class="btn">
            <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
            Add filter
          </v-btn>

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
            :headers="headers"
            :items="dataMarketplace"
            class="mt-6 my-data-table"
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
                <span class="acenter bold" style="color: #475467;">
                  {{ item.asset_id }} 
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
                  {{ item.price }} <v-sheet class="chip-currency bold">{{ item.currency }}</v-sheet>
                </span>
              </template>

              <template #[`item.country`]="{ item }">
                <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                  <img :src="countries[item.country]" :alt="`${item.country} Icon`" style="width: 20px;">
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
              <v-col v-for="(item,index) in dataMarketplace" :key="index" xl="3" lg="3" md="4" sm="6" cols="12">
                <v-card class="card cards-marketplace" @click="goDetails(item)">
                  <div class="divrow jspace acenter mb-6">
                    <div class="divcol astart" style="gap: 5px;">
                      <span style="color: #475467;">Asset</span>
                      <h6 class="mb-0 font700">{{ item.asset_id }}</h6>
                      
                    </div>
                    <v-menu location="start">
                      <template v-slot:activator="{ props }">
                        <v-btn class="btn btn-dots" v-bind="props">
                          <img src="@/assets/sources/icons/dots-vertical.svg" alt="dots-vertical icon">
                        </v-btn>
                      </template>

                      <v-card class="acenter jstart pt-2 pb-2 pl-1 pr-1 card-menu" style="gap: 25px;">
                        <a @click="$router.push('/rec-single-marketplace')">Buy</a>
                      </v-card>
                    </v-menu>
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
                      <img :src="countries[item.country]" alt="icon" class="mr-1" style="width: 20px;"> {{ item.country }}
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
      </v-col>
    </v-row>
  </div>
</template>

<script setup>
import '@/assets/styles/pages/profile.scss'
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
import { useToast } from 'vue-toastification'
import { computed, ref, watch } from 'vue'
// import IrecChart from '@/components/irec-chart.vue'

const
  toast = useToast(),

windowStep = ref(undefined),
toggle = ref(0),
energies = {
  'hydro energy': HydroEnergyIcon,
  ocean: OceanEnergyIcon,
  geothermal: GeothermalEnergyIcon,
  biome: BiomeEnergyIcon,
  'wind energy': WindEnergyIcon,
  sun: SolarEnergyIcon,
},
countries = {
  chile: ChileIcon
},

renewableTabs = ref([
  {
    name: "By me",
    value: "me"
  },
  {
    name: "To my name",
    value: "myName"
  },
]),
renewableTab = ref(0),

seriesRenewable = ref([{
  name: 'PRODUCT A',
  data: [24, 55, 31, 67, 12, 43]
},]),

redemptionTabs = ref([
  {
    name: "All",
    value: "all"
  },
  {
    name: "By me",
    value: "me"
  },
  {
    name: "To my name",
    value: "myName"
  },
]),
redemptionTab = ref(0),

headers = [
  { sortable: false, key: 'checkbox', align: "center" },
  { title: 'Energy source', sortable: false, key: 'energy_source'},
  { title: 'Country', key: 'country', sortable: false },
  { title: 'Price', key: 'price', sortable: false },
  { title: 'MWh', key: 'mwh', sortable: false },
  { title: 'Actions', key: 'actions', sortable: false, align: 'center'},
],
dataMarketplace = ref([
  {
    energy_source: "hydro energy",
    price: "125.00",
    currency: '$',
    country: 'chile',
    mwh: 32,
    checkbox: false,
  },
  {
    energy_source: "wind energy",
    price: "125.00",
    currency: '$',
    country: 'chile',
    mwh: 32,
    checkbox: false,
  },
]),
itemsPerPage = ref(100),


windowStepComputed = computed(() => {
  if (window.innerWidth > 960) {
    return 1;
  } else {
    return 2;
  }
})


watch(windowStepComputed, (newVal) => {
  windowStep.value = newVal;
}, { immediate: true })


function goDetails() {}
</script>