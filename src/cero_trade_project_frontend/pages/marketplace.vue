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

        <v-btn class="btn">
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
        :headers="headers"
        :items="dataMarketplace"
        class="mt-6 my-data-table"
        density="compact"
        >
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
                    <a @click="$router.push(basePath('/rec-single-marketplace'))">Buy</a>
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
  </div>
</template>

<script>
import '@/assets/styles/pages/marketplace.scss'
import HydroEnergyIcon from '@/assets/sources/energies/hydro-color.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar-color.svg'
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
        { title: 'Asset ID', key: 'asset_id', sortable: false },
        { title: 'Energy source', key: 'energy_source', sortable: false },
        { title: 'Country', key: 'country', sortable: false },
        { title: 'Price', key: 'price', sortable: false },
        { title: 'MWh', key: 'mwh', sortable: false },
        { title: 'Volume Produced', key: 'volume', sortable: false },
        { title: 'Actions', key: 'actions', sortable: false, align: 'center'},
      ],
      dataMarketplace: [
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'wind energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'sun',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'wind energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'sun',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'wind energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'hydro energy',
          country: 'chile',
          mwh: 32,
          volume: 7654,
        },
        {
          asset_id: '#1234567',
          id: '1234567',
          icon_arrow: 'mdi-arrow-down',
          percent: '20',
          price: "125.00 - 223.00",
          currency: '$',
          energy_source: 'sun',
          country: 'chile',
          mwh: 32,
          volume: 7654,
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
      this.$router.push(this.basePath('/rec-single-marketplace'))
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
