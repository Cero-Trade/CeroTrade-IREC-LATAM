<!-- TODO redesign this page -->

<template>
  <modal-approve
    ref="modalApprove"
    :token-id="tokenId"
    :amount-in-e8s="numberToToken(totalPrice)"
    :fee-tx-in-e8s="feeInE8S"
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
    :content="`you agree to send a request to ${beneficiaries?.find(e => e.principalId === formRedeem.beneficiary)?.companyName ?? 'your beneficiary'} to redeem ${(formPreRedeem.amount ?? 0) > 1 ? 'tokens' : 'token'} in his name`"
    @accept="requestRedeemToken"
  />

  <div id="token-details">
    <aside class="d-flex flex-wrap mb-10" style="gap: 10px">
      <div class="flex-column mr-auto">
        <span class="mb-3 acenter" style="color: #475467; font-size: 16px; font-weight: 700;">
          <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
          <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
          <span class="text-first">{{ prevRoutePatch }}</span>
          <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
          <span style="color: #00555B;">Asset # {{ tokenId }}</span>
        </span>
        <h3 class="acenter mb-0" :title="tokenId" style="width: max-content">
          <company-logo
            :energy-src="energies[tokenDetail.assetInfo.deviceDetails?.deviceType]"
            :country-src="countries[tokenDetail.assetInfo.specifications?.country]?.flag"
            class="mr-4"
          ></company-logo>
          Asset # {{ shortString(tokenId, {}) }}
        </h3>
      </div>

      <div class="container-actions d-flex" style="gap: 10px">
        <v-btn class="btn2" @click="dialogTokenInfo = true">
          <img src="@/assets/sources/icons/info-circle-light.svg" alt="info-circle icon" style="width: 16px">
          Your token info
        </v-btn>

        <v-btn class="btn" @click="dialogTrade = true">
          <img src="@/assets/sources/icons/lightning.svg" alt="lightning icon" style="width: 16px">
          Trade
        </v-btn>
      </div>
    </aside>

    <section class="container-stats mb-16">
      <v-card v-for="(item, i) in stats" :key="i" class="card-styled">
        <h6 class="h6">{{ item.name }}</h6>
        <span class="great-text">{{ item.value }}</span>
      </v-card>
    </section>

    <v-tabs v-model="currentTab" class="custom-tabs mb-6" style="max-width: max-content;" hide-slider>
      <v-tab v-for="(item, i) in ['Market Insights', 'Asset Details', 'Device Details']" :key="i">
        {{ item }}
      </v-tab>
    </v-tabs>

    <v-window v-model="currentTab" class="container-tabs mb-11">
      <v-window-item :value="0">
        <section class="container-stats">
          <v-card v-for="(item, i) in marketInsights" :key="i" class="card-styled">
            <h6 class="h6">{{ item.name }}</h6>
            <span class="great-text">{{ item.value }}</span>
          </v-card>
        </section>
      </v-window-item>

      <v-window-item :value="1">
        <section class="d-flex flex-wrap" style="gap: 24px">
          <v-card class="card-styled-2 flex-grow-1">
            <aside
              v-for="(item, i) in assetDetails.slice(0, assetDetails.length / 2)" :key="i"
              :class="{ 'mb-6': i < (assetDetails.length / 2) - 1 }"
            >
              <label class="label">{{ item.name }}</label>
              <h6 class="h6 d-flex align-center mb-0" style="gap: 3px">
                <img :src="item.img" :alt="`${item.name} icon`">
                {{ item.value }}
              </h6>
            </aside>
          </v-card>

          <v-card class="card-styled-2 flex-grow-1">
            <aside
              v-for="(item, i) in assetDetails.slice(assetDetails.length / 2, assetDetails.length)" :key="i"
              :class="{ 'mb-6': i < (assetDetails.length / 2) - 1 }"
            >
              <label class="label">{{item.name}}</label>
              <h6 class="great-text d-flex align-center mb-0" style="gap: 3px">
                <img :src="item.img" :alt="`${item.name} icon`">
                {{ item.value }}
              </h6>
            </aside>
          </v-card>
        </section>
      </v-window-item>

      <v-window-item :value="2">
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
            </v-tabs>

            <hr style="border-bottom: 2px solid rgba(0,0,0,0.25)!important; width: 100%!important; position: relative; top: -2px;">
            <v-window v-model="tabsSpecifications">
              <v-window-item value="one">
                <h5 class="bold mb-6 mt-4">Device Details</h5>

                <v-row>
                  <v-col xl="8" lg="8" md="8" cols="12">
                    <div class="jspace divrow mt-3 mb-1">
                      <span style="color: #475467;">Name</span>
                      <span>{{ tokenDetail.assetInfo.deviceDetails?.name }}</span>
                    </div>

                    <div class="jspace divrow mb-1">
                      <span style="color: #475467;">Type</span>
                      <span>{{ tokenDetail.assetInfo.deviceDetails?.deviceType }}</span>
                    </div>

                    <div class="jspace divrow mt-3 mb-1">
                      <span style="color: #475467;">Device group</span>
                      <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                        <img :src="energiesColored[tokenDetail.assetInfo.deviceDetails?.deviceType]" :alt="`${tokenDetail.assetInfo.deviceDetails?.deviceType} icon`" style="width: 20px;">
                        {{ tokenDetail.assetInfo.deviceDetails?.deviceType }}
                      </span>
                    </div>

                    <div class="jspace divrow mt-3 mb-1" style="gap: 20px;">
                      <span style="color: #475467;">Description</span>
                      <span style="text-align: right; max-width: 60%;">{{ tokenDetail.assetInfo.deviceDetails?.description }}</span>
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
                      <span>{{ tokenDetail.assetInfo.specifications?.deviceCode }}</span>
                    </div>

                    <div class="jspace divrow mt-3 mb-1">
                      <span style="color: #475467;">Location</span>
                      <span>{{ tokenDetail.assetInfo.specifications?.location }}</span>
                    </div>

                    <div class="jspace divrow mt-3 mb-1">
                      <span style="color: #475467;">Latitude</span>
                      <span>{{ tokenDetail.assetInfo.specifications?.latitude }}</span>
                    </div>

                    <div class="jspace divrow mt-3 mb-1">
                      <span style="color: #475467;">Longitude</span>
                      <span>{{ tokenDetail.assetInfo.specifications?.longitude }}</span>
                    </div>

                    <div class="jspace divrow mt-3 mb-1">
                      <span style="color: #475467;">Country</span>
                      <div>
                        <img :src="countries[tokenDetail.assetInfo.specifications?.country].flag" :alt="`${tokenDetail.assetInfo.specifications?.country} flag`">
                        <span>{{ tokenDetail.assetInfo.specifications?.country }}</span>
                      </div>
                    </div>
                  </v-col>
                </v-row>
              </v-window-item>
            </v-window>
          </v-card>
        </v-col>
      </v-window-item>
    </v-window>

    <!-- <v-row>
      <v-col class="container-info">
        <v-row>
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
              <h5 class="bold" style="position: absolute; bottom: 0; left: 20px;">{{ tokenDetail.totalAmount }} MWh</h5>
            </v-card>

            <v-card class="card divcol jspace absolute-card-portfolio">
              <span>Amount for sale</span>
              <h5 class="bold" style="position: absolute; bottom: 0; left: 20px;">{{ tokenDetail.inMarket }} MWh</h5>
            </v-card>
          </v-col>
        </v-row>
      </v-col>

      <v-col clasS="container-actions" xl="4" lg="4" md="4" cols="12">
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
          </v-form>
        </v-col>
      </v-col>
    </v-row> -->


    <!-- TODO saved to use later -->
    <!-- <aside class="container-redemptions">
      <v-card v-for="(item, i) in redemptions" :key="i" class="card divcol pt-6">
        <span style="color: #475467;">Redemption amount (MWh)</span>
        <span class="mt-2 mb-4" style="color: #475467;">
          <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon" style="width: 15px">
          {{ item.tokenAmount }}
        </span>

        <span style="color: #475467;">Redemption Date</span>
        <span class="mt-2 mb-4">{{ moment(item.date).format('YYYY/MM/DD') }}</span>

        <div class="border mb-2 jspace">
          <div class="divrow acenter">
            <img src="@/assets/sources/icons/pdf.svg" alt="PDF">
            <div class="divcol ml-2">
              <span style="color: #475467; font-weight: 500;">{{ item.redemptionPdf.name }}</span>
              <span style="color: #475467;">{{ formatBytes(item.redemptionPdf.size) }}</span>
            </div>
          </div>

          <v-card :href="item.url" :download="item.redemptionPdf.name" class="card center" style="width: max-content!important; border-radius: 10px!important;">
            <img src="@/assets/sources/icons/download.svg" alt="download icon" style="width: 18px">
          </v-card>
        </div>
      </v-card>
    </aside> -->

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
        <template #[`item.seller`]="{ item, index }">
          <div class="pointer d-flex align-center" @click="getSellerProfile(item.seller, index)">
            <v-sheet class="double-sheet">
              <v-sheet>
                <v-progress-circular
                  v-if="!item.sellerLogo"
                  :indeterminate="item.loading"
                ></v-progress-circular>
                <v-img-load
                  v-else
                  :src="item.sellerLogo"
                  :alt="`${item.sellerName} logo`"
                  cover
                  sizes="25px"
                  rounded="50%"
                  class="flex-grow-0"
                />
              </v-sheet>
            </v-sheet>
            <span class="bold">{{ item.sellerName }}</span>
          </div>
        </template>

        <template #[`item.price`]="{ item }">
          <span class="divrow jspace acenter">
            {{ item.price }} <v-sheet class="chip-currency bold">{{ item.currency }}</v-sheet>
          </span>
        </template>

        <template #[`item.country`]="{ item }">
          <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
            <img :src="countries[item.country].flag" :alt="`${item.country} Icon`" style="width: 20px;">
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
            <span class="text-capitalize" style="color: #475467;">{{ item.sellerName }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span>Price</span>
            <span style="color: #475467;">{{ item.currency }} {{ item.price }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span>Country</span>
            <span style="color: #475467;" class="acenter text-capitalize">
              <img :src="countries[item.country].flag" alt="icon" class="mr-1" style="width: 20px;"> {{ item.country }}
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
                :energy-src="energies[tokenDetail.assetInfo.deviceDetails?.deviceType]"
                :country-src="countries[tokenDetail.assetInfo.specifications?.country].flag"
                class="mr-4"
              ></company-logo>
              #{{ shortString(tokenId, {}) }}
            </h5>
          </div>
          
          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[tokenDetail.assetInfo.deviceDetails?.deviceType]" :alt="`${tokenDetail.assetInfo.deviceDetails?.deviceType} icon`" style="width: 20px;">
              {{ tokenDetail.assetInfo.deviceDetails?.deviceType }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Country</span>
            <span class="flex-center" style="gap: 5px">
              <img :src="countries[tokenDetail.assetInfo.specifications?.country].flag" :alt="`${tokenDetail.assetInfo.specifications?.country} flag`">
              {{ tokenDetail.assetInfo.specifications?.country }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Amount</span>
            <span>{{ formTakeOffMarket.amount }} MWh</span>
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
                    return true
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
                    return true
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
            >
              <template #selection="{ item }">
                <v-img-load
                  :src="item.raw.companyLogo"
                  :alt="`${item.raw.companyName} logo`"
                  cover
                  sizes="25px"
                  rounded="50%"
                  class="flex-grow-0"
                />
                <span class="bold ml-2 ellipsis-text">{{ item.raw.name }}</span>
              </template>

              <template #item="{ item, props }">
                <v-list-item v-bind="props" title=" ">
                  <div class="d-flex align-center">
                    <v-img-load
                      :src="item.raw.companyLogo"
                      :alt="`${item.raw.companyName} logo`"
                      cover
                      sizes="25px"
                      rounded="50%"
                      class="flex-grow-0"
                    />
                    <span class="bold ml-2" style="translate: 0 1px">{{ item.raw.companyName }}</span>
                  </div>
                </v-list-item>
              </template>
            </v-select>
          </div>

          <!-- <v-btn class="btn2" style="width: max-content !important">Add beneficiary</v-btn> -->

          <v-card class="card cards-rec pa-6">
            <span class="bold mt-3">Checkout review</span>

            <v-divider class="mb-3 mt-4"  thickness="2" style="width: 150%; position: relative; left: -50px;"></v-divider>
            
            <div class="jspace divrow mb-2 acenter">
              <h5 class="acenter h5-mobile" :title="tokenId">
                <company-logo
                  :energy-src="energies[tokenDetail.assetInfo.deviceDetails?.deviceType]"
                  :country-src="countries[tokenDetail.assetInfo.specifications?.country].flag"
                  class="mr-4"
                ></company-logo>
                #{{ shortString(tokenId, {}) }}
              </h5>
            </div>

            <div class="jspace divrow mb-1">
              <span style="color: #475467;">Energy source type</span>
              <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                <img :src="energiesColored[tokenDetail.assetInfo.deviceDetails?.deviceType]" :alt="`${tokenDetail.assetInfo.deviceDetails?.deviceType} icon`" style="width: 20px;">
                {{ tokenDetail.assetInfo.deviceDetails?.deviceType }}
              </span>
            </div>

            <div class="jspace divrow mb-1">
              <span style="color: #475467;">Country</span>
              <span class="flex-center" style="gap: 5px">
                <img :src="countries[tokenDetail.assetInfo.specifications?.country].flag" :alt="`${tokenDetail.assetInfo.specifications?.country} flag`">
                {{ tokenDetail.assetInfo.country }}
              </span>
            </div>

            <div class="jspace divrow mb-1">
              <span style="color: #475467;">Amount</span>
              <span>{{ formPreRedeem.amount }} MWh</span>
            </div>

            <v-divider class="mb-3 mt-4"  thickness="2" style="width: 100%;"></v-divider>

            <div class="jspace divrow mt-1">
              <span>Transaction fee</span>
              <span>{{ tokenToNumber(feeInE8S) }} ICP</span>
            </div>
            <div class="jspace divrow mt-1">
              <span>Cero trade comission</span>
              <span>{{ tokenToNumber(ceroComisison) }} ICP</span>
            </div>
            <div class="jspace divrow mt-1">
              <span class="bold">Total</span>
              <span class="bold">{{ maxDecimals(totalPrice + tokenToNumber(feeInE8S) + tokenToNumber(ceroComisison)) }} ICP</span>
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
                :energy-src="energies[tokenDetail.assetInfo.deviceDetails?.deviceType]"
                :country-src="countries[tokenDetail.assetInfo.specifications?.country].flag"
                class="mr-4"
              ></company-logo>
              #{{ shortString(tokenId, {}) }}
            </h5>
            <div class="divrow mb-0 astart acenter">
              <h5 class="mb-0 mr-2 h5-mobile">
                {{ formSell.price ?? 0 }} ICP
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>          
          </div>


          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[tokenDetail.assetInfo.deviceDetails?.deviceType]" :alt="`${tokenDetail.assetInfo.deviceDetails?.deviceType} icon`" style="width: 20px;">
              {{ tokenDetail.assetInfo.deviceDetails?.deviceType }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Country</span>
            <span class="flex-center" style="gap: 5px">
              <img :src="countries[tokenDetail.assetInfo.specifications?.country].flag" :alt="`${tokenDetail.assetInfo.country} flag`">
              {{ tokenDetail.assetInfo.country }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Amount</span>
            <span>{{ formSell.amount }} MWh</span>
          </div>
        </v-card>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogSellingDetailsReview = false">Cancel</v-btn>
          <v-btn class="btn" @click="putOnSale()" style="border: none!important;">Put on the market</v-btn>
        </div>
      </v-card>
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
                :energy-src="energies[tokenDetail.assetInfo.deviceDetails?.deviceType]"
                :country-src="countries[tokenDetail.assetInfo.specifications?.country].flag"
                class="mr-4"
              ></company-logo>
              #{{ shortString(tokenId, {}) }}
            </h5>
            <div class="divrow astart acenter">
              <h5 class="mr-2 h5-mobile">
                {{ formBuy.price ?? 0 }} ICP
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[tokenDetail.assetInfo.deviceDetails?.deviceType]" :alt="`${tokenDetail.assetInfo.deviceDetails?.deviceType} icon`" style="width: 20px;">
              {{ tokenDetail.assetInfo.deviceDetails?.deviceType }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Region</span>
            <span>{{ tokenDetail.assetInfo.specifications?.region }}</span>
          </div>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 100%;"></v-divider>

          <div class="jspace divrow mt-1">
            <span>Transaction fee</span>
            <span>{{ tokenToNumber(feeInE8S) }} ICP</span>
          </div>
          <div class="jspace divrow mt-1">
            <span>Cero trade comission</span>
            <span>{{ tokenToNumber(ceroComisison) }} ICP</span>
          </div>
          <div class="jspace divrow mt-1">
            <span class="bold">Total</span>
            <span class="bold">{{ maxDecimals(totalPrice + tokenToNumber(feeInE8S) + tokenToNumber(ceroComisison)) }} ICP</span>
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
                :energy-src="energies[tokenDetail.assetInfo.deviceDetails?.deviceType]"
                :country-src="countries[tokenDetail.assetInfo.specifications?.country].flag"
                class="mr-4"
              ></company-logo>
              #{{ shortString(tokenId, {}) }}
            </h5>
            <div class="divrow astart acenter">
              <h5 class="mr-2 h5-mobile">
                {{ previousBuyAmount ?? 0 }} ICP
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[tokenDetail.assetInfo.deviceDetails?.deviceType]" :alt="`${tokenDetail.assetInfo.deviceDetails?.deviceType} icon`" style="width: 20px;">
              {{ tokenDetail.assetInfo.deviceDetails?.deviceType }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Region</span>
            <span>{{ tokenDetail.assetInfo.specifications?.region }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Start date</span>
            <span>{{ tokenDetail.assetInfo.startDate?.toDateString() }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">End date</span>
            <span>{{ tokenDetail.assetInfo.endDate?.toDateString() }}</span>
          </div>
        </v-card>

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
          <v-btn
            class="btn"
            @click="dialogRedeemCertificates = false;  dialogRedeem = true" style="border: none!important;">Yes, redeem</v-btn>
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
          :items="Object.values(countries)"
          variant="outlined"
          flat elevation="0"
          menu-icon=""
          item-title="name"
          item-value="name"
          label="country"
          class="select mb-4"
        >
          <template #append-inner="{ isFocused }">
            <img
              src="@/assets/sources/icons/chevron-down.svg"
              alt="chevron-down icon"
              :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
            >
          </template>

          <template #selection="{ item }">
            <v-img-load
              :src="item.raw.flag.toString()"
              :alt="`${item.raw.name} logo`"
              cover
              sizes="25px"
              rounded="50%"
              class="flex-grow-0"
            />
            <span class="bold ml-2 ellipsis-text">{{ item.raw.name }}</span>
          </template>

          <template #item="{ item, props }">
            <v-list-item v-bind="props" title=" ">
              <div class="d-flex align-center">
                <v-img-load
                  :src="item.raw.flag.toString()"
                  :alt="`${item.raw.name} logo`"
                  cover
                  sizes="25px"
                  rounded="50%"
                  class="flex-grow-0"
                />
                <span class="bold ml-2" style="translate: 0 1px">{{ item.raw.name }}</span>
              </div>
            </v-list-item>
          </template>
        </v-autocomplete>

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


    <!-- dialogTokenInfo -->
    <v-dialog v-model="dialogTokenInfo" width="100%" min-width="290" max-width="434">
      <v-card class="card dialog-card-detokenize d-flex flex-column" style="min-width: 100% !important">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogTokenInfo = false">

        <span class="great-text mb-6">Your token information</span>

        <h5 class="mb-2">Currently for sale by you</h5>
        <span class="great-text mb-6">{{ tokenDetail.inMarket }} MWh</span>

        <h5 class="mb-2">Owned by you</h5>
        <span class="great-text mb-6">{{ tokenDetail.totalAmount }} MWh</span>

        <h5 class="mb-2">Redeemed by you</h5>
        <span class="great-text mb-6">{{ redeemedByUser }} MWh</span>

        <v-btn
          class="btn"
          style="background-color: #fff !important; width: 100% !important"
          to="/profile"
        >Check out my redemption history</v-btn>
      </v-card>
    </v-dialog>

    <!-- dialogTrade -->
    <v-dialog v-model="dialogTrade" persistent width="100%" min-width="290" max-width="500">
      <v-card class="card dialog-card-detokenize d-flex flex-column" style="min-width: 100% !important">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogTrade = false">

        <h3 class="h3">Trade Asset #{{ tokenId }}</h3>

        <v-tabs v-model="tradeTab" class="custom-tabs mb-3" hide-slider>
          <v-tab v-for="(item, i) in ['Buy', 'Market', 'Redeem']" :key="i" :style="tradeTab !== i ? 'border: none !important' : null">
            {{ item }}
          </v-tab>
        </v-tabs>

        <v-window v-model="tradeTab">
          <v-window-item :value="0">
            <v-form ref="formBuyRef" @submit.prevent>
              <v-card class="card-styled-2" height="550" style="overflow: auto">
                <span class="great-text">Buy Tokens</span>
                <h6 class="h6 mb-6">Select a seller and specify the quantity to buy.</h6>

                <label class="label mb-2">Filter by Country</label>
                <v-autocomplete
                  v-model="filters.country"
                  :items="Object.values(countries)"
                  menu-icon=""
                  item-title="name"
                  item-value="name"
                  label="country"
                  variant="outlined"
                  flat elevation="0"
                  class="select mb-4"
                >
                  <template #append-inner="{ isFocused }">
                    <img
                      src="@/assets/sources/icons/chevron-down.svg"
                      alt="chevron-down icon"
                      :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
                    >
                  </template>

                  <template #selection="{ item }">
                    <v-img-load
                      :src="item.raw.flag.toString()"
                      :alt="`${item.raw.name} logo`"
                      cover
                      sizes="25px"
                      rounded="50%"
                      class="flex-grow-0"
                    />
                    <span class="bold ml-2 ellipsis-text">{{ item.raw.name }}</span>
                  </template>

                  <template #item="{ item, props }">
                    <v-list-item v-bind="props" title=" ">
                      <div class="d-flex align-center">
                        <v-img-load
                          :src="item.raw.flag.toString()"
                          :alt="`${item.raw.name} logo`"
                          cover
                          sizes="25px"
                          rounded="50%"
                          class="flex-grow-0"
                        />
                        <span class="bold ml-2" style="translate: 0 1px">{{ item.raw.name }}</span>
                      </div>
                    </v-list-item>
                  </template>
                </v-autocomplete>

                <label class="label mb-2">Price Range (ICP)</label>
                <v-range-slider
                  v-model="filters.priceRange"
                  :min="0"
                  :max="1000"
                  :step="1"
                  :thumb-label="filters.priceRange ? 'always' : false"
                  class="select align-center mb-4 mt-3"
                  variant="outlined"
                  flat elevation="0"
                  hide-details
                ></v-range-slider>

                <label class="label mb-2">Select Seller</label>
                <v-select
                  v-model="formBuy.sellerId"
                  variant="outlined"
                  :items="dataMarketplace"
                  item-title="sellerName"
                  item-value="seller"
                  flat elevation="0"
                  class="select mb-6"
                  :rules="[globalRules.required]"
                  @update:model-value="(value) => selectSeller(dataMarketplace.find(e => e.seller == value))"
                ></v-select>

                <label class="label mb-2">Quantity to Buy (MWh)</label>
                <v-text-field
                  v-model="formBuy.amount"
                  type="number"
                  variant="outlined"
                  flat elevation="0"
                  :rules="[globalRules.requiredNumber]"
                  class="select hide-spin mb-7"
                ></v-text-field>

                <v-btn
                  class="btn bg-black"
                  style="--c: white; width: 100% !important; max-width: 130px !important"
                  @click="showDialog('buy')"
                >Buy</v-btn>
              </v-card>
            </v-form>
          </v-window-item>

          <v-window-item :value="1">
            <v-card class="card-styled-2" height="550" style="overflow: auto">
              <span class="great-text">Manage Market Tokens</span>
              <h6 class="h6 mb-6">Put tokens in the market or remove them.</h6>

              <v-form ref="formSellRef">
                <label class="label mb-2">Quantity to Put in Market (MWh)</label>
                <v-text-field
                  v-model="formSell.amount"
                  type="number"
                  variant="outlined"
                  flat elevation="0"
                  :rules="[globalRules.requiredNumber]"
                  class="select hide-spin mb-6"
                ></v-text-field>

                <label class="label mb-2">Price per MWh (ICP)</label>
                <v-text-field
                  v-model="formSell.price"
                  variant="outlined"
                  flat elevation="0"
                  :rules="[globalRules.requiredNumber]"
                  class="select mb-7"
                ></v-text-field>

                <v-btn
                  v-if="haveToken"
                  class="btn bg-black mb-4"
                  style="--c: white; width: 100% !important; max-width: 130px !important"
                  @click="showDialog('sell')"
                >Put in Market</v-btn>
              </v-form>

              <h6 class="h6 mb-4">Tokens in Market {{ tokenDetail.inMarket }} MWh</h6>
              <h6 class="h6 mb-4">Tokens Available to Put in Market: {{ tokenDetail.totalAmount }} MWh</h6>

              <label class="label mb-4">Your Market Listings</label>

              <h6 v-if="!haveTokenInMarket" class="h6 mb-0">You don't have any tokens in the market.</h6>

              <v-form v-else ref="formTakeOffMarketRef">
                <v-text-field
                  v-model="formTakeOffMarket.amount"
                  type="number"
                  variant="outlined"
                  flat elevation="0"
                  :rules="[globalRules.requiredNumber]"
                  class="select hide-spin mb-7"
                ></v-text-field>

                <v-btn
                  class="btn bg-black mt-4"
                  style="--c: white; width: 100% !important; max-width: 130px !important"
                  @click="showDialog('takeOff')"
                >Take off market</v-btn>
              </v-form>
            </v-card>
          </v-window-item>

          <v-window-item :value="2">
            <v-form ref="formPreRedeemRef" @submit.prevent>
              <v-card class="card-styled-2" height="550" style="overflow: auto">
                <span class="great-text">Redeem Tokens</span>
                <h6 class="h6 mb-6">Redeem your tokens at the current platform rate.</h6>

                <label class="label mb-2">Quantity to Redeem (MWh)</label>
                <v-text-field
                  v-model="formPreRedeem.amount"
                  type="number"
                  variant="outlined"
                  flat elevation="0"
                  :rules="[globalRules.requiredNumber]"
                  class="select hide-spin mb-7"
                ></v-text-field>
                <h6 class="h6 mb-4">Platform Redemption Rate: {{ stats.find(e => e.id === 'redemption')?.value ?? 0 }}</h6>
                <h6 class="h6 mb-6">Tokens Available to Redeem: {{ tokenDetail.totalAmount }} Mwh</h6>

                <v-btn
                  v-if="haveToken"
                  :loading="!beneficiaries"
                  class="btn bg-black"
                  style="--c: white; width: 100% !important; max-width: 130px !important"
                  @click="showDialog('redeem')"
                >Redeem Tokens</v-btn>
              </v-card>
            </v-form>
          </v-window-item>
        </v-window>
      </v-card>
    </v-dialog>
  </div>
</template>

<script setup>
import '@/assets/styles/pages/token-details.scss'
import ModalApprove from '@/components/modals/modal-approve.vue'
// import Apexchart from "vue3-apexcharts"

import HydroEnergyIcon from '@/assets/sources/energies/hydro.svg'
import OceanEnergyIcon from '@/assets/sources/energies/ocean.svg'
import GeothermalEnergyIcon from '@/assets/sources/energies/geothermal.svg'
import BiomeEnergyIcon from '@/assets/sources/energies/biome.svg'
import WindEnergyIcon from '@/assets/sources/energies/wind.svg'
import SolarEnergyIcon from '@/assets/sources/energies/solar.svg'

import HydroEnergyColorIcon from '@/assets/sources/energies/hydro-color.svg'
import WindEnergyColorIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyColorIcon from '@/assets/sources/energies/solar-color.svg'

import calendarIcon from '@/assets/sources/icons/calendar.svg'
import co2EmisionIcon from '@/assets/sources/icons/co2-emision.svg'
import radioactivityEmissionIcon from '@/assets/sources/icons/radioactivity-emision.svg'
import volumeProducedIcon from '@/assets/sources/icons/volume-produced.svg'

import { AgentCanister } from '@/repository/agent-canister'
import { computed, onBeforeMount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'vue-toastification'
import variables from '@/mixins/variables'
import moment from 'moment'
import { closeLoader, tokenToNumber, numberToToken, showLoader, maxDecimals, shortString, formatBytes } from '@/plugins/functions'

const
  route = useRoute(),
  router = useRouter(),
  toast = useToast(),
  { globalRules, ceroComisison, countries, dateFormat, defaultMaxDecimals } = variables,

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
stats = ref([]),
currentTab = ref(0),
marketInsights = ref([]),
assetDetails = ref([]),
tabsSpecifications = ref(null),

tokenDetail = ref({
  tokenId: null,
  inMarket: null,
  totalAmount: null,
  assetInfo: {
    co2Emission: null,
    specifications: {
      latitude: null,
      country: null,
      longitude: null,
      deviceCode: null,
      location: null
    },
    deviceDetails: {
      name: null,
      description: null,
      deviceType: null
    },
    tokenId: null,
    endDate: null,
    volumeProduced: null,
    radioactivityEmission: null,
    startDate: null
  }
}),

headers = [
  { title: 'Seller', key: 'seller', sortable: false },
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
dialogPurchaseReview = ref(false),
dialogRedeemCertificates = ref(false),
dialogSellingDetailsReview = ref(false),
dialogFilters = ref(false),
dialogRedeem = ref(false),
dialogRedeemSure = ref(false),
dialogTokenInfo = ref(false),
dialogTrade = ref(false),

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

redemptions = ref([]),

filters = ref({
  country: null,
  companyName: null,
  priceRange: null,
}),
tradeTab = ref(0),

beneficiaries = ref(null),
periodStartMenu = ref(false),
periodEndMenu = ref(false),
locales = ref(["en", "es"]),

haveToken = ref(false),
haveTokenInMarket = ref(false),

previousBuyAmount = ref(),
formBuyRef = ref(),
formBuy = ref({
  amount: null,
  price: null,
  sellerId: null
}),

formSellRef = ref(),
formSell = ref({
  amount: null,
  price: null
}),

formTakeOffMarketRef = ref(),
formTakeOffMarket = ref({ amount: null }),

formPreRedeemRef = ref(),
formPreRedeem = ref({ amount: null }),

formRedeemRef = ref(),
formRedeem = ref({
  beneficiary: null,
  periodStart: null,
  periodEnd: null,
  locale: null,
}),

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


redeemedByUser = computed(() => redemptions.value.reduce((a, b) => a + b.tokenAmount, 0)),
totalPrice = computed(() => dialogPurchaseReview.value ? Number(formBuy.value.price) * Number(formBuy.value.amount) : 0),
feeInE8S = computed(() => dialogPurchaseReview.value ? 30_000n : 20_000n)

// dialogs state management

// redeem flow
watch(dialogRedeem, (value) => {
  if (!value) {
    formRedeem.value.beneficiary = null
    formRedeem.value.locale = null
    formRedeem.value.periodStart = null
    formRedeem.value.periodEnd = null
  }
})


onBeforeMount(() => {
  getData()

  const input = route.query.input
  if (input) {
    router.replace({ path: '/token-details', query: { tokenId: tokenId.value } })

    switch (input) {
      case 'sell': dialogSellingDetailsReview.value = true
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
    const [singlePortfolio, statistics, _, __] = await Promise.allSettled([
      AgentCanister.getSinglePortfolio(tokenId.value),
      AgentCanister.getAssetStatistics(tokenId.value),
      getMarketPlace(),
      getBeneficiaries()
    ])

    haveToken.value = singlePortfolio.value.tokenInfo.totalAmount > 0
    haveTokenInMarket.value = singlePortfolio.value.tokenInfo.inMarket > 0
    tokenDetail.value = singlePortfolio.value.tokenInfo
    redemptions.value = singlePortfolio.value.redemptions
    seriesMintedVsProduced.value = [
      singlePortfolio.value.tokenInfo.assetInfo.volumeProduced > 0
        ? (statistics.value.mwh || 1) / (singlePortfolio.value.tokenInfo.assetInfo.volumeProduced * 100)
        : 0
    ]

    const totalInMarketplace = dataMarketplace.value.reduce((a, b) => a + b.mwh, 0) + tokenDetail.value.inMarket,
    platformRate = statistics.value.redemptions > 0 ? (statistics.value.mwh || 1) / (statistics.value.redemptions * 100) : 0;


    stats.value = [
      {
        id: 'produced',
        name: 'Total produced',
        value: `${tokenDetail.value.assetInfo.volumeProduced} MWh`,
      },
      {
        id: 'market',
        name: 'Total In Market',
        value: `${totalInMarketplace} MWh`,
      },
      {
        id: 'redemption',
        name: 'Platform Redemption Rate',
        value: `${platformRate}%`,
      },
    ]
    marketInsights.value = [
      {
        name: 'Hosted on platform',
        value: `${statistics.value.mwh} MWh`,
      },
      {
        name: 'Sold on platform',
        value: `${statistics.value.sells} MWh`,
      },
      {
        name: 'Redeemed on platform',
        value: `${statistics.value.redemptions} MWh`,
      },
      {
        name: 'Average price trend',
        value: `${statistics.value.priceE8STrend} ICP`,
      },
    ]
    assetDetails.value = [
      {
        name: 'Type',
        img: energiesColored[tokenDetail.value.assetInfo.deviceDetails?.deviceType],
        value: 'Hydroenergy',
      },
      {
        name: 'Start date of production',
        img: calendarIcon,
        value: tokenDetail.value.assetInfo.startDate?.toDateString(),
      },
      {
        name: 'End date of production',
        img: calendarIcon,
        value: tokenDetail.value.assetInfo.endDate?.toDateString(),
      },
      {
        name: 'CO2 Emission',
        img: co2EmisionIcon,
        value: `${tokenDetail.value.assetInfo.co2Emission}%`,
      },
      {
        name: 'Radioactivity emission',
        img: radioactivityEmissionIcon,
        value: `${tokenDetail.value.assetInfo.radioactivityEmission}%`,
      },
      {
        name: 'Volume produced',
        img: volumeProducedIcon,
        value: `${tokenDetail.value.assetInfo.volumeProduced} MWh`,
      },
    ]
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
    toast.error(error)
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
        sellerName: item.sellerName,
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
  if (!dialogTrade.value) {
    tradeTab.value = 0
    dialogTrade.value = true
  }

  formBuy.value.sellerId = item.seller;
  formBuy.value.price = item.price;
}

function clearForms() {
  formBuy.value.amount = null
  formBuy.value.price = null
  formBuy.value.sellerId = null

  formSell.value.amount = null
  formSell.value.price = null

  formTakeOffMarket.value.amount = null

  formPreRedeem.value.amount = null
}

async function showDialog(input) {
  switch (input) {
    case "sell": {
      if (!(await formSellRef.value.validate()).valid) return

      dialogSellingDetailsReview.value = true
    } break;

    case "buy": {
      if (!(await formBuyRef.value.validate()).valid) return

      dialogPurchaseReview.value = true
    } break;

    case "takeOff": {
      if (!(await formTakeOffMarketRef.value.validate()).valid) return

      dialogTakeOffMarket.value = true
    } break;

    case "redeem": {
      if (!(await formPreRedeemRef.value.validate()).valid) return

      dialogRedeemSure.value = true
    } break;
  }
}

async function purchaseToken() {
  dialogTrade.value = false
  showLoader()

  try {
    const tx = await AgentCanister.purchaseToken(tokenId.value, formBuy.value.sellerId, Number(formBuy.value.amount))
    previousBuyAmount.value = formBuy.value.amount

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

  clearForms()
}

async function putOnSale() {
  dialogTrade.value = false
  showLoader()

  try {
    await AgentCanister.putOnSale(tokenId.value, Number(formSell.value.amount), Number(formSell.value.price))
    await getData()

    closeLoader()
    dialogSellingDetailsReview.value = false;

    console.log("put on sale");
    toast.success(`You have put ${formSell.value.amount} tokens up for sale`)
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }

  clearForms()
}

async function takeOffMarket() {
  dialogTrade.value = false
  showLoader()

  try {
    await AgentCanister.takeTokenOffMarket(tokenId.value, Number(formTakeOffMarket.value.amount))
    await getData()

    closeLoader()

    console.log("take off market");
    toast.success(`You have taken ${formTakeOffMarket.value.amount} from the market`)
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }

  clearForms()
}

async function requestRedeemToken() {
  dialogTrade.value = false
  modalRequestRedeem.value.model = false
  showLoader()

  try {
    await AgentCanister.requestRedeemToken({
      items: [{
        id: tokenId.value,
        volume: Number(previousBuyAmount.value ?? formPreRedeem.value.amount),
      }],
      beneficiary: formRedeem.value.beneficiary,
      periodStart: formRedeem.value.periodStart,
      periodEnd: formRedeem.value.periodEnd,
      locale: formRedeem.value.locale,
    })
    previousBuyAmount.value = null

    closeLoader()
    dialogRedeem.value = false;
    dialogRedeemCertificates.value = false;

    toast.success(`you have send redemption request to beneficiary ${beneficiaries.value.find(e => e.principalId === formRedeem.value.beneficiary).companyName}`)
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }

  clearForms()
}

async function redeemToken() {
  dialogTrade.value = false
  showLoader()

  try {
    const tx = await AgentCanister.redeemToken({
      items: [{
        id: tokenId.value,
        volume: Number(previousBuyAmount.value ?? formPreRedeem.value.amount),
      }],
      periodStart: formRedeem.value.periodStart,
      periodEnd: formRedeem.value.periodEnd,
      locale: formRedeem.value.locale,
    })
    previousBuyAmount.value = null

    await getData()

    closeLoader()
    dialogRedeem.value = false;
    dialogRedeemCertificates.value = false;

    console.log("redeem token", tx);
    toast.success(`you have redeemed ${formPreRedeem.value.amount} tokens`)
  } catch (error) {
    closeLoader()
    console.error(error);
    toast.error(error)
  }

  clearForms()
}

async function getSellerProfile(uid, index) {
  if (dataMarketplace.value[index].loading || dataMarketplace.value[index].sellerLogo) return;
  dataMarketplace.value[index].loading = true

  try {
    const profile = await AgentCanister.getProfile(uid)
    dataMarketplace.value[index].sellerLogo = profile.companyLogo
  } catch (error) {
    toast.error(error)
  }

  dataMarketplace.value[index].loading = false
}

function goDetails({ token_id: tokenId }, input) {
  const query = { tokenId }
  if (input) query.input = input

  router.push({ path: '/token-details', query })
}
</script>