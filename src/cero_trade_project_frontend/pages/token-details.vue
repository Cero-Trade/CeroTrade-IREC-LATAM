<template>
  <modal-approve
    ref="modalApprove"
    :token-id="tokenId"
    :amount-in-icp="amountInIcp"
    :fee-in-e8s="feeInE8S"
    @approve="() => {
      if (dialogPurchaseReview)
        purchaseToken()
      else if (dialogRedeem || dialogRedeemCertificates)
        redeemToken()
    }"
  ></modal-approve>

  <modal-confirm
    ref="modalRequestRedeem"
    title="Do you want to send redeem request"
    :content="`you agree to send a request to ${beneficiaries?.find(e => e.principalId === formRedeem.beneficiary)?.companyName ?? 'your beneficiary'} to redeem ${(tokenAmount ?? 0) > 1 ? 'tokens' : 'token'} in his name`"
    @accept="requestRedeemToken"
  />

  <div id="token-details">
    <span class="mb-10 acenter" style="color: #475467; font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span class="text-first">{{ prevRoutePatch }}</span>
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span style="color: #00555B;">Asset # {{ tokenId }}</span>
    </span>
    <h3 class="acenter mb-4" :title="tokenId" style="width: max-content">
      <company-logo
        :energy-src="energies[tokenDetail?.assetInfo.deviceDetails.deviceType]"
        :country-src="countriesImg[tokenDetail?.assetInfo.specifications.country]"
        class="mr-4"
      ></company-logo>
      Asset # {{ shortString(tokenId, {}) }}
    </h3>

    <v-row>
      <v-col xl="8" lg="8" md="8" cols="12">
        <v-row>
          <v-col xl="5" lg="5" cols="12">
            <v-card class="card cards-rec">
              <div class="jspace divrow mb-1">
                <span style="color: #475467;">Type</span>
                <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                  <img :src="energiesColored[tokenDetail?.assetInfo.deviceDetails.deviceType]" :alt="`${tokenDetail?.assetInfo.deviceDetails.deviceType} icon`" style="width: 20px;">
                  {{ tokenDetail?.assetInfo.deviceDetails.deviceType }} energy
                </span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">Start date of production</span>
                <span>{{ tokenDetail?.assetInfo.startDate.toDateString() }}</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">End date of production</span>
                <span>{{ tokenDetail?.assetInfo.endDate.toDateString() }}</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">CO2 Emission</span>
                <span>{{ tokenDetail?.assetInfo.co2Emission }}%</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">Radioactivity emission</span>
                <span>{{ tokenDetail?.assetInfo.radioactivityEmnission }}%</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">Total volume produced</span>
                <span>{{ tokenDetail?.assetInfo.volumeProduced }}</span>
              </div>
            </v-card>
          </v-col>

          <v-col xl="4" lg="4" cols="12">
            <v-card class="card relative" style="min-height: 100%!important;">
              <span>Amount minted in CT / total produced</span>
              <div id="chart">
                <apexchart type="radialBar" :options="chartOptions" :series="seriesMintedVsProduced"></apexchart>
              </div>
            </v-card>
          </v-col>

          <v-col xl="3" lg="3" cols="12">
            <v-card class="card divcol jspace absolute-card-portfolio mb-2">
              <span>Total amount owned</span>
              <h5 class="bold" style="position: absolute; bottom: 0; left: 20px;">{{ tokenDetail?.totalAmount }} MWh</h5>
            </v-card>

            <v-card class="card divcol jspace absolute-card-portfolio">
              <span>Amount for sale</span>
              <h5 class="bold" style="position: absolute; bottom: 0; left: 20px;">{{ tokenDetail?.inMarket }} MWh</h5>
            </v-card>
          </v-col>
          <v-col cols="12">
            <v-card class="card" style="padding-left: 20px!important;">
              <v-tabs
                v-model="tabsSpecifications"
                bg-color="transparent"
                color="basil"
                class="mt-6"
              >
                <v-tab value="one" class="tab-btn" style="border: none!important; border-radius: 0px!important;">
                  Device Details
                </v-tab>
                <v-tab value="two" class="tab-btn" style="border: none!important; border-radius: 0px!important;">
                  Specifications
                </v-tab>
                <v-tab value="three" class="tab-btn delete-mobile" style="border: none!important; border-radius: 0px!important;">
                  Dates
                </v-tab>
              </v-tabs>

              <hr style="border-bottom: 2px solid rgba(0,0,0,0.25)!important; width: 100%!important; position: relative; top: -2px;">
              <v-window v-model="tabsSpecifications">
                <v-window-item value="one">
                  <h5 class="bold mb-6 mt-4">Device Details</h5>

                  <v-row>
                    <v-col xl="8" lg="8" md="8" cols="12">
                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Name</span>
                        <span>{{ tokenDetail?.assetInfo.deviceDetails.name }}</span>
                      </div>

                      <div class="jspace divrow mb-1">
                        <span style="color: #475467;">Type</span>
                        <span>{{ tokenDetail?.assetInfo.deviceDetails.deviceType }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Device group</span>
                        <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                          <img :src="energiesColored[tokenDetail?.assetInfo.deviceDetails.deviceType]" :alt="`${tokenDetail?.assetInfo.deviceDetails.deviceType} icon`" style="width: 20px;">
                          {{ tokenDetail?.assetInfo.deviceDetails.deviceType }}
                        </span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1" style="gap: 20px;">
                        <span style="color: #475467;">Description</span>
                        <span style="text-align: right; max-width: 60%;">{{ tokenDetail?.assetInfo.deviceDetails.description }}</span>
                      </div>
                    </v-col>
                  </v-row>
                </v-window-item>

                <v-window-item value="two">
                  <h5 class="bold mb-6 mt-4">Specifications</h5>

                  <v-row>
                    <v-col xl="8" lg="8" md="8" cols="12">
                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Device Code</span>
                        <span>{{ tokenDetail?.assetInfo.specifications.deviceCode }}</span>
                      </div>

                      <div class="jspace divrow mb-1">
                        <span style="color: #475467;">Capacity</span>
                        <span>{{ tokenDetail?.assetInfo.specifications.capacity }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Location</span>
                        <span>{{ tokenDetail?.assetInfo.specifications.location }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Latitude</span>
                        <span>{{ tokenDetail?.assetInfo.specifications.latitude }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Longitude</span>
                        <span>{{ tokenDetail?.assetInfo.specifications.longitude }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Address</span>
                        <span>{{ tokenDetail?.assetInfo.specifications.address }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">State/Province</span>
                        <span>{{ tokenDetail?.assetInfo.specifications.stateProvince }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Country</span>
                        <span>{{ tokenDetail?.assetInfo.specifications.country }}</span>
                      </div>
                    </v-col>
                  </v-row>
                </v-window-item>

                <v-window-item value="three">
                  <h5 class="bold mb-6 mt-4">Dates</h5>

                  <v-row class="mt-3">
                    <v-col xl="8" lg="8" md="8" cols="12">
                      <div
                        v-for="(date, index) in tokenDetail?.assetInfo.dates" :key="index"
                        class="jspace divrow mb-1"
                      >
                        <span style="color: #475467;">{{
                          index === 0 ? "Registration Date"
                          : index === 1 ? "Commissioning Date"
                          : "Expire Date"
                        }}</span>
                        <span>{{ date.toDateString() }}</span>
                      </div>
                    </v-col>
                  </v-row>
                </v-window-item>
              </v-window>
            </v-card>
          </v-col>

          <v-col cols="12">
            <div class="flex-space-center mb-4" style="gap: 10px">
              <h5 class="bold mb-0">Sellers</h5>

              <v-btn class="btn" @click="dialogFilters = true">
                <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
                Add filter
              </v-btn>
            </div>

            <v-data-table
            v-model:items-per-page="itemsPerPage"
            :items-per-page-options="[
              {value: 10, title: '10'},
              {value: 25, title: '25'},
              {value: 50, title: '50'},
            ]"
            :headers="headers"
            :items="dataMarketplace"
            :items-length="totalPages"
            :loading="loadingMarketplace"
            class="my-data-table deletemobile"
            density="compact"
            @update:options="getMarketPlace()"
            >
              <template #[`item.seller`]="{ item }">
                <v-menu :close-on-content-click="false" @update:model-value="(value) => getSellerProfile(value, item.seller)">
                  <template #activator="{ props }">
                    <a v-bind="props" class="pointer flex-acenter" style="gap: 5px; max-width: 200px">{{ shortPrincipalId(item.seller?.toString()) }}</a>
                  </template>

                  <v-card class="px-4 py-2 bg-secondary d-flex flex-column">
                    <v-progress-circular
                      v-if="!previewSeller"
                      indeterminate
                      color="rgb(var(--v-theme-primary))"
                      class="mx-auto"
                    ></v-progress-circular>

                    <span v-else class="flex-acenter" style="gap: 10px; text-wrap: nowrap">
                      <v-img-load
                        :src="previewSeller.companyLogo"
                        :alt="`${previewSeller.companyName} logo`"
                        cover
                        sizes="30px"
                        rounded="50%"
                        class="flex-grow-0"
                      />
                      {{ previewSeller.companyName }}
                    </span>
                  </v-card>
                </v-menu>
              </template>

              <template #[`item.price`]="{ item }">
                <span class="divrow jspace acenter">
                  {{ item.price }} <v-sheet class="chip-currency bold">{{ item.currency }}</v-sheet>
                </span>
              </template>

              <template #[`item.country`]="{ item }">
                <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                  <img :src="countriesImg[item.country]" :alt="`${item.country} Icon`" style="width: 20px;">
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
                <v-chip @click="selectSeller(item)" color="white" class="chip-table mr-1" style="border-radius: 10px!important;">
                  <span style="color: #000 !important; font-size: 12px !important">Buy</span>
                </v-chip>
              </template>
            </v-data-table>


            <v-progress-circular
              v-if="loadingMarketplace"
              indeterminate
              size="60"
              color="rgb(var(--v-theme-primary))"
              class="showmobile mx-auto my-16"
            ></v-progress-circular>

            <span v-else-if="!dataMarketplace.length" class="text-center my-16 showmobile">No data available</span>

            <v-col v-else v-for="(item,index) in dataMarketplace" :key="index" xl="3" lg="3" md="4" sm="6" cols="12" class="showmobile">
              <v-card class="card cards-marketplace">
                <v-btn class="ml-auto mb-2 btn" @click="selectSeller(item)">Buy</v-btn>

                <div class="jspace divrow mb-1">
                  <span>Seller ID</span>

                  <v-menu :close-on-content-click="false" @update:model-value="(value) => getSellerProfile(value, item.seller)">
                    <template #activator="{ props }">
                      <a v-bind="props" style="color: #475467;" class="acenter pointer text-capitalize">{{ shortPrincipalId(item.seller?.toString()) }}</a>
                    </template>

                    <v-card class="px-4 py-2 bg-secondary d-flex">
                      <v-progress-circular
                        v-if="!previewSeller"
                        indeterminate
                        color="rgb(var(--v-theme-primary))"
                        class="mx-auto"
                      ></v-progress-circular>

                      <span v-else class="flex-acenter" style="gap: 10px; text-wrap: nowrap">
                        <v-img-load
                          :src="previewSeller.companyLogo"
                          :alt="`${previewSeller.companyName} logo`"
                          cover
                          sizes="30px"
                          rounded="50%"
                          class="flex-grow-0"
                        />
                        {{ previewSeller.companyName }}
                      </span>
                    </v-card>
                  </v-menu>
                </div>

                <div class="jspace divrow mb-1">
                  <span>Price</span>
                  <span style="color: #475467;">{{ item.currency }} {{ item.price }}</span>
                </div>

                <div class="jspace divrow mb-1">
                  <span>Country</span>
                  <span style="color: #475467;" class="acenter text-capitalize">
                    <img :src="countriesImg[item.country]" alt="icon" class="mr-1" style="width: 20px;"> {{ item.country }}
                  </span>
                </div>

                <div class="jspace divrow mb-1">
                  <span>MWh</span>
                  <span class="d-flex flex-acenter mr-1" style="color: #475467;">
                    <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon" style="width: 20px">
                  {{ item.mwh }}</span>
                </div>
              </v-card>
            </v-col>

            <v-pagination
              v-model="currentPage"
              :length="totalPages"
              :disabled="loadingMarketplace"
              class="mt-4"
              @update:model-value="getMarketPlace()"
            ></v-pagination>
          </v-col>
        </v-row>
      </v-col>

      <v-col xl="4" lg="4" md="4" cols="12">
        <v-col cols="12" class="pt-0 pl-0">
          <v-form v-model="amountSelected" @submit.prevent>
            <v-card class="card mb-6 divcol astart card-currency">
              <div class="jspace" style="width: 100%;">
                <div class="divcol mr-2" style="gap: 10px;">
                  <label>Choose quantity (MWh)</label>
                  <div class="divrow" style="gap: 5px;">
                    <v-btn class="btn2" style="max-height: 40px!important;"
                      @click="tokenAmount ? tokenAmount-- : null"
                    >-</v-btn>
                    <v-text-field
                    v-model="tokenAmount"
                    class="input hide-spin" variant="outlined" elevation="0"
                    type="number"
                    :rules="[globalRules.requiredNumber]"
                    ></v-text-field>
                    <v-btn class="btn2" style="max-height: 40px!important;"
                      @click="tokenAmount ? tokenAmount++ : tokenAmount=1"
                    >+</v-btn>
                  </div>
                </div>
              </div>
            </v-card>

            <div class="divrow mb-4" style="gap: 10px; flex-wrap: wrap;">
              <v-btn v-if="haveToken" class="btn btn2" @click="showDialog('sell')" style="flex: 1 1 calc(50% - 10px)">
                Sell
              </v-btn>

              <v-btn v-if="haveTokenInMarket" class="btn btn2" @click="showDialog('takeOff')" style="flex: 1 1 calc(50% - 10px)">
                Take off market
              </v-btn>

              <v-btn class="btn btn2" @click="showDialog('buy')" style="flex: 1 1 calc(50% - 10px)">
                Buy
              </v-btn>

              <v-btn v-if="haveToken" :loading="!beneficiaries" class="btn" @click="showDialog('redeem')" style="flex: 1 1 calc(50% - 10px)">
                Redeem Token
              </v-btn>
            </div>

            <!-- TODO commented until api connection -->
            <!-- <div v-for="(item,index) in dataPdf" :key="index" class="border mb-2 jspace">
              <div class="divrow acenter">
                <img src="@/assets/sources/icons/pdf.svg" alt="PDF">
                <div class="divcol ml-2">
                  <span style="color: #475467; font-weight: 500;">{{ item.name }}</span>
                  <span style="color: #475467;">{{ item.weight }}</span>
                </div>
              </div>

              <v-card class="card center" style="width: max-content!important; border-radius: 10px!important;">
                <img src="@/assets/sources/icons/download.svg" alt="download icon" style="width: 18px">
              </v-card>
            </div> -->


            <!-- TODO commented until api connection -->
            <!-- <v-card class="card divcol pt-6">
              <span style="color: #475467;">Redemption amount (MWh)</span>
              <span class="mt-2 mb-4" style="color: #475467;">
                <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon" style="width: 15px">
                420
              </span>

              <span style="color: #475467;">Redemption Date</span>
              <span class="mt-2 mb-4">{{ date }}</span>

              <div v-for="(item,index) in dataPdf" :key="index" class="border mb-2 jspace">
                <div class="divrow acenter">
                  <img src="@/assets/sources/icons/pdf.svg" alt="PDF">
                  <div class="divcol ml-2">
                    <span style="color: #475467; font-weight: 500;">{{ item.name }}</span>
                    <span style="color: #475467;">{{ item.weight }}</span>
                  </div>
                </div>

                <v-card class="card center" style="width: max-content!important; border-radius: 10px!important;">
                  <img src="@/assets/sources/icons/download.svg" alt="download icon" style="width: 18px">
                </v-card>
              </div>
            </v-card> -->
          </v-form>
        </v-col>
      </v-col>
    </v-row>
    
    <!-- Dialog Take off market -->
    <v-dialog v-model="dialogTakeOffMarket" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogTakeOffMarket = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
          </v-sheet>
        </v-sheet>
        <h6>Take off market details</h6>
        <span class="tertiary">You are about to take some of your tokens off the marketplace. They will just be stored in your portafolio now.</span>

        <v-card class="card mt-6 pa-6">
          <span class="bold mt-3">Checkout review</span>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 150%; position: relative; left: -50px;"></v-divider>
          
          <div class="jspace divrow mb-4 acenter">
            <h5 class="acenter mb-0 bold h5-mobile" :title="tokenId">
              <company-logo
                :energy-src="energies[tokenDetail?.assetInfo.deviceDetails.deviceType]"
                :country-src="countriesImg[tokenDetail?.assetInfo.specifications.country]"
                class="mr-4"
              ></company-logo>
              #{{ shortString(tokenId, {}) }}
            </h5>
          </div>
          
          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[tokenDetail?.assetInfo.deviceDetails.deviceType]" :alt="`${tokenDetail?.assetInfo.deviceDetails.deviceType} icon`" style="width: 20px;">
              {{ tokenDetail?.assetInfo.deviceDetails.deviceType }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Country</span>
            <span class="flex-center" style="gap: 5px">
              <img :src="countriesImg[tokenDetail?.assetInfo.specifications.country]" :alt="`${tokenDetail?.assetInfo.specifications.country} flag`">
              {{ tokenDetail?.assetInfo.specifications.country }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Amount</span>
            <span>{{ tokenAmount }} MWh</span>
          </div>
        </v-card>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogTakeOffMarket = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogTakeOffMarket = false; takeOffMarket()" style="border: none!important;">Take off market</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Dialog redeem sure -->
    <v-dialog v-model="dialogRedeemSure" persistent>
      <v-card class="card dialog-card-tokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogRedeemSure = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/refresh.svg" alt="refresh icon">
          </v-sheet>
        </v-sheet>
        <h6>Are you sure you want to redeem your I-REC?</h6>
        <span class="tertiary">By redeeming your I-RECs, the associated tokens will be irreversibly burnt and sent to a burn wallet, removing them from circulation. The I-RECs will then be officially redeemed in your name, rendering them non-tradeable. This process is utilized to claim certifications and other environmental benefits. Once completed, this action is final and cannot be reversed.</span>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogRedeemSure = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogRedeemSure = false;  dialogRedeem = true" style="border: none!important;">Yes, I am sure</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Dialog Redeem -->
    <v-dialog v-model="dialogRedeem" persistent>
      <v-form ref="formRedeemRef" @submit.prevent>
        <v-card class="card dialog-card-detokenize">
          <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogRedeem = false">
          <v-sheet class="mb-6 double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
            </v-sheet>
          </v-sheet>
          <h6>IREC redemption details</h6>
          <span class="tertiary mb-4">Please check all information on your tokenized assets’ redemption. You can redeem them to your own name, or to another company’s name by deeming them a beneficiary of yours.</span>

          <label :for="formRedeem.periodStart ? 'periodEnd' : 'periodStart'" class="mb-1">Redemption period dates</label>
          <div class="d-flex mb-4" style="gap: 20px;">
            <v-menu v-model="periodStartMenu" :close-on-content-click="false">
              <template v-slot:activator="{ props }">
                <v-text-field
                  id="periodStart"
                  v-model="formRedeem.periodStart"
                  placeholder="Select period start (required)"
                  readonly v-bind="props"
                  variant="outlined"
                  density="compact"
                  class="select mb-2"
                  style="flex-basis: 50%;"
                  :rules="[globalRules.required, (v) => {
                    const periodEnd = formRedeem.periodEnd
                    if (periodEnd && moment(v).isAfter(periodEnd)) return 'Period start cant be major than period end'
                    return null
                  }]"
                >
                  <template #append-inner>
                    <img
                      v-if="formRedeem.periodStart"
                      src="@/assets/sources/icons/close.svg"
                      alt="close icon"
                      class="pointer"
                      @click="formRedeem.periodStart = null"
                    >
                  </template>
                </v-text-field>
              </template>

              <v-date-picker
                title=""
                color="rgb(var(--v-theme-secondary))"
                hide-actions
                @update:model-value="(v) => { formRedeem.periodStart = moment(v).format('YYYY/MM/DD') }"
              >
                <template v-slot:header></template>
              </v-date-picker>
            </v-menu>


            <v-menu v-model="periodEndMenu" :close-on-content-click="false">
              <template v-slot:activator="{ props }">
                <v-text-field
                  id="periodEnd"
                  v-model="formRedeem.periodEnd"
                  placeholder="Select period end (required)"
                  readonly v-bind="props"
                  variant="outlined"
                  density="compact"
                  class="select mb-2"
                  style="flex-basis: 50%;"
                  :rules="[globalRules.required, (v) => {
                    const periodStart = formRedeem.periodStart
                    if (periodStart && moment(v).isBefore(periodStart)) return 'Period end cant be minor than period start'
                    return null
                  }]"
                >
                  <template #append-inner>
                    <img
                      v-if="formRedeem.periodEnd"
                      src="@/assets/sources/icons/close.svg" alt="close icon"
                      class="pointer"
                      @click="formRedeem.periodEnd = null"
                    >
                  </template>
                </v-text-field>
              </template>

              <v-date-picker
                title=""
                color="rgb(var(--v-theme-secondary))"
                hide-actions
                @update:model-value="(v) => { formRedeem.periodEnd = moment(v).format('YYYY/MM/DD') }"
              >
                <template v-slot:header></template>
              </v-date-picker>
            </v-menu>
          </div>

          <div class="flex-column mb-4" style="gap: 5px">
            <label for="locale" class="mb-1">Locale assigned to redemption</label>
            <v-select
              v-model="formRedeem.locale"
              id="locale"
              variant="solo" flat
              :items="locales"
              class="select mb-2"
              bg-color="transparent"
              placeholder="locale (required)"
              :rules="[globalRules.required]"
            ></v-select>
          </div>

          <div class="flex-column mb-4" style="gap: 5px">
            <label for="beneficiary" class="mb-1">Beneficiary account (company)</label>
            <v-select
              v-model="formRedeem.beneficiary"
              id="beneficiary"
              variant="solo" flat
              :items="beneficiaries"
              item-title="companyName"
              item-value="principalId"
              class="select mb-2"
              bg-color="transparent"
              placeholder="beneficiary account (optional)"
              :rules="[true]"
            ></v-select>
          </div>

          <!-- <v-btn class="btn2" style="width: max-content !important">Add beneficiary</v-btn> -->

          <v-card class="card cards-rec pa-6">
            <span class="bold mt-3">Checkout review</span>

            <v-divider class="mb-3 mt-4"  thickness="2" style="width: 150%; position: relative; left: -50px;"></v-divider>
            
            <div class="jspace divrow mb-2 acenter">
              <h5 class="acenter h5-mobile" :title="tokenId">
                <company-logo
                  :energy-src="energies[tokenDetail?.assetInfo.deviceDetails.deviceType]"
                  :country-src="countriesImg[tokenDetail?.assetInfo.specifications.country]"
                  class="mr-4"
                ></company-logo>
                #{{ shortString(tokenId, {}) }}
              </h5>
            </div>

            <div class="jspace divrow mb-1">
              <span style="color: #475467;">Energy source type</span>
              <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                <img :src="energiesColored[tokenDetail?.assetInfo.deviceDetails.deviceType]" :alt="`${tokenDetail?.assetInfo.deviceDetails.deviceType} icon`" style="width: 20px;">
                {{ tokenDetail?.assetInfo.deviceDetails.deviceType }}
              </span>
            </div>

            <div class="jspace divrow mb-1">
              <span style="color: #475467;">Country</span>
              <span class="flex-center" style="gap: 5px">
                <img :src="countriesImg[tokenDetail?.assetInfo.specifications.country]" :alt="`${tokenDetail?.assetInfo.specifications.country} flag`">
                {{ tokenDetail?.assetInfo.country }}
              </span>
            </div>

            <div class="jspace divrow mb-1">
              <span style="color: #475467;">Amount</span>
              <span>{{ tokenAmount }} MWh</span>
            </div>

            <v-divider class="mb-3 mt-4"  thickness="2" style="width: 100%;"></v-divider>

            <div class="jspace divrow mt-1">
              <span>Transaction fee</span>
              <span>{{ convertE8SToICP(feeInE8S) }} ICP</span>
            </div>
            <div class="jspace divrow mt-1">
              <span>Cero trade comission</span>
              <span>{{ convertE8SToICP(ceroComisison) }} ICP</span>
            </div>
            <div class="jspace divrow mt-1">
              <span class="bold">Total</span>
              <span class="bold">{{ maxDecimals(amountInIcp + convertE8SToICP(feeInE8S) + convertE8SToICP(ceroComisison), 4) }} ICP</span>
            </div>
          </v-card>

          <div class="border-card mt-6">
            <div class="jspace divrow">
              <span class="bold">Payment method</span>
              <div class="divrow mb-4" style="gap: 10px;">
                <!-- <img src="@/assets/sources/icons/visa.svg" alt="Visa">
                <img src="@/assets/sources/icons/mastercard.svg" alt="Mastercard">
                <img src="@/assets/sources/icons/mastercard-yellow.svg" alt="Mastercard"> -->
                <img src="@/assets/sources/icons/internet-computer-icon.svg" alt="icp">
              </div>
            </div>

            <!-- TODO commented for while -->
            <!-- <div class="jspace divrow">
              <v-btn class="btn" style="background-color: #fff!important; width: max-content!important;">Change</v-btn>

              <span class="bold">Payment with ICP</span>
            </div> -->
          </div>

          <div class="divrow center mt-6" style="gap: 10px;">
            <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogRedeem = false">Cancel</v-btn>
            <v-btn class="btn" @click="async () => {
              if (!(await formRedeemRef.validate()).valid) return

              // if beneficiary provided
              if (formRedeem.beneficiary) {
                modalRequestRedeem.model = true

              // if beneficiary not provided
              } else {
                modalApprove.model = true
              }
            }" style="border: none!important;">Redeem</v-btn>
          </div>
        </v-card>
      </v-form>
    </v-dialog>

    <!-- Dialog static price -->
    <v-dialog v-model="dialogStaticPrice" persistent>
      <v-form ref="formStaticPrice" @submit.prevent>
        <v-card class="card dialog-card-detokenize">
          <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogStaticPrice = false">
          <v-sheet class="mb-6 double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/sell.svg" alt="Sell" style="width: 20px; height: 20px;">
            </v-sheet>
          </v-sheet>
          <h6 class="bold">Price</h6>
          <span class="tertiary mb-4">Set the price you want to sell every MWh of your tokenized asset for. The price is set in ICP.</span>

          <label for="sale_amount">Sale amount</label>

          <v-text-field
            v-model="tokenPrice"
            id="card-number" class="input textfield-select" variant="solo"  flat
            elevation="0" placeholder="10"
            type="number"
            :rules="[globalRules.requiredNumber]"
          >
            <template #append-inner>
              <img
                title="Amount per 1 MWh"
                src="@/assets/sources/icons/help-circle.svg"
                alt="help-circle icon"
                class="mr-2"
                style="width: 18px"
              >

              ICP

              <!-- <v-select
                v-model="selectedCurrency"
                :items="itemsCurrency"
                variant="solo"
                flat
                density="compact"
                menu-icon=""
                class="select"
                bg-color="transparent"
                hide-details
                style="color: #000;z-index: 99;"
              >
                <template #append-inner="{ isFocused }">
                  <img
                    src="@/assets/sources/icons/chevron-down.svg"
                    alt="chevron-down icon"
                    :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
                  >
                </template>
              </v-select> -->
            </template>
          </v-text-field>
          

          <div class="divrow center mt-6" style="gap: 10px;">
            <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogStaticPrice = false;">
              <img src="@/assets/sources/icons/arrow-left.svg" alt="arrow-left icon">
              Back
            </v-btn>
            <v-btn class="btn" @click="async () => {
              if (!(await formStaticPrice.validate()).valid) return

              dialogSellingDetailsReview = true
              dialogStaticPrice = false;
            }
            " style="border: none!important;">Confirm</v-btn>
          </div>
        </v-card>
      </v-form>
    </v-dialog>

    <!-- Dialog selling details review -->
    <v-dialog v-model="dialogSellingDetailsReview" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogSellingDetailsReview = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
          </v-sheet>
        </v-sheet>
        <h6>Selling details review</h6>
        <span class="tertiary">Please check all details regarding the sale of your tokenized asset before you proceed, including the price and amount in MWh you will to put on the market.</span>

        <v-card class="card mt-6 pa-6">
          <span class="bold mt-3">Checkout review</span>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 150%; position: relative; left: -50px;"></v-divider>
          
          <div class="jspace divrow mb-4 acenter">
            <h5 class="acenter mb-0 bold h5-mobile" :title="tokenId">
              <company-logo
                :energy-src="energies[tokenDetail?.assetInfo.deviceDetails.deviceType]"
                :country-src="countriesImg[tokenDetail?.assetInfo.specifications.country]"
                class="mr-4"
              ></company-logo>
              #{{ shortString(tokenId, {}) }}
            </h5>
            <div class="divrow mb-0 astart acenter">
              <h5 class="mb-0 mr-2 h5-mobile">
                {{ tokenPrice ?? 0 }} ICP
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>          
          </div>


          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[tokenDetail?.assetInfo.deviceDetails.deviceType]" :alt="`${tokenDetail?.assetInfo.deviceDetails.deviceType} icon`" style="width: 20px;">
              {{ tokenDetail?.assetInfo.deviceDetails.deviceType }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Country</span>
            <span class="flex-center" style="gap: 5px">
              <img :src="countriesImg[tokenDetail?.assetInfo.specifications.country]" :alt="`${tokenDetail?.assetInfo.country} flag`">
              {{ tokenDetail?.assetInfo.country }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Amount</span>
            <span>{{ tokenAmount }} MWh</span>
          </div>
        </v-card>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogSellingDetailsReview = false">Cancel</v-btn>
          <v-btn class="btn" @click="putOnSale()" style="border: none!important;">Put on the market</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Dialog choose seller -->
    <v-dialog v-model="dialogChooseSeller" persistent>
      <v-form ref="formChooseSeller" @submit.prevent>
        <v-card class="card dialog-card-detokenize">
          <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogChooseSeller = false">
          <v-sheet class="mb-6 double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
            </v-sheet>
          </v-sheet>
          <h6>Choose seller</h6>
          <span class="tertiary">This is a list of all sellers of this tokenized asset.</span>

          <v-btn class="btn ml-auto my-3" style="max-width: max-content !important" @click="dialogFilters = true">
            <img src="@/assets/sources/icons/filter-lines.svg" alt="filter-lines icon">
            Add filter
          </v-btn>

          <v-data-table
          v-model:items-per-page="itemsPerPage"
          :items-per-page-options="[
            {value: 10, title: '10'},
            {value: 25, title: '25'},
            {value: 50, title: '50'},
          ]"
          :headers="headers"
          :items="dataMarketplace"
          :items-length="totalPages"
          :loading="loadingMarketplace"
          class="my-data-table deletemobile"
          density="compact"
          @update:options="getMarketPlace"
          >
            <template #[`item.seller`]="{ item }">
              <v-menu :close-on-content-click="false" @update:model-value="(value) => getSellerProfile(value, item.seller)">
                <template #activator="{ props }">
                  <a v-bind="props" class="pointer flex-acenter" style="gap: 5px; max-width: 200px">{{ shortPrincipalId(item.seller?.toString()) }}</a>
                </template>

                <v-card class="px-4 py-2 bg-secondary d-flex flex-column">
                  <v-progress-circular
                    v-if="!previewSeller"
                    indeterminate
                    color="rgb(var(--v-theme-primary))"
                    class="mx-auto"
                  ></v-progress-circular>

                  <span v-else class="flex-acenter" style="gap: 10px; text-wrap: nowrap">
                    <v-img-load
                      :src="previewSeller.companyLogo"
                      :alt="`${previewSeller.companyName} logo`"
                      cover
                      sizes="30px"
                      rounded="50%"
                      class="flex-grow-0"
                    />
                    {{ previewSeller.companyName }}
                  </span>
                </v-card>
              </v-menu>
            </template>

            <template #[`item.price`]="{ item }">
              <span class="divrow jspace acenter">
                {{ item.price }} <v-sheet class="chip-currency bold">{{ item.currency }}</v-sheet>
              </span>
            </template>

            <template #[`item.country`]="{ item }">
              <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                <img :src="countriesImg[item.country]" :alt="`${item.country} Icon`" style="width: 20px;">
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
              <v-chip @click="selectSeller(item)" color="white" class="chip-table mr-1" style="border-radius: 10px!important;">
                <span style="color: #000 !important; font-size: 12px !important">Buy</span>
              </v-chip>
            </template>
          </v-data-table>

          <v-pagination
            v-model="currentPage"
            :length="totalPages"
            :disabled="loadingMarketplace"
            class="mt-4"
            @update:model-value="getMarketPlace()"
          ></v-pagination>
        </v-card>
      </v-form>
    </v-dialog>

    <!-- Dialog purchase review -->
    <v-dialog v-model="dialogPurchaseReview" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogPurchaseReview = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
          </v-sheet>
        </v-sheet>
        <h6>Purchase review</h6>
        <span class="tertiary">Please make sure all details on your token purchase are correct and you agree with transaction and tax fees. After selecting your payment method, please proceed with payment.</span>

        <v-card class="card cards-rec mt-6 pa-6">
          <span class="bold mt-3">Checkout review</span>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 150%; position: relative; left: -50px;"></v-divider>
          
          <div class="jspace divrow mb-2 acenter">
            <h5 class="acenter h5-mobile" :title="tokenId">
              <company-logo
                :energy-src="energies[tokenDetail?.assetInfo.deviceDetails.deviceType]"
                :country-src="countriesImg[tokenDetail?.assetInfo.specifications.country]"
                class="mr-4"
              ></company-logo>
              #{{ shortString(tokenId, {}) }}
            </h5>
            <div class="divrow astart acenter">
              <h5 class="mr-2 h5-mobile">
                {{ tokenPrice ?? 0 }} ICP
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[tokenDetail?.assetInfo.deviceDetails.deviceType]" :alt="`${tokenDetail?.assetInfo.deviceDetails.deviceType} icon`" style="width: 20px;">
              {{ tokenDetail?.assetInfo.deviceDetails.deviceType }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Region</span>
            <span>{{ tokenDetail?.assetInfo.specifications.region }}</span>
          </div>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 100%;"></v-divider>

          <div class="jspace divrow mt-1">
            <span>Transaction fee</span>
            <span>{{ convertE8SToICP(feeInE8S) }} ICP</span>
          </div>
          <div class="jspace divrow mt-1">
            <span>Cero trade comission</span>
            <span>{{ convertE8SToICP(ceroComisison) }} ICP</span>
          </div>
          <div class="jspace divrow mt-1">
            <span class="bold">Total</span>
            <span class="bold">{{ maxDecimals(amountInIcp + convertE8SToICP(feeInE8S) + convertE8SToICP(ceroComisison), 4) }} ICP</span>
          </div>
        </v-card>

        <div class="border-card mt-6">
          <div class="jspace divrow">
            <span class="bold">Payment method</span>
            <div class="divrow mb-4" style="gap: 10px;">
              <!-- <img src="@/assets/sources/icons/visa.svg" alt="Visa">
              <img src="@/assets/sources/icons/mastercard.svg" alt="Mastercard">
              <img src="@/assets/sources/icons/mastercard-yellow.svg" alt="Mastercard"> -->
              <img src="@/assets/sources/icons/internet-computer-icon.svg" alt="icp">
            </div>
          </div>

          <!-- TODO commented for while -->
          <!-- <div class="jspace divrow">
            <v-btn class="btn" style="background-color: #fff!important; width: max-content!important;">Change</v-btn>

            <span class="bold">Payment with ICP</span>
          </div> -->
        </div>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogPurchaseReview = false">Cancel</v-btn>
          <v-btn class="btn" @click="modalApprove.model = true" style="border: none!important;">Proceed with payment</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Dialog payment confirm -->
    <v-dialog v-model="dialogPaymentConfirm" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogPaymentConfirm = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon" style="width: 22px">
          </v-sheet>
        </v-sheet>
        <h6>Payment confirmation</h6>
        <span class="tertiary">The transaction was done succesfully. You can now check your Portafolio to find your new token. In the receipt bellow you will find all purchase information, feel free to download.</span>

        <v-card class="card mt-6 pa-6">
          <div class="jspace divrow mb-1 acenter">
            <h5 class="acenter h5-mobile" :title="tokenId">
              <company-logo
                :energy-src="energies[tokenDetail?.assetInfo.deviceDetails.deviceType]"
                :country-src="countriesImg[tokenDetail?.assetInfo.specifications.country]"
                class="mr-4"
              ></company-logo>
              #{{ shortString(tokenId, {}) }}
            </h5>
            <div class="divrow astart acenter">
              <h5 class="mr-2 h5-mobile">
                {{ tokenPrice ?? 0 }} ICP
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[tokenDetail?.assetInfo.deviceDetails.deviceType]" :alt="`${tokenDetail?.assetInfo.deviceDetails.deviceType} icon`" style="width: 20px;">
              {{ tokenDetail?.assetInfo.deviceDetails.deviceType }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Region</span>
            <span>{{ tokenDetail?.assetInfo.specifications.region }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Start date</span>
            <span>{{ tokenDetail?.assetInfo.startDate.toDateString() }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">End date</span>
            <span>{{ tokenDetail?.assetInfo.endDate.toDateString() }}</span>
          </div>
        </v-card>

        <!-- TODO commented until api connection -->
        <!-- <div v-for="(item,index) in dataPdfCofirm" :key="index" class="border mb-4 mt-6 jspace">
          <div class="divrow acenter">
            <img src="@/assets/sources/icons/pdf.svg" alt="PDF">
            <div class="divcol ml-2">
              <span style="color: #475467; font-weight: 500;">{{ item.name }}</span>
              <span style="color: #475467;">{{ item.weight }}</span>
            </div>
          </div>

          <v-card class="card center" style="width: max-content!important;">
            <img src="@/assets/sources/icons/download.svg" alt="download icon" style="width: 22px">
          </v-card>
        </div> -->

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn flex-grow-1" @click="dialogRedeemCertificates = true; dialogPaymentConfirm = false" style="border: none!important;">Continue</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Dialog Redeem Certificates -->
    <v-dialog v-model="dialogRedeemCertificates" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogRedeemCertificates = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon" style="width: 22px">
          </v-sheet>
        </v-sheet>
        <h6>Do you want to redeem the cerfificates you just bought?</h6>
        <span class="tertiary">Obtain the redemption statement for your certificates right away by triggering the redemption flow: it’s a couple of clicks away.</span>
        <span class="tertiary bold mt-2 acenter">
          <img src="@/assets/sources/icons/info-circle.svg" alt="info-circle icon" class="mr-1" style="width: 23px">
          Learn more
        </span>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogRedeemCertificates = false">Not Now</v-btn>
          <v-btn class="btn" @click="modalApprove.model = true" style="border: none!important;">Yes, redeem</v-btn>
        </div>
      </v-card>
    </v-dialog>


    <!-- Dialog Filters -->
    <v-dialog v-model="dialogFilters" persistent width="100%" min-width="290" max-width="500">
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

        <v-text-field
          v-model="filters.companyName"
          variant="outlined"
          flat elevation="0"
          label="company name"
          class="select"
        ></v-text-field>

        <v-range-slider
          v-model="filters.priceRange"
          :min="0"
          :max="1000"
          :step="1"
          variant="solo"
          elevation="0"
          label="Price range"
          :thumb-label="filters.priceRange ? 'always' : false"
          class="align-center mt-3"
          hide-details
        ></v-range-slider>


        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogFilters = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogFilters = false; getMarketPlace()" style="border: none!important;">Apply</v-btn>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup>
import '@/assets/styles/pages/token-details.scss'
import ModalApprove from '@/components/modals/modal-approve.vue'
import countries from '@/assets/sources/json/countries-all.json'
import Apexchart from "vue3-apexcharts"

import HydroEnergyIcon from '@/assets/sources/energies/hydro.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar.svg'

import HydroEnergyColorIcon from '@/assets/sources/energies/hydro-color.svg'
import WindEnergyColorIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyColorIcon from '@/assets/sources/energies/solar-color.svg'

import ChileIcon from '@/assets/sources/icons/CL.svg'
import { AgentCanister } from '@/repository/agent-canister'
import { computed, onBeforeMount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import variables from '@/mixins/variables'
import moment from 'moment'
import { closeLoader, convertE8SToICP, showLoader, maxDecimals, shortPrincipalId, shortString } from '@/plugins/functions'
import { Principal } from '@dfinity/principal'

const
  route = useRoute(),
  router = useRouter(),
  toast = useToast(),
  { globalRules, ceroComisison } = variables,

energiesColored = {
  "Solar": SolarEnergyColorIcon,
  "Wind": WindEnergyColorIcon,
  "Hydro-Electric": HydroEnergyColorIcon,
  "Thermal": GeothermalEnergyIcon,
},
energies = {
  "Solar": SolarEnergyIcon,
  "Wind": WindEnergyIcon,
  "Hydro-Electric": HydroEnergyIcon,
  "Thermal": GeothermalEnergyIcon,
},
countriesImg = {
  CL: ChileIcon
},
tokenDetail = ref(undefined),
headers = [
  { title: 'Seller ID', key: 'seller', sortable: false },
  { title: 'Country', key: 'country', sortable: false },
  { title: 'Price', key: 'price', sortable: false },
  { title: 'MWh', key: 'mwh', sortable: false },
  { title: 'Actions', key: 'actions', sortable: false, align: 'center'},
],
dataMarketplace = ref([]),

loadingMarketplace = ref(true),
currentPage = ref(1),
itemsPerPage = ref(50),
totalPages = ref(1),
dialogTakeOffMarket = ref(false),
dialogPaymentConfirm = ref(false),
dialogChooseSeller = ref(false),
formChooseSeller = ref(),
dialogPurchaseReview = ref(false),
dialogRedeemCertificates = ref(false),
dialogParticipantBenefits = ref(false),
dialogSellingDetailsReview = ref(false),
dialogDynamicPrice = ref(false),
dialogFilters = ref(false),
itemsCurrency = ref(['USD', 'VES']),
selectedCurrency = ref('USD'),
dialogStaticPrice = ref(false),
formStaticPrice = ref(),
radioSell = ref(null),
dialogSellOptions = ref(false),
dialogRedeem = ref(false),
formRedeemRef = ref(),
dialogRedeemSure = ref(false),
dialogDetokenize = ref(false),
tabsSpecifications = ref(null),
dataPdfRedeem = [
  {
    name: 'Certificate',
    weight: '200 KB'
  }
],
dataPdfCofirm = [
  {
    name: 'Download receipt',
    weight: '200 KB'
  }
],
dataPdf =[
  {
    name: 'Receipt',
    weight: '148 KB',
  },
],
date = '24/04/23',
dialogAreYouSure = ref(false),
tokenBenefits = [
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

time_selection = 'Year',

seriesMintedVsProduced = ref([]),
chartOptions = {
  colors: ['#C6F221'],
  chart: {
    type: 'radialBar',
    offsetY: -20,
    sparkline: {
      enabled: true
    }
  },
  plotOptions: {
    radialBar: {
      startAngle: -90,
      endAngle: 90,
      track: {
        background: "#F2F4F7",
        rounded: true,
        opacity: 1.0,
        strokeWidth: '97%',
        margin: 5,
        dropShadow: {
          enabled: true,
          top: 2,
          left: 0,
          color: '#fff',
          opacity: 1,
          blur: 2
        },
        strokeLinecap: 'round',
      },
      dataLabels: {
        name: {
          show: true,
          color: '#475467',
          position: 'bottom',
          fontSize: '14px',
          offsetY: -35
        },
        value: {
          fontSize: '28px',
          color: 'black',
          fontWeight: '700',
          position: 'top',
          offsetY: -20
        }
      }
    }
  },
  grid: {
    padding: {
      top: 0,
      bottom: 30,
    }
  },
  fill: {
    type: 'solid',
  },
  labels: ['Minted'],
},
beneficiaries = ref(null),
periodStartMenu = ref(false),
periodEndMenu = ref(false),
locales = ref(["en", "es"]),

haveToken = ref(false),
haveTokenInMarket = ref(false),
amountSelected = ref(),
sellerSelected = ref(undefined),
tokenPrice = ref(null),
tokenAmount = ref(undefined),
formRedeem = ref({
  beneficiary: null,
  periodStart: null,
  periodEnd: null,
  locale: null,
}),

filters = ref({
  country: null,
  companyName: null,
  priceRange: null,
}),

previewSeller = ref(null),

modalApprove = ref(),
modalRequestRedeem = ref(),


tokenId = computed(() => route.query.tokenId),
prevRoutePatch  = computed(() => {
  try {
    const fullPath = router.options.history.state.back,
    path = fullPath.split('?')[0]

    return path.substring(1, path.length).split('-').join(' ')
  } catch (error) {
    router.replace('/')
  }
}),


amountInIcp = computed(() => dialogPurchaseReview.value ? Number(tokenPrice.value) * Number(tokenAmount.value) : 0),
feeInE8S = computed(() => dialogPurchaseReview.value ? 30_000 : 20_000)

// dialogs state management

// buy flow
watch(dialogChooseSeller, (value) => {
  if (dialogPurchaseReview.value) return
  if (!value) {
    sellerSelected.value = null
    tokenPrice.value = null
  }
})
watch(dialogPurchaseReview, (value) => {
  if (dialogPaymentConfirm.value) return
  if (!value) {
    sellerSelected.value = null
    tokenPrice.value = null
  }
})
watch(dialogPaymentConfirm, (value) => {
  if (!value) {
    sellerSelected.value = null
    tokenPrice.value = null
  }
})

// sell flow
watch(dialogStaticPrice, (value) => {
  if (dialogSellingDetailsReview.value) return
  if (!value) tokenPrice.value = null
})
watch(dialogSellingDetailsReview, (value) => {
  if (!value) tokenPrice.value = null
})

// redeem flow
watch(dialogRedeem, (value) => {
  if (!value) formRedeem.value.beneficiary = null
})


onBeforeMount(() => {
  getData()

  const input = route.query.input
  if (input) {
    router.replace({ path: '/token-details', query: { tokenId: tokenId.value } })

    switch (input) {
      case 'sell': dialogStaticPrice.value = true
        break;

      case 'redeem': dialogRedeemSure.value = true
        break;

      case 'takeOff': dialogTakeOffMarket.value = true
        break;
    }
  }
})


async function getData() {
  try {
    const [checkToken, checkTokenInMarket, token, statistics, _, __] = await Promise.allSettled([
      AgentCanister.checkUserToken(tokenId.value),
      AgentCanister.checkUserTokenInMarket(tokenId.value),
      AgentCanister.getTokenDetails(tokenId.value),
      AgentCanister.getAssetStatistics(tokenId.value),
      getMarketPlace(),
      getBeneficiaries()
    ])

    haveToken.value = checkToken.value
    haveTokenInMarket.value = checkTokenInMarket.value
    tokenDetail.value = token.value
    seriesMintedVsProduced.value = [(statistics.value.mwh || 1) / (token.value.assetInfo.volumeProduced || 1) * 100]
  } catch (error) {
    console.error(error);
    toast.error(error)
  }
}

async function getBeneficiaries() {
  try {
    beneficiaries.value = await AgentCanister.getBeneficiaries()
  } catch (error) {
    beneficiaries.value = []
    console.error(error);
  }
}

async function getMarketPlace() {
  loadingMarketplace.value = true

  try {
    // get getMarketplaceSellers
    const marketplace = await AgentCanister.getMarketplaceSellers({
      tokenId: tokenId.value,
      length: itemsPerPage.value,
      country: filters.value.country?.toLowerCase(),
      priceRange: filters.value.priceRange,
      page: currentPage.value,
      excludeCaller: true,
    }),
    list = []

    // build dataMarketplace
    for (const item of marketplace.data) {
      list.push({
        seller: item.sellerId,
        country: item.assetInfo.specifications.country,
        price: item.priceE8S,
        mwh: item.mwh,
      })
    }

    dataMarketplace.value = list.sort((a, b) => a.token_id - b.token_id)
    totalPages.value = marketplace.totalPages
  } catch (error) {
    console.error(error);
    toast.error(error)
  }

  loadingMarketplace.value = false
}

function selectSeller(item) {
  if (!amountSelected.value) return toast.warning('Must to choose a quanitty')

  dialogPurchaseReview.value = true
  dialogChooseSeller.value = false;

  sellerSelected.value = item.seller;
  tokenPrice.value = item.price;
}

function showDialog(input) {
  if (!amountSelected.value) return toast.warning('Must to choose a quanitty')

  switch (input) {
    case "sell": dialogStaticPrice.value = true
      break;
    case "buy": dialogChooseSeller.value = true
      break;
    case "takeOff": dialogTakeOffMarket.value = true
      break;
    case "redeem": dialogRedeemSure.value = true
      break;
  }
}

async function purchaseToken() {
  try {
    showLoader()
    const tx = await AgentCanister.purchaseToken(tokenId.value, sellerSelected.value, Number(tokenAmount.value))
    await getData()

    closeLoader()
    dialogPaymentConfirm.value = true
    dialogPurchaseReview.value = false;

    console.log("purchase token", tx);
    toast.success("Your purchase has been completed successfully")
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }
}

async function putOnSale() {
  try {
    showLoader()
    await AgentCanister.putOnSale(tokenId.value, Number(tokenAmount.value), Number(tokenPrice.value))
    await getData()

    closeLoader()
    dialogSellingDetailsReview.value = false;

    console.log("put on sale");
    toast.success(`You have put ${tokenAmount.value} tokens up for sale`)
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }
}

async function takeOffMarket() {
  try {
    showLoader()
    await AgentCanister.takeTokenOffMarket(tokenId.value, Number(tokenAmount.value))
    await getData()

    closeLoader()

    console.log("take off market");
    toast.success(`You have taken ${tokenAmount.value} from the market`)
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }
}

async function requestRedeemToken() {
  modalRequestRedeem.value.model = false
  showLoader()

  try {
    await AgentCanister.requestRedeemToken({
      tokenId: tokenId.value,
      amount: Number(tokenAmount.value),
      beneficiary: Principal.fromText(formRedeem.value.beneficiary),
      periodStart: formRedeem.value.periodStart,
      periodEnd: formRedeem.value.periodEnd,
      locale: formRedeem.value.locale,
    })
    closeLoader()
    dialogRedeem.value = false;
    dialogRedeemCertificates.value = false;

    toast.success(`you have send redemption request to beneficiary ${beneficiaries.value.find(e => e.principalId === formRedeem.value.beneficiary).companyName}`)
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }
}

async function redeemToken() {
  showLoader()

  try {
    const tx = await AgentCanister.redeemToken({
      tokenId: tokenId.value,
      amount: Number(tokenAmount.value),
      periodStart: formRedeem.value.periodStart,
      periodEnd: formRedeem.value.periodEnd,
      locale: formRedeem.value.locale,
    })

    await getData()

    closeLoader()
    dialogRedeem.value = false;
    dialogRedeemCertificates.value = false;

    console.log("redeem token", tx);
    toast.success(`you have redeemed ${tokenAmount.value} tokens`)
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }
}

async function getSellerProfile(value, uid) {
  if (!value) previewSeller.value = null

  try {
    previewSeller.value = await AgentCanister.getProfile(uid)
  } catch (error) {
    toast.error(error)
  }
}

function goDetails({ token_id: tokenId }, input) {
  const query = { tokenId }
  if (input) query.input = input

  router.push({ path: '/token-details', query })
}
</script>