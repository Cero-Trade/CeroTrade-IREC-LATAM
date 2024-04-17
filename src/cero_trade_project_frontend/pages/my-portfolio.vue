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

        <v-btn class="btn2">
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

        <!-- TODO where get this -->
        <v-card class="card card-mwh d-flex flex-column-jcenter flex-grow-1">
          <h6>Redeemed MWh</h6>
          <h5 >0MWh</h5>
        </v-card>
      </v-col>
    </v-row>

    <v-row>
      <v-col xl="6" lg="6" cols="12">
        <!-- TODO apply filters -->
        <v-tabs
          v-model="tabsWindow"
          bg-color="transparent"
          color="basil"
          class="mt-6"
        >
          <v-tab :value="1" class="tab-btn" style="border: none!important; border-bottom: 2px solid rgba(0,0,0,0.25)!important; border-radius: 0px!important;">
            All
          </v-tab>
          <v-tab :value="2" class="tab-btn" style="border: none!important; border-bottom: 2px solid rgba(0,0,0,0.25)!important; border-radius: 0px!important;">
            For sale
          </v-tab>
          <v-tab :value="3" class="tab-btn" style="border: none!important; border-bottom: 2px solid rgba(0,0,0,0.25)!important; border-radius: 0px!important;">
            Not for sale
          </v-tab>
          <v-tab :value="4" class="tab-btn" style="border: none!important; border-bottom: 2px solid rgba(0,0,0,0.25)!important; border-radius: 0px!important;">
            Redeemed
          </v-tab>
        </v-tabs>
      </v-col>

      <v-col xl="6" lg="6" cols="12" class="divrow aend jend delete-mobile" style="gap: 10px;">
        <v-btn class="btn2"><img src="@/assets/sources/icons/sell-btn.svg" alt="Sell">Sell</v-btn>
        <v-btn class="btn2"><img src="@/assets/sources/icons/sell-btn.svg" alt="Sell">Take of market</v-btn>
        <v-btn class="btn2"><img src="@/assets/sources/icons/redeem-btn.svg" alt="Sell">Redeem</v-btn>
      </v-col>
    </v-row>

    <div class="divrow jspace mt-4">
      <div class="divrow" style="gap: 15px;">
        <v-btn class="btn">
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

          <template #[`item.status`]="{ item }">
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="statuses[item.status]" :alt="`${item.status} icon`" style="width: 20px;">
              {{ item.status }}
            </span>
          </template>
        </v-data-table>
      </v-window-item>

      <v-window-item :value="2" class="pa-2">
        <v-row class="mt-6">
          <v-col v-for="(item,index) in dataMarketplace" :key="index" xl="3" lg="3" md="4" sm="6" cols="12">
            <v-card class="card cards-marketplace" @click="goDetails(item)">
              <div class="divrow jspace acenter mb-6">
                <div class="divrow center" style="gap: 5px;">
                  <h6 class="mb-0 font700">IREC #{{ item.token_id }}</h6>
                </div>
                <v-menu location="start">
                  <template v-slot:activator="{ props }">
                    <v-btn class="btn btn-dots" v-bind="props">
                      <img src="@/assets/sources/icons/dots-vertical.svg" alt="dots-vertical icon">
                    </v-btn>
                  </template>

                  <v-card class="divcol pt-2 pb-2 pl-1 pr-1 card-menu" style="gap: 25px;">
                    <a @click="$router.push('/rec-single-portfolio')">Sell</a>
                    <a @click="$router.push('/rec-single-portfolio')">Redeem</a>
                    <a @click="$router.push('/rec-single-portfolio')">Take of market</a>
                  </v-card>
                </v-menu>
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

              <div class="jspace divrow mb-1">
                <span>Status</span>
                <span style="color: #475467;" class="acenter text-capitalize">
                  <img :src="statuses[item.status]" alt="icon" class="mr-1" style="width: 20px;"> {{ item.status }}
                </span>
              </div>
            </v-card>
          </v-col>
        </v-row>
      </v-window-item>
    </v-window>
  </div>
</template>

<script>
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
import { UsersCanister } from '@/repository/users-canister'
import { TokensCanister } from '@/repository/tokens-canister'
// import { closeLoader, showLoader } from '@/plugins/functions'


export default{
  components: { RenewableChart },
  data(){
    return{
      checkboxCheckedIcon,
      checkboxBaseIcon,
      windowStep: undefined,
      tabsWindow: 1,
      
      energies: {
        hydro: HydroEnergyIcon,
        ocean: OceanEnergyIcon,
        geothermal: GeothermalEnergyIcon,
        biome: BiomeEnergyIcon,
        wind: WindEnergyIcon,
        sun: SolarEnergyIcon,
      },
      countries: {
        chile: ChileIcon
      },
      statuses: {
        'not for sale': WalletIcon,
        'for sale': TokenizedIcon,
        sold: TokenizedIcon,
        redeemed: RedeemedIcon
      },

      headers: [
        { key: 'checkbox', sortable: false, align: 'center'},
        { title: 'Token ID', sortable: false, key: 'token_id', align: "center" },
        { title: 'Energy source', key: 'energy_source', sortable: false },
        { title: 'Country', key: 'country', sortable: false },
        // { title: 'Asset ID', key: 'asset_id', sortable: false },
        { title: 'MWh', key: 'mwh', sortable: false },
        { title: 'Status', key: 'status', sortable: false },
      ],
      dataMarketplace: [
        // { 
        //   token_id: 1,
        //   // asset_id: '1234567',
        //   price: 125.00,
        //   energy_source: 'hydro energy',
        //   country: 'chile',
        //   mwh: 32,
        //   volume: 7654,
        //   checkbox: false,
        //   status: 'for sale',
        // },
      ],

      allItems: 'All items',
      items: ['All items', 'Items'],
      items_timeline: ['Timeline', 'Others'],
      timeline: 'Timeline',
      toggle: 0,

      series: undefined,
      categories: undefined
    }
  },
  computed: {
    windowStepComputed() {
      if (window.innerWidth > 960) {
        return 1;
      } else {
        return 2;
      }
    },
    totalMwh() {
      if (!this.series) return 0
      const data = this.series[0].data
      console.log(data);
      return data.reduce((acc, item) => acc + item, 0)
    }
  },
  watch: {
    windowStepComputed(newVal) {
      this.windowStep = newVal;
    }
  },
  created() {
    this.windowStep = this.windowStepComputed;
    this.getData()
  },
  methods:{
    async getData() {
      try {
        const res = await UsersCanister.getPortfolio(),
        list = []

        for (const item of res) {
          list.push({
            token_id: item.tokenId,
            energy_source: item.assetInfo.assetType,
            country: item.assetInfo.specifications.country,
            mwh: item.totalAmount,
            status: item.status,
            checkbox: false,
          })
        }

        this.dataMarketplace = list.sort((a, b) => a.token_id - b.token_id)

        const grouped = list.reduce((acc, item) => {
          let existenceElement = acc.find(elem => elem.energy_source === item.energy_source);
          if (existenceElement) {
            existenceElement.valor += item.mwh;
          } else {
            acc.push({ ...item });
          }
          return acc;
        }, []);

        this.series = [{
          name: 'MWh',
          data: grouped.map(e => e.mwh)
        }]
        if (grouped.length) this.categories = grouped.map(e => e.energy_source)
      } catch (error) {
        console.error(error);
      }
    },
    goDetails(){
      this.$router.push('/rec-single-portfolio')
    }
  }
}

</script>