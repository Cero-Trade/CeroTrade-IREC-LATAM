<template>
    <div id="dashboard">
      <h4>Hi {{ profile.companyName }} 👋</h4>
      <span class="mbb16" style="color:#475467; margin-bottom: 64px;">Welcome to Cero Trade platform. Your gateway to a greener and more sustainable future. Manage your energy assets, track your usage, and contribute to a healthier planet.</span>
  
      <v-row>
        <v-col xl="9" lg="9" cols="12">
          <v-row>
            <v-col xl="4" lg="4" md="4" cols="12" class="d-flex flex-column" style="gap: 20px">
              <v-card class="card jspace no-bottom-pa flex-grow-1">
                <div class="divcol">
                  <span>Total MWh</span>
                  <h4 class="bold mb-0">10MWh</h4>
                </div>
  
                <div style="width: 140px;">
                  <mwh-chart height="80" :series="seriesMwh" />
                </div>
              </v-card>
              
              <v-card class="card jspace no-bottom-pa flex-grow-1">
                <div class="divcol">
                  <span>Redeemed MWh</span>
                  <h4 class="bold mb-0">10MWh</h4>
                </div>
  
                <div style="width: 140px;">
                  <mwh-chart height="80" :series="seriesMwh" />
                </div>
              </v-card>
            </v-col>
  
            <v-col xl="8" lg="8" md="6" cols="12">
              <v-card class="card" style="min-height: 100%!important;">
                <h6>Renewable sources</h6>
                <renewable-chart height="200" :series="seriesRenewable" />
              </v-card>
            </v-col>
  
            <v-col cols="12">
              <v-card class="card">
                <h6>Tokenized I-RECs</h6>
                <irec-chart height="250" :series="series" />
              </v-card>
            </v-col>
          </v-row>
        </v-col>
  
        <v-col xl="3" lg="3" cols="12">
          <v-row>
            <v-col cols="12">
              <v-card class="card divcol mb-4" style="background-color: #F9FAFB!important; min-height: 200px!important;">
                <h5>Quick links</h5>
                <span class="mb-2 d-flex flex-acenter" style="color: #00555B; font-size: 12px; gap: 5px">
                  <img src="@/assets/sources/icons/file.svg" alt="file icon">
                  Documentation
                </span>
                <span class="mb-2 d-flex flex-acenter" style="color: #00555B; font-size: 12px; gap: 5px">
                  <img src="@/assets/sources/icons/headphones.svg" alt="headphones icon">
                  Support
                </span>
              </v-card>
  
              <v-card class="card divcol mb-4" style="background-color: #F9FAFB!important; min-height: 200px!important;">
                <h5 class="acenter"><img src="@/assets/sources/icons/account-multiple.svg" alt="Account" class="mr-4" style="width: 20px;">Profile</h5>
                <p class="p12">Access and edit your profile information.</p>
                <v-btn class="btn btn-max-content" @click="$router.push({ path: '/settings', query: { editProfile: true } })">
                  Edit profile <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon">
                </v-btn>
              </v-card>
  
              <v-card class="card divcol mb-4" style="background-color: #F9FAFB!important; min-height: 200px!important;">
                <h5 class="acenter"><img src="@/assets/sources/icons/marketplace-black.svg" alt="Marketplace" class="mr-4" style="width: 20px;">Marketplace</h5>
                <p class="p12">Discover new opportunities in the renewable energy marketplace. Buy, sell, and trade with ease.</p>
                <v-btn class="btn btn-max-content"
                @click="$router.push({ path: '/marketplace' })"
                >Go to marketplace <img src="@/assets/sources/icons/coins.svg" alt="coins icon"></v-btn>
              </v-card>
            </v-col>
          </v-row>
        </v-col>
      </v-row>
  <!-- 
      Dialog conect
      <v-dialog v-model="dialogConect" persistent>
        <v-card class="card card-dialog-connect">
          <v-icon class="close" @click="dialogConect = false">mdi-close</v-icon>
          <v-sheet class="mb-10 double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
            </v-sheet>
          </v-sheet>
          <h6 class="bold">Connect wallet</h6>
          <span class="tertiary">Lorem ipsum dolor sit amet consectetur, adipisicing elit</span>
          <v-row class="mt-6">
            <v-col xl="4" lg="4" md="6" cols="12">
              <v-card class="card divcol astart jcenter divrow-mobile">
                <div>
                  <div class="divrow mb-4" style="gap: 10px;">
                    <img src="@/assets/sources/icons/visa.svg" alt="Visa">
                    <img src="@/assets/sources/icons/mastercard.svg" alt="Mastercard">
                    <img src="@/assets/sources/icons/mastercard-yellow.svg" alt="Mastercard">
                  </div>
  
                  <h6 class="mb-4" style="font-weight: 700;">Credit / Debit cards</h6>
                </div>
  
                <v-btn class="btn" @click="dialogConect = false; dialogCreditCrad = true">Connect</v-btn>
              </v-card>
            </v-col>
  
            <v-col xl="4" lg="4" md="6" cols="12">
              <v-card class="card divcol astart jcenter divrow-mobile">
                <div>
                  <div class="divrow mb-4" style="gap: 10px;">
                    <img src="@/assets/sources/icons/bticoin.svg" alt="Bitcoin">
                    <img src="@/assets/sources/icons/ethereum.svg" alt="Ethereum">
                  </div>
  
                  <h6 class="mb-4" style="font-weight: 700;">Payment with cryptocurrency</h6>
                </div>
  
                <v-btn class="btn">Connect</v-btn>
              </v-card>
            </v-col>
  
            <v-col xl="4" lg="4" md="6" cols="12">
              <v-card class="card divcol astart jcenter divrow-mobile">
                <div>
                  <div class="divrow mb-4" style="gap: 10px;">
                    <img src="@/assets/sources/icons/bank.svg" alt="Bank">
                  </div>
  
                  <h6 class="mb-4" style="font-weight: 700;">Bank transfer</h6>
                </div>
  
                <v-btn class="btn">Connect</v-btn>
              </v-card>
            </v-col>
  
            <v-col xl="4" lg="4" md="6" cols="12">
              <v-card class="card divcol astart jcenter divrow-mobile">
                <div>
                  <div class="divrow mb-4" style="gap: 10px;">
                    <img src="@/assets/sources/icons/tether.svg" alt="Tether">
                  </div>
  
                  <h6 class="mb-4" style="font-weight: 700;">Payment with stablecoins</h6>
                </div>
  
                <v-btn class="btn">Connect</v-btn>
              </v-card>
            </v-col>
  
            <v-col xl="4" lg="4" md="6" cols="12">
              <v-card class="card divcol astart jcenter divrow-mobile">
                <div>
                  <div class="divrow mb-4" style="gap: 10px;">
                    <img src="@/assets/sources/icons/internet-computer-icon.svg" alt="ICP">
                  </div>
  
                  <h6 class="mb-4" style="font-weight: 700;">Payment with ICP</h6>
                </div>
  
                <v-btn class="btn">Connect</v-btn>
              </v-card>
            </v-col>
          </v-row>
        </v-card>
      </v-dialog>
  
      Dialog Credit Card
      <v-dialog v-model="dialogCreditCrad" persistent>
        <v-card class="card card-dialog-credit-card">
          <v-icon class="close" @click="dialogCreditCrad = false">mdi-close</v-icon>
          <v-sheet class="mb-6 double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/credit-card.svg" alt="Credit card" style="width: 20px;">
            </v-sheet>
          </v-sheet>
          <h6 class="bold">Credit card connect</h6>
          <v-row class="mt-1">
            <v-col cols="12">
              <label for="card-name">Card issuer name</label>
              <v-text-field id="card-name" class="input" variant="outlined" elevation="0" placeholder="Olivia Cero"></v-text-field>
            </v-col>
            <v-col cols="12">
              <label for="card-number">Card number</label>
              <v-text-field
              id="card-number" class="input" variant="outlined" 
              elevation="0" placeholder="Card number"
              append-inner-icon="mdi-help-circle-outline"
              >
              <template v-slot:prepend-inner>
                <img src="@/assets/sources/icons/mastercard-yellow.svg" alt="Icono" />
              </template>
              </v-text-field>
            </v-col>
            <v-col xl="6" lg="6" md="6" cols="12">
              <label for="expiration">Expiration date</label>
              <v-text-field id="expiration" class="input" variant="outlined" elevation="0" placeholder="12/24"></v-text-field>
            </v-col>
            <v-col xl="6" lg="6" md="6" cols="12">
              <label for="cvc">Enter CVC</label>
              <v-text-field id="cvc" class="input" variant="outlined" elevation="0" placeholder="Enter CVC" append-inner-icon="mdi-help-circle-outline"></v-text-field>
            </v-col>
          </v-row>
          <div class="divrow mt-6" style="gap: 10px;">
            <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogCreditCrad = false">Cancel <v-icon>mdi-close</v-icon></v-btn>
            <v-btn class="btn" @click="dialogCreditCrad = false; walletStatus = true" style="border: none!important;">Confirm <v-icon>mdi-check</v-icon></v-btn>
          </div>
        </v-card>
      </v-dialog>
  
      Dialog 2fa
      <v-dialog v-model="dialog2fa" persistent>
        <v-card class="card card-dialog-2fa">
          <v-icon class="close" @click="dialog2fa = false">mdi-close</v-icon>
          <v-sheet class="mb-6 double-sheet">
            <v-sheet>
              <v-icon>mdi-shield-outline</v-icon>
            </v-sheet>
          </v-sheet>
          <h6 class="bold">Add 2-factor verification</h6>
          <span class="tertiary">Lorem ipsum dolor sit amet consectetur adipisicing elit. At alias laboriosam iste eum, repellendus.</span>
          <v-row class="mt-6">
            <v-col cols="12">
              <label for="card-number">Add mobile phone</label>
              <v-text-field
              id="card-number" class="input" variant="outlined" 
              elevation="0" placeholder="+1 (555) 000-0000"
              append-inner-icon="mdi-help-circle-outline"
              >
              <v-select
                v-model="selectedLang"
                :items="items"
                variant="solo"
                flat
                menu-icon="mdi-chevron-down"
                class="select"
                bg-color="transparent"
                hide-details
                style="color: #000;z-index: 99;"
              ></v-select>
              </v-text-field>
            </v-col>
          </v-row>
          <div class="divrow mt-6" style="gap: 10px;">
            <v-btn class="btn" style="background-color: #fff!important;" @click="dialog2fa = false">Cancel <v-icon>mdi-close</v-icon></v-btn>
            <v-btn class="btn" @click="dialog2fa = false; dialogPhone = true">Confirm <v-icon>mdi-check</v-icon></v-btn>
          </div>
        </v-card>
      </v-dialog>
  
      Dialog OTP
      <v-dialog v-model="dialogPhone" persistent>
        <v-card class="card card-dialog-2fa">
          <v-icon class="close" @click="dialogPhone = false; status2fa = true">mdi-close</v-icon>
          <v-sheet class="mb-6 double-sheet">
            <v-sheet>
              <v-icon>mdi-shield-outline</v-icon>
            </v-sheet>
          </v-sheet>
          <h6 class="bold">Verify your phone</h6>
          <span class="tertiary">Lorem ipsum dolor sit amet consectetur adipisicing elit. At alias laboriosam iste eum, repellendus.</span>
          <v-row class="mt-6">
            <v-col cols="12">
              <label class="bold" for="otp">Secure code</label>
              <v-otp-input id="otp" :length="4" placeholder="0"></v-otp-input>
            </v-col>
          </v-row>
        </v-card>
      </v-dialog>
      Dialog verify
      <v-dialog v-model="dialogParticipant" persistent>
        <v-card class="card card-dialog-participant">
          <v-icon class="close" @click="dialogParticipant = false">mdi-close</v-icon>
          <v-sheet class="double-sheet mb-6">
            <v-sheet>
              <v-icon>mdi-check-decagram-outline</v-icon>
            </v-sheet>
          </v-sheet>
          <h6 class="bold">Verify as participant</h6>
          <div class="divrow divcol-mobile jspace" style="gap: 30px;">
            <span class="tertiary">Lorem ipsum dolor sit amet consectetur adipisicing elit. At alias laboriosam iste eum, repellendus.</span>
            <v-btn class="btn showmobile" @click="dialogParticipant = false; dialogParticipantForm = true">How to become a participant</v-btn>
            <v-btn class="btn deletemobile" style="border: none!important;" @click="dialogParticipant = false; dialogParticipantForm = true">Become a participant</v-btn>
            <v-btn class="btn" style="border: none!important;" @click="dialogParticipant = false; dialogParticipantForm = true">Verify as a participant</v-btn>
          </div>
          <div class="divrow jstart acenter mt-4">
            <v-icon style="color: #475467!important;">mdi-help-circle-outline</v-icon>
            <span class="tertiary deletemobile ml-2" style="font-weight: 700;">How to become a participant</span>
          </div>
        
          <v-row class="mt-6">
            <v-col xl="6" lg="6" md="6" cols="12">
              <v-card class="card pt-6 pb-6" style="height: 100%!important;"> 
                <h6>Non-participant</h6>
                <span class="tertiary">Lorem ipsum dolor sit amet consectetur adipisicing elit. At alias laboriosam iste eum, repellendus.</span>
                <v-divider :thickness="2" class="tertiary mt-4 mb-4" style="height: 1px;width: 150%;position: relative; left: -80px;"></v-divider>
                <div class="divcol astart ml-6" style="gap: 20px;">
                  <span><v-icon class="check mr-2">mdi-check</v-icon> Acces to basic features</span>
                  <span><v-icon class="check mr-2">mdi-check</v-icon> Basic reporting + analytics</span>
                  <span><v-icon class="check mr-2">mdi-check</v-icon> Up to 10 individual users</span>
                </div>
              </v-card>
            </v-col>
            <v-col xl="6" lg="6" md="6" cols="12">
              <v-card class="card pt-6 pb-6"> 
                <h6>Participant</h6>
                <span class="tertiary">Lorem ipsum dolor sit amet consectetur adipisicing elit. At alias laboriosam iste eum, repellendus.</span>
                <v-divider :thickness="2" class="tertiary mt-4 mb-4" style="height: 1px;width: 150%;position: relative; left: -80px;"></v-divider>
                <div class="divcol astart ml-6" style="gap: 20px;">
                  <span><v-icon class="check-green mr-2">mdi-check</v-icon> Acces to basic features</span>
                  <span><v-icon class="check-green mr-2">mdi-check</v-icon> Basic reporting + analytics</span>
                  <span><v-icon class="check-green mr-2">mdi-check</v-icon> Up to 10 individual users</span>
                  <span><v-icon class="check-green mr-2">mdi-check</v-icon> 20GB individual data</span>
                  <span><v-icon class="check-green mr-2">mdi-check</v-icon> Basic chat support</span>
                </div>
              </v-card>
            </v-col>
          </v-row>
        </v-card>
      </v-dialog>
  
      Dialog participant form
      <v-dialog v-model="dialogParticipantForm" persistent>
        <v-card class="card card-dialog-form">
          <v-icon class="close" @click="dialogParticipantForm = false">mdi-close</v-icon>
          <v-sheet class="double-sheet mb-6">
            <v-sheet>
              <v-icon>mdi-check-decagram-outline</v-icon>
            </v-sheet>
          </v-sheet>
          <h6 class="bold">Verify as participant</h6>
          <span class="tertiary">Lorem ipsum dolor sit amet consectetur adipisicing elit. At alias laboriosam iste eum, repellendus.</span>
          <span class="tertiary mt-4" style="font-weight: 700;"><v-icon>mdi-help-circle-outline</v-icon> How to become a participant</span>
          <v-row class="mt-6">
            <v-col cols="12">
              <label for="credential">Credential ID</label>
              <v-text-field
              id="credential" class="input" variant="outlined" elevation="0" 
              placeholder="Enter credential ID" append-inner-icon="mdi-help-circle-outline"
              ></v-text-field>
            </v-col>
            <v-col cols="12">
              <label for="password">Password</label>
              <v-text-field
              id="password" class="input" variant="outlined" elevation="0" 
              :append-inner-icon="show_password ? 'mdi-eye-outline' : 'mdi-eye-off-outline'"
              :type="show_password ? 'text' : 'password'"
              placeholder="Enter password"
              @click:append-inner="show_password = !show_password"
              ></v-text-field>
            </v-col>
            <v-col cols="12">
              <v-btn class="btn" style="min-width: 100%!important;" @click="dialogParticipantForm = false ;dialogPending = true">
                Verify
              </v-btn>
            </v-col>
          </v-row>
        </v-card>
      </v-dialog>
  
      Dialog pending
      <v-dialog v-model="dialogPending" persistent>
        <v-card class="card card-dialog-2fa">
          <v-icon class="close" @click="dialogPending = false; verifyStatus = true">mdi-close</v-icon>
          <img src="@/assets/sources/icons/loading.svg" alt="loading" class="mb-6" style="width: 30px;">
          <h6>Verification pending</h6>
          <span class="tertiary">Lorem ipsum dolor sit amet consectetur adipisicing elit. At alias laboriosam iste eum, repellendus.</span>
        </v-card>
      </v-dialog> -->
    </div>
  </template>
  
  <script>
  import '@/assets/styles/pages/dashboard.scss'
  import VueApexCharts from "vue3-apexcharts"
  import RenewableChart from '@/components/renewable-chart.vue'
  import MwhChart from '@/components/mwh-chart.vue'
  import IrecChart from '@/components/irec-chart.vue'
  import { UserProfileModel } from '@/models/user-profile-model'
  
  export default {
    components: {
      apexchart: VueApexCharts,
      RenewableChart,
      MwhChart,
      IrecChart
    },
    data(){
      return{
        profile: UserProfileModel.get(),
        walletStatus: false,
        status2fa: false,
        verifyStatus: false,
        show_password: false,
        dialogParticipantForm: false,
        dialogPending: false,
        dialogParticipant: false,
        dialogPhone: false,
        items: ["US", "UK"],
        selectedLang:'USA',
        dialogConect: false,
        dialogCreditCrad: false,
        dialog2fa: false,
        // donutSeries: [44, 55, 81],
        // donutOptions: {
        //   labels: ['Redeemed', 'Tokenized', 'Raw'], 
        //   chart: {
        //     type: 'donut',
        //   },
        //   plotOptions: {
        //     pie: {
        //       donut: {
        //         size: '50%', // Ajusta este valor para cambiar el grosor del anillo
        //       },
        //     },
        //   },
        //   colors: ['#00393D', '#00555B', '#C6F221'],
        //   dataLabels: {
        //     enabled: false,
        //   },
        //   stroke: {
        //     width: 0, // Ajusta este valor para cambiar el grosor del anillo
        //   },
        //   responsive: [{
        //     breakpoint: 480,
        //     options: {
        //       chart: {
        //         width: 300
        //       },
        //       // legend: {
        //       //   position: 'bottom'
        //       // }
        //     }
        //   }]
        // },
  
        series: [{
          name: 'PRODUCT A',
          data: [424, 355, 431, 167, 212, 543, 664, 155, 841, 637, 122, 443]
        }, 
        {
          name: 'PRODUCT B',
          data: [153, 623, 720, 338, 193, 217, 113, 233, 420, 558, 113, 927]
        }, 
        {
          name: 'PRODUCT C',
          data: [111, 187, 165, 115, 821, 814, 411, 173, 315, 115, 261, 314]
        },],
        seriesRenewable: [{
          name: 'PRODUCT A',
          data: [24, 55, 31, 67, 12, 43]
        },],
        seriesMwh: [{
            name: 'Series 1',
            data: [31, 40, 28, 51, 42, 109, 100, 31, 40, 28, 51, 42, 109, 100 ]
          }, 
        ],
      }
    },
  }
  </script>