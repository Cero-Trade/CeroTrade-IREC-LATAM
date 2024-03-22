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
    >
      <v-tab
        v-for="(item, i) in tabs" :key="i"
        style="border: none!important; border-bottom: 2px solid rgba(0,0,0,0.25)!important; border-radius: 0px!important;"
      >{{ item }}</v-tab>
    </v-tabs>

    <div class="divrow jspace flex-wrap" style="row-gap: 10px;">
      <div class="divrow" style="gap: 15px;">

        <v-btn class="btn">
          <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
          Add filter
        </v-btn>
      </div>
    </div>

    <v-data-table
      v-model:items-per-page="itemsPerPage"
      :headers="headers"
      :items="dataTransactions"
      class="mt-6 my-data-table"
      >
        <template #[`item.token_id`]="{ item }">
          <span class="flex-center wbold" style="color: #475467;">{{ item.token_id }}</span>
        </template>

        <template #item.type="{ item }">
          <span class="text-capitalize w700" :style="`
            color: ${item.type === 'sale' ? '#00555B'
            : item.type === 'redemption' ? '#5A02CA'
            : '#2970FF'
          } !important`">{{ item.type }}</span>
        </template>
        
        <template #[`item.recipent`]="{ item }">
          <span class="flex-acenter" style="gap: 5px; text-wrap: nowrap">
            <img :src="companies[item.recipent]" :alt="`${item.recipent} icon`" style="width: 20px;">
            {{ item.recipent }}
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
          <span class="flex-acenter">
            <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon">
            {{ item.mwh }}
          </span>
        </template>
        
        <template #item.via="{ item }">
          <span style="text-wrap: nowrap">{{ item.via }}</span>
        </template>

        <template #item.amount="{ item }">
          {{ item.amount ? `$${item.amount}` : '-' }}
        </template>
      </v-data-table>
  </div>
</template>

<script>
import '@/assets/styles/pages/my-transactions.scss'
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
import variables from '@/mixins/variables'

export default{
  data() {
    return{
      basePath: variables.basePath,
      tabsMobile: 1,
      itemsPerPage: 100,
      windowStep: undefined,
      allItems: 'All items',
      items: ['All items', 'Items'],
      items_timeline: ['Timeline', 'Others'],
      timeline: 'Timeline',
      toggle: 0,

      tab: 0,
      tabs: ["All", "Sale", "Purchase", "Redemption"],

      companies: {
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
      energies: {
        'hydro energy': HydroEnergyIcon,
        ocean: OceanEnergyIcon,
        geothermal: GeothermalEnergyIcon,
        biome: BiomeEnergyIcon,
        'wind energy': WindEnergyIcon,
        sun: SolarEnergyIcon,
      },
      countries: {
        chile: ChileIcon
      },

       headers: [
        // { title: '', key: 'checkbox', sortable: false, align: 'center'},
        { title: 'Token ID', key: 'token_id', align: 'center', sortable: false },
        { title: 'Type', key: 'type', sortable: false },
        { title: 'Recipent', key: 'recipent', sortable: false },
        { title: 'Energy source', key: 'energy_source', sortable: false },
        { title: 'Country', key: 'country', sortable: false },
        { title: 'MWh', key: 'mwh', sortable: false },
        { title: 'Asset ID', key: 'asset_id', sortable: false },
        { title: 'Date', key: 'date', sortable: false },
        { title: 'Amount (USD)', key: 'amount', align: 'center', sortable: false },
        { title: 'Via', key: 'via', align: 'center', sortable: false },
        { title: 'Transaction ID', key: 'transaction_id', align: 'center', sortable: false },
      ],
      dataTransactions: [
        {
          token_id: '1',
          type: "sale",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '2',
          type: "redemption",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'ocean',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '3',
          type: "redemption",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'wind energy',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '4',
          type: "sale",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'biome',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '5',
          type: "sale",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'sun',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '6',
          type: "redemption",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'geothermal',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '7',
          type: "redemption",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '8',
          type: "purchase",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '9',
          type: "purchase",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '10',
          type: "purchase",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '11',
          type: "purchase",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
        {
          token_id: '12',
          type: "sale",
          recipent: 'Sphere',
          icon_source: 'mdi-waves',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          asset_id: '#1234567',
          date: "01/04/2024",
          amount: 100,
          via: "Bank Transfer",
          transaction_id: 1
        },
      ],
    }
  },

  computed: {
    windowStepComputed() {
      if (window.innerWidth > 960) {
        return 1;
      } else {
        return 2;
      }
    }
  },

  methods:{
    goDetails(){
      this.$router.push(basePath('/rec-single-my-transactions'))
    },
  },
  watch: {
    windowStepComputed(newVal) {
      this.windowStep = newVal;
    }
  },
  created() {
    this.windowStep = this.windowStepComputed;
  }
}
</script>
