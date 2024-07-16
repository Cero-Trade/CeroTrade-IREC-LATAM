<template>
  <div id="profile">
    <span class="mb-10 acenter" style="color: #475467; font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
       Profile
    </span>
    <div class="divrow acenter mb-4">
      <company-logo
        :energy-src="countriesImg[profile?.country ?? 'chile']"
        :country-src="profile?.companyLogo"
        badge-padding="2px"
        energy-sizes="25px"
        class="mr-4"
      ></company-logo>

      <h3 class="mb-0">{{ profile?.companyName }}</h3>
    </div>

    <v-btn class="btn2 ml-auto mb-4" @click="$router.push({ path: '/settings', query: { editProfile: true } })">
      <img src="@/assets/sources/icons/pencil.svg" alt="pencil icon">
      <span style="font-weight: 700 !important;">Edit profile information</span>
    </v-btn>

    <v-row>
      <v-col cols="12" class="d-flex flex-wrap justify-space-between" style="gap: 20px">
        <v-card class="card relative d-flex flex-column-jcenter flex-grow-1">
          <span>Redeemed by me</span>
          <h5 class="mb-0">{{ calcMwh(redemptionsByMe) }}MWh</h5>
        </v-card>
        
        <v-card class="card relative d-flex flex-column-jcenter flex-grow-1">
          <span>Redeemed to my name</span>
          <h5 class="mb-0">{{ calcMwh(redemptionsToMe) }}MWh</h5>
        </v-card>
      </v-col>

      <v-col cols="12" class="mb-4">
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

        <v-card class="card" style="min-height: 100%!important;">
          <h6>Redeemed by Energy Source</h6>
          <renewable-chart height="200" :series="seriesRenewable" :categories="categoriesRenewable" />
        </v-card>
      </v-col>

      <v-col cols="12" class="marketplace-styles">
        <h5 class="mb-3 bold">Redemptions</h5>
        
        <div class="divrow jspace">
          <v-btn class="btn" @click="dialogFilters = true">
            <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
            Add filter
          </v-btn>

          <!-- <div class="divrow jcenter acenter" style="gap: 5px;">
            <v-btn-toggle class="center deletemobile" rounded="1" v-model="toggle">
              <v-btn class="btn-toggle" @click="windowStep = 1"><img src="@/assets/sources/icons/table-view.svg" alt="Table icon"></v-btn>
              <v-btn class="btn-toggle" @click="windowStep = 2"><img src="@/assets/sources/icons/card-view.svg" alt="Card icon"></v-btn>
            </v-btn-toggle>
          </div> -->
        </div>

        <v-data-table
          v-model:items-per-page="redemptionsPerPage"
          :items-per-page-options="[
            {value: 10, title: '10'},
            {value: 25, title: '25'},
            {value: 50, title: '50'},
          ]"
          :headers="headerRedemptions"
          :items="filteredRedemptions"
          :items-length="totalRedemptionPages"
          :loading="loadingRedemptions"
          class="mt-6 my-data-table"
          @update:options="getRedemptions"
        >
          <template #[`item.asset_id`]="{ item }">
            <span class="flex-center wbold" style="color: #475467;">{{ item.asset_id }}</span>
          </template>

          <template #[`item.redeemedBy`]="{ item }">
            <v-menu :close-on-content-click="false" @update:model-value="(value) => getPreviewProfile(value, item.redeemedBy)">
              <template #activator="{ props }">
                <a v-bind="props" class="flex-acenter pointer" style="gap: 5px; text-wrap: nowrap">{{ shortPrincipalId(item.redeemedBy?.toString()) }}</a>
              </template>

              <v-card class="px-4 py-2 bg-secondary d-flex">
                <v-progress-circular
                  v-if="!previewProfile"
                  indeterminate
                  color="rgb(var(--v-theme-primary))"
                  class="mx-auto"
                ></v-progress-circular>

                <span v-else class="flex-acenter" style="gap: 10px; text-wrap: nowrap">
                  <v-img-load
                    :src="previewProfile.companyLogo"
                    :alt="`${previewProfile.companyName} logo`"
                    cover
                    sizes="30px"
                    rounded="50%"
                    class="flex-grow-0"
                  />
                  {{ previewProfile.companyName }}
                </span>
              </v-card>
            </v-menu>
          </template>

          <template #[`item.beneficiary`]="{ item }">
            <v-menu :close-on-content-click="false" @update:model-value="(value) => getPreviewProfile(value, item.beneficiary)">
              <template #activator="{ props }">
                <a v-bind="props" class="flex-acenter pointer" style="gap: 5px; text-wrap: nowrap">{{ shortPrincipalId(item.beneficiary?.toString()) }}</a>
              </template>

              <v-card class="px-4 py-2 bg-secondary d-flex">
                <v-progress-circular
                  v-if="!previewProfile"
                  indeterminate
                  color="rgb(var(--v-theme-primary))"
                  class="mx-auto"
                ></v-progress-circular>

                <span v-else class="flex-acenter" style="gap: 10px; text-wrap: nowrap">
                  <v-img-load
                    :src="previewProfile.companyLogo"
                    :alt="`${previewProfile.companyName} logo`"
                    cover
                    sizes="30px"
                    rounded="50%"
                    class="flex-grow-0"
                  />
                  {{ previewProfile.companyName }}
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
        </v-data-table>


        <v-pagination
          v-model="currentRedemptionPage"
          :length="totalRedemptionPages"
          :disabled="loadingRedemptions"
          class="mt-4"
          @update:model-value="getRedemptions()"
        ></v-pagination>
      </v-col>
    </v-row>
  </div>



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

        <!-- <v-range-slider
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
        ></v-range-slider> -->

        <v-range-slider
          v-model="filters.mwhRange"
          :min="0"
          :max="1000"
          :step="1"
          variant="solo"
          elevation="0"
          label="Mwh range"
          :thumb-label="filters.mwhRange ? 'always' : false"
          class="align-center my-3"
          hide-details
        ></v-range-slider>

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
</template>

