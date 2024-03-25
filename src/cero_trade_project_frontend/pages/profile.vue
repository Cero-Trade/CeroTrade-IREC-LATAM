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

    <v-row>
      <v-col xl="8" lg="8" md="8" cols="12">
        <v-row>
          <v-col xl="8" lg="8" cols="12">
            <v-card class="card" style="min-height: 100%!important;">
              <h6>Renewable sources</h6>
              <renewable-chart height="200" :series="seriesRenewable" />
            </v-card>
          </v-col>
          
          <v-col xl="4" lg="4" cols="12" class="d-flex flex-column justify-space-between" style="gap: 20px">
            <v-card class="card relative d-flex flex-column-jcenter flex-grow-1">
              <span>Offered MWh</span>
              <h5 class="mb-0">10MWh</h5>
            </v-card>
            
            <v-card class="card relative d-flex flex-column-jcenter flex-grow-1">
              <span>Redeemed MWh</span>
              <h5 class="mb-0">10MWh</h5>
            </v-card>
          </v-col>

          <v-col cols="12" class="marketplace-styles">
            <div class="flex-space-center mb-3">
              <h5 class="mb-0 bold">Sellers</h5>

              <v-btn class="btn"><img src="@/assets/sources/icons/redeem-btn.svg" alt="Sell">Buy</v-btn>
            </div>
            
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
          </v-col>
        </v-row>
      </v-col>

      <v-col xl="4" lg="4" md="4" cols="12">
        <v-col cols="12" class="pt-0 pl-0">
          <v-card class="card mb-6 divcol astart card-currency">
            <label class="mb-2" for="currency">Choose seller</label>
            <v-select
            :items="['Sphere']"
            variant="outline"
            flat
            menu-icon=""
            class="select mb-4"
            bg-color="#ffffff"
            hide-details
            density="compact"
            style="min-width: 100%;"
            >
              <template #append-inner="{ isFocused }">
                <img
                  src="@/assets/sources/icons/chevron-down.svg"
                  alt="chevron-down icon"
                  :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
                >
              </template>
            </v-select>
            <div class="jspace" style="width: 100%;">
              <div class="divcol" style="gap: 10px;">
                <label>Choose quantity (MWh)</label>
                <div class="divrow" style="gap: 5px;">
                  <v-btn class="btn2" style="max-height: 40px!important;">-</v-btn>
                  <v-text-field
                  class="input" variant="outlined" elevation="0"
                  hide-details
                  ></v-text-field>
                  <v-btn class="btn2" style="max-height: 40px!important;">+</v-btn>
                </div>
              </div>
              <div class="divcol" style="gap: 10px;">
                <label>Price</label>
                <h6>$125.04</h6>
              </div>
            </div>
          </v-card>

          <div class="divrow mb-4" style="gap: 10px; flex-wrap: wrap;">
            <v-btn class="btn" @click="dialogPurchaseReview = true" style="min-width: 100%!important;">
              Buy
            </v-btn>
          </div>
        </v-col>
      </v-col>
    </v-row>

    <!-- Dialog purchase review -->
    <v-dialog v-model="dialogPurchaseReview" persistent>
      <v-card class="card dialog-card-detokenize">
        <img
          src="@/assets/sources/icons/close.svg"
          alt="close icon"
          class="close"
          style="width: 24px"
          @click="dialogPurchaseReview = false"
        >
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
          </v-sheet>
        </v-sheet>
        <h6>Purchase review</h6>
        <span class="tertiary">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Explicabo illum asperiores eaque perferendis iure nemo.</span>

        <v-card class="card cards-rec mt-6 pa-6" v-for="(item, index) in dataCardEnergy" :key="index">
          <span class="bold mt-3">Checkout review</span>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 150%; position: relative; left: -50px;"></v-divider>
          
          <div class="jspace divrow mb-2 acenter">
            <h5 class="acenter h5-mobile"><img src="@/assets/sources/images/avatar-rec.svg" alt="Avatar" class="mr-2" style="width: 40px;"> #123455667</h5>
            <div class="divrow astart acenter">
              <h5 class="mr-2 h5-mobile">
                $ 124.05
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energies[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
              {{ item.energy_source }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Region</span>
            <span>{{ item.region }}</span>
          </div>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 100%;"></v-divider>

          <div class="jspace divrow mt-4">
            <span>Subtotal</span>
            <span>$124.05</span>
          </div>
          <div class="jspace divrow mt-1">
            <span>Transaction fee (10%)</span>
            <span>$12.41</span>
          </div>
          <div class="jspace divrow mt-1">
            <span class="bold">Total</span>
            <span class="bold">$136.46</span>
          </div>
        </v-card>

        <div class="border-card mt-6">
          <div class="jspace divrow">
            <span class="bold">Payment methods</span>
            <div class="divrow mb-4" style="gap: 10px;">
              <img src="@/assets/sources/icons/visa.svg" alt="Visa">
              <img src="@/assets/sources/icons/mastercard.svg" alt="Mastercard">
              <img src="@/assets/sources/icons/mastercard-yellow.svg" alt="Mastercard">
            </div>
          </div>
          <div class="jspace divrow">
            <v-btn class="btn" style="background-color: #fff!important; width: max-content!important;">Change</v-btn>
            <span class="bold">Credit / Debit cards</span>
          </div>
        </div>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogPurchaseReview = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogPurchaseReview = false; dialogPaymentConfirm = true" style="border: none!important;">Proceed with payment</v-btn>
        </div>
      </v-card>
    </v-dialog>
    <!-- Dialog payment confirm -->
    <v-dialog v-model="dialogPaymentConfirm" persistent>
      <v-card class="card dialog-card-detokenize">
        <img
          src="@/assets/sources/icons/close.svg"
          alt="close icon"
          class="close"
          style="width: 24px"
          @click="dialogPaymentConfirm = false"
        >
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon" style="width: 22px">
          </v-sheet>
        </v-sheet>
        <h6>Payment confirmation</h6>
        <span class="tertiary">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Explicabo illum asperiores eaque perferendis iure nemo.</span>

        <v-card class="card mt-6 pa-6" v-for="(item, index) in dataCardEnergy" :key="index">
          <div class="jspace divrow mb-1 acenter">
            <h5 class="acenter h5-mobile"><img src="@/assets/sources/images/avatar-rec.svg" alt="Avatar" class="mr-2" style="width: 40px;"> #123455667</h5>
            <div class="divrow astart acenter">
              <h5 class="mr-2 h5-mobile">
                $ 124.05
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energies[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
              {{ item.energy_source }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Region</span>
            <span>{{ item.region }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Start date</span>
            <span>{{ item.date }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">End date</span>
            <span>24/12/2023</span>
          </div>
        </v-card>

        <div v-for="(item,index) in dataPdfCofirm" :key="index" class="border mb-4 mt-6 jspace">
          <div class="divrow acenter">
            <img src="@/assets/sources/icons/pdf.svg" alt="PDF">
            <div class="divcol ml-2">
              <span style="color: #475467; font-weight: 500;">{{ item.name }}</span>
              <span style="color: #475467;">{{ item.weight }}</span>
            </div>
          </div>

          <v-card class="card center" style="width: max-content!important;">
            <img src="@/assets/sources/icons/download.svg" alt="download icon" style="width: 20px">
          </v-card>
        </div>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn flex-grow-1" @click="dialogPaymentConfirm = false; dialogRedeemCertificates = true" style="border: none!important;">Continue</v-btn>
        </div>
      </v-card>
    </v-dialog>
    <!-- Dialog Redeem Certificates -->
    <v-dialog v-model="dialogRedeemCertificates" persistent>
      <v-card class="card dialog-card-detokenize">
        <img
          src="@/assets/sources/icons/close.svg"
          alt="close icon"
          class="close"
          style="width: 24px"
          @click="dialogRedeemCertificates = false"
        >
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon" style="width: 22px">
          </v-sheet>
        </v-sheet>
        <h6>Do you want to redeem the cerfificates you just bought?</h6>
        <span class="tertiary">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Explicabo illum asperiores eaque perferendis iure nemo.</span>
        <span class="tertiary wbold mt-2 d-flex flex-acenter">
          <img src="@/assets/sources/icons/info-circle-light.svg" alt="info-circle icon" class="mr-1" style="width: 23px">
          Learn more
        </span>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogRedeemCertificates = false">Not Now</v-btn>
          <v-btn class="btn" @click="dialogRedeemCertificates = false;" style="border: none!important;">Yes, redeem</v-btn>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
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
import variables from '@/mixins/variables'


export default {
  components: { RenewableChart },
  data(){
    return{
      basePath: variables.basePath,
      checkboxCheckedIcon,
      checkboxBaseIcon,
      windowStep: undefined,
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
        { sortable: false, key: 'checkbox', align: "center" },
        { title: 'Energy source', sortable: false, key: 'energy_source'},
        { title: 'Country', key: 'country', sortable: false },
        { title: 'Price', key: 'price', sortable: false },
        { title: 'MWh', key: 'mwh', sortable: false },
        { title: 'Actions', key: 'actions', sortable: false, align: 'center'},
      ],
      dataMarketplace: [
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
        {
          energy_source: "sun",
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
          checkbox: false,
        },
        {
          energy_source: "hydro energy",
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
          checkbox: false,
        },
        {
          energy_source: "hydro energy",
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
          checkbox: false,
        },
        {
          energy_source: "hydro energy",
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
          checkbox: false,
        },
        {
          energy_source: "hydro energy",
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
          checkbox: false,
        },
        {
          energy_source: "hydro energy",
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
          checkbox: false,
        },
      ],
      itemsPerPage: 100,
      dialogPaymentConfirm: false,
      dialogPurchaseReview: false,
      dialogParticipantBenefits: false,
      dialogSellingDetailsReview: false,
      dialogDynamicPrice: false,
      itemsCurrency:['USD', 'VES'],
      selectedCurrency: 'USD',
      dialogStaticPrice: false,
      radioSell: null,
      dialogSellOptions: false,
      dialogRedeem: false,
      dialogRedeemSure: false,
      dialogDetokenize: false,
      dialogRedeemCertificates: false,
      tabsSpecifications: null,
      dataDates: [
        {
          registration_date: '2022-01-15',
          commissioning_date: '2022-04-01',
          expire_date: '2042-04-01'
        }
      ],
      dataSpecifications:[
        {
          device_code: 'WT100X',
          capacity: '2.5 Megawatts (MW)',
          location: 'Lorem Ipsum',
          latitude: '52.509865',
          longitude: '-1.964623',
          address: 'Hilltop Farm, Windy Lane, Birmingham, B32 1NN',
          state: 'West Midlands',
          country: 'United Kingdom',
        },
      ],
      dataDeviceDetails:[
        {
          name: 'Wind Turbine T-100X',
          type: 'Wind Turbine',
          device_group: 'Wind energy',
          icon_source: 'mdi-weather-windy',
          description: 'A state-of-the-art wind turbine designed for optimal energy production with minimal environmental impact.'
        }
      ],
      dataPdfRedeem:[
        {
          name: 'Certificate',
          weight: '200 KB'
        }
      ],
      dataPdfCofirm:[
        {
          name: 'Download receipt',
          weight: '200 KB'
        }
      ],
      dataPdf:[
        {
          name: 'Certificate',
          weight: '200 KB'
        },
        {
          name: 'Receipt',
          weight: '148 KB',
        },
      ],
      date: '24/04/23',
      dialogAreYouSure: false,
      tokenBenefits: [
        {
          name:"Lorem, ipsum dolor sit amet consectetur",
        },
        {
          name:"Lorem, ipsum dolor sit amet consectetur",
        },
        {
          name:"Lorem, ipsum dolor sit amet consectetur",
        },
        {
          name:"Lorem, ipsum dolor sit amet consectetur",
        },
        {
          name:"Lorem, ipsum dolor sit amet consectetur",
        },
      ],

      time_selection: 'Year',
      dataCardEnergy: [
        {
          icon_source: 'mdi-waves',
          energy_source: 'hydro energy',
          region: 'Valparaiso, Chile',
          date: '24/12/2023',
          date_start: '12/03/2023',
          co2: '0,12%',
          radioactivity: '0,005%',
          // certification: 'Certification type',
        },
      ],

      // series: [43],
      seriesRenewable: [{
        name: 'PRODUCT A',
        data: [24, 55, 31, 67, 12, 43]
      },],
      // seriesBar: [
      //   {
      //   name: 'PRODUCT A',
      //   data: [11424, 33355, 32431, 21167, 9212, 44543, 11664, 45155, 12841, 45637, 12122, 19443]
      //   }, 
      // ],
      // chartOptionsBar: {
      //   chart: {
      //     type: 'bar',
      //     height: 150,
      //     stacked: true,
      //     toolbar: {
      //       show: false
      //     },
      //     zoom: {
      //       enabled: true
      //     }
      //   },
      //   colors: ['#00393D'],
      //   responsive: [{
      //     breakpoint: 480,
      //     options: {
      //       legend: {
      //         position: 'bottom',
      //         offsetX: -10,
      //         offsetY: 0
      //       }
      //     }
      //   }],
      //   plotOptions: {
      //     bar: {
      //       horizontal: false,
      //       borderRadius: 10,
      //       dataLabels: {
      //         enabled: false,
      //       }
      //     },
      //   },
      //   xaxis: {
      //     type: 'category',
      //     categories: ['Jan','Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
      //   },
      //   legend: {
      //     show: false,
      //   },
      //   dataLabels: {
      //     enabled: false
      //   },
      //   fill: {
      //     opacity: 1
      //   }
      // },
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
  watch: {
    windowStepComputed(newVal) {
      this.windowStep = newVal;
    }
  },
  created() {
    this.windowStep = this.windowStepComputed;
  },


  methods:{
    value1(){
      this.radioSell = 1;
    },
    value2(){
      this.radioSell = 2;
    },
    goDetails(){
    },
    goToStaticOrDynamic(){
      if(this.radioSell == 2){
        this.dialogSellOptions = false;
        this.dialogStaticPrice = true;
      }else if(this.radioSell == 1){
        this.dialogSellOptions = false;
        this.dialogDynamicPrice = true;
      }
    },
  }
}

</script>