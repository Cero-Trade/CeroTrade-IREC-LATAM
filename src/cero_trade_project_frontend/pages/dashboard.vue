<template>
  <modal-import-irecs ref="modalImportIrecs" />

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
                  <h4 class="bold mb-0">{{ formatAmount(totalMwh, { compact: true }) }} MWh</h4>
                </div>
  
                <!-- <div style="width: 140px;">
                  <mwh-chart height="80" :series="seriesMwh" />
                </div> -->
              </v-card>
              
              <v-card class="card jspace no-bottom-pa flex-grow-1">
                <div class="divcol">
                  <span>Redeemed MWh</span>
                  <h4 class="bold mb-0">{{ formatAmount(totalRedemptions, { compact: true }) }} MWh</h4>
                </div>
  
                <!-- <div style="width: 140px;">
                  <mwh-chart height="80" :series="seriesRedemptions" />
                </div> -->
              </v-card>
            </v-col>
  
            <v-col xl="8" lg="8" md="6" cols="12">
              <v-card class="card" style="min-height: 100%!important;">
                <h6>Renewable sources</h6>
                <renewable-chart
                  height="200"
                  :series="seriesRenewable"
                  :categories="categoriesRenewable"
                />
              </v-card>
            </v-col>
  
            <!-- <v-col cols="12">
              <v-card class="card">
                <h6>Tokenized I-RECs</h6>
                <irec-chart height="250" :series="series" />
              </v-card>
            </v-col> -->
          </v-row>
        </v-col>
  
        <v-col xl="3" lg="3" cols="12">
          <v-row>
            <v-col cols="12">
              <v-card class="card divcol mb-4" style="background-color: #F9FAFB!important;">
                <h5 class="acenter"><img src="@/assets/sources/icons/lightning.svg" alt="Marketplace" class="mr-4" style="width: 20px;">Import IRECs</h5>
                <p class="p12">Transfered IRECs to our Platform Operator Account? Add them to your portafolio as tokens.</p>
                <v-btn class="btn btn-max-content"
                @click="$refs.modalImportIrecs.model = true"
                >Get them</v-btn>
              </v-card>

              <v-card class="card divcol mb-4" style="background-color: #F9FAFB!important;">
                <h5 class="acenter"><img src="@/assets/sources/icons/account-multiple.svg" alt="Account" class="mr-4" style="width: 20px;">Profile</h5>
                <p class="p12">Access and edit your profile information.</p>
                <v-btn class="btn btn-max-content" @click="$router.push({ path: '/settings', query: { editProfile: true } })">
                  Edit profile <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon">
                </v-btn>
              </v-card>
  
              <v-card class="card divcol mb-4" style="background-color: #F9FAFB!important;">
                <h5 class="acenter"><img src="@/assets/sources/icons/marketplace-black.svg" alt="Marketplace" class="mr-4" style="width: 20px;">Marketplace</h5>
                <p class="p12">Discover new opportunities in the renewable energy marketplace. Buy, sell, and trade with ease.</p>
                <v-btn class="btn btn-max-content"
                @click="$router.push({ path: '/marketplace' })"
                >Go to marketplace <img src="@/assets/sources/icons/coins.svg" alt="coins icon"></v-btn>
              </v-card>

              <v-card class="card divcol mb-4" style="background-color: #F9FAFB!important;">
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
            </v-col>
          </v-row>
        </v-col>
      </v-row>
    </div>
  </template>
  
  <script>
  import '@/assets/styles/pages/dashboard.scss'
  import VueApexCharts from "vue3-apexcharts"
  import RenewableChart from '@/components/renewable-chart.vue'
  import MwhChart from '@/components/mwh-chart.vue'
  // import IrecChart from '@/components/irec-chart.vue'
  import { UserProfileModel } from '@/models/user-profile-model'
  import { AgentCanister } from '@/repository/agent-canister'
  import { useToast } from 'vue-toastification'
  import ModalImportIrecs from '@/components/modals/modal-import-irecs.vue'
  import { formatAmount as formatAmountFunc } from '@/plugins/functions'
  import { ref } from 'vue'
  
  export default {
    components: {
      apexchart: VueApexCharts,
      RenewableChart,
      MwhChart,
      ModalImportIrecs,
      // IrecChart
    },
    setup(){
      const toast = useToast(),
      formatAmount = formatAmountFunc

      return{
        toast,
        formatAmount,
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
        seriesRenewable: ref(undefined),
        categoriesRenewable: ref(undefined),

        seriesMwh: ref([]),
        seriesRedemptions: ref([]),

        totalMwh: ref(0),
        totalRedemptions: ref(0)
      }
    },
    beforeMount() {
      this.getData()
    },
    methods: {
      async getData() {
        try {
          const response = await AgentCanister.getAllAssetStatistics(),
          grouped = response.reduce((acc, [_, item]) => {
            let existenceElement = acc.find(elem => elem.assetType === item.assetType);

            if (existenceElement) {
              existenceElement.mwh += item.mwh;
              existenceElement.redemptions += item.redemptions;
            } else {
              acc.push({ ...item });
            }
            return acc;
          }, []) ?? [],
          assetTypes = [], redemptions = [], mwhs = []

          for (const { assetType, mwh, redemptions: redeems } of grouped) {
            assetTypes.push(assetType)
            redemptions.push(redeems)
            mwhs.push(mwh)
          }

          this.seriesRenewable = [{ name: 'MWh in Cero Trade', data: mwhs }]
          this.categoriesRenewable = assetTypes

          this.seriesMwh = [{
            name: 'Mwh for energy source',
            data: mwhs
          }]
          this.seriesRedemptions = [{
            name: 'Redemptions for energy source',
            data: redemptions
          }]

          this.totalMwh = mwhs.reduce((acc, mwh) => acc + mwh, 0)
          this.totalRedemptions = redemptions.reduce((acc, redemption) => acc + redemption, 0)
        } catch (error) {
          this.toast.error(error)
        }
      }
    }
  }
  </script>