<script setup>
import '@/assets/styles/pages/profile.scss'
import countries from '@/assets/sources/json/countries-all.json'
import RenewableChart from "@/components/renewable-chart.vue"
import HydroEnergyIcon from '@/assets/sources/energies/hydro-color.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar-color.svg'
import ChileIcon from '@/assets/sources/icons/CL.svg'
import { useToast } from 'vue-toastification'
import { computed, onBeforeMount, ref, watch } from 'vue'
import { AgentCanister } from '@/repository/agent-canister'
import { UserProfileModel } from '@/models/user-profile-model'
import { TxType } from '@/models/transaction-model'
import moment from 'moment'
import { shortPrincipalId } from '@/plugins/functions'
// import IrecChart from '@/components/irec-chart.vue'

const
  toast = useToast(),

windowStep = ref(undefined),
toggle = ref(0),
energies = {
  hydro: HydroEnergyIcon,
  ocean: OceanEnergyIcon,
  geothermal: GeothermalEnergyIcon,
  biome: BiomeEnergyIcon,
  wind: WindEnergyIcon,
  sun: SolarEnergyIcon,
},
countriesImg = {
  CL: ChileIcon
},

profile = ref(null),
previewProfile = ref(null),

tabValue = {
  all: "all",
  byMe: "byMe",
  toMe: "toMe",
},

seriesRenewable = computed(() => [{ name: 'MWh redeemed', data: renewableEnergies.value.map(e => e.mwh) }]),
categoriesRenewable = computed(() => renewableEnergies.value.map(e => e.energy_source)),

dialogFilters = ref(),
filtersFormRef = ref(),
filters = ref({
  country: null,
  // priceRange: null,
  mwhRange: null,
  assetTypes: null,
  method: null,
  fromDate: null,
  toDate: null,
}),

fromDateMenu = ref(),
toDateMenu = ref(),

redemptionTabs = ref([
  {
    name: "All",
    value: tabValue.all
  },
  {
    name: "By me",
    value: tabValue.byMe
  },
  {
    name: "To my name",
    value: tabValue.toMe
  },
]),
redemptionTab = ref(0),

headerRedemptions = [
  { title: 'Asset ID', key: 'asset_id', sortable: false },
  { title: 'Redeemed By', key: 'redeemedBy', sortable: false },
  { title: 'Beneficiary', key: 'beneficiary', sortable: false },
  { title: 'Energy source', key: 'energy_source', sortable: false },
  { title: 'Price (ICP)', key: 'price', align: 'center', sortable: false },
  { title: 'MWh', key: 'mwh', sortable: false },
  { title: 'Country', key: 'country', sortable: false },
  { title: 'Date', key: 'date', sortable: false },
],
redemptions = ref([]),
loadingRedemptions = ref(true),
currentRedemptionPage = ref(1),
redemptionsPerPage = ref(50),
totalRedemptionPages = ref(1),


windowStepComputed = computed(() => {
  if (window.innerWidth > 960) {
    return 1;
  } else {
    return 2;
  }
}),

redemptionsByMe = computed(() => redemptions.value.filter(e => e.redeemedBy.toString() === profile.value?.principalId.toString())),
redemptionsToMe = computed(() => redemptions.value.filter(e => {
  const principalId = profile.value?.principalId.toString()

  return e.redeemedBy.toString() !== principalId && e.beneficiary.toString() === principalId
})),

filteredRedemptions = computed(() => {
  switch (redemptionTabs.value[redemptionTab.value].value) {
    case tabValue.all:
      return redemptions.value;

    case tabValue.byMe:
      return redemptionsByMe.value;

    case tabValue.toMe:
      return redemptionsToMe.value;
  }
}),


renewableEnergies = computed(() => filteredRedemptions.value?.reduce((acc, item) => {
  let existenceElement = acc.find(elem => elem.energy_source === item.energy_source);

  if (existenceElement) {
    existenceElement.mwh += item.mwh;
  } else {
    acc.push({ ...item });
  }
  return acc;
}, []) ?? []),

calcMwh = (redemptions) => {
  console.log("redemptions -->", redemptions);

  return redemptions.map(e => e.mwh).reduce((a, b) => a + b, 0)
}


watch(windowStepComputed, (newVal) => {
  windowStep.value = newVal;
}, { immediate: true })


onBeforeMount(getData)


async function getData() {
  profile.value = UserProfileModel.get()
  profile.value.country = 'CL'

  await getRedemptions()
}

async function getRedemptions() {
  loadingRedemptions.value = true

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
      length: redemptionsPerPage.value,
      page: currentRedemptionPage.value,
      txType: TxType.redemption,
      country: filters.value.country,
      // priceRange: filters.value.priceRange,
      mwhRange: filters.value.mwhRange,
      assetTypes,
      method: filters.value.method,
      rangeDates,
    }),
    list = []


    // build redemptions
    for (const item of data) {
      list.push({
        asset_id: item.assetInfo.tokenId,
        redeemedBy: item.from,
        beneficiary: item.to,
        energy_source: item.assetInfo.assetType,
        // price: item.priceE8S,
        mwh: item.tokenAmount,
        country: item.assetInfo.specifications.country,
        date: item.date.toDateString(),
      })
    }

    redemptions.value = list.sort((a, b) => a.asset_id - b.asset_id)
    totalRedemptionPages.value = total
  } catch (error) {
    toast.error(error.toString())
  }

  loadingRedemptions.value = false
}

async function getPreviewProfile(value, uid) {
  if (!value) previewProfile.value = null

  try {
    previewProfile.value = await AgentCanister.getProfile(uid)
  } catch (error) {
    toast.error(error)
  }
}

function goDetails() {}
</script>