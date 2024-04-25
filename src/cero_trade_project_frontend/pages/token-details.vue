<template>
  <div id="token-details">
    <span class="mb-10 acenter" style="color: #475467; font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span class="text-first">{{ prevRoutePatch }}</span>
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span style="color: #00555B;">IREC #{{ tokenId }}</span>
    </span>
    <h3 class="acenter mb-4">
      <company-logo
        :src="tokenDetail?.companyLogo"
        :country-src="countries[tokenDetail?.assetInfo.specifications.country]"
        :energy-src="energies[tokenDetail?.assetInfo.assetType]"
        class="mr-4"
      ></company-logo>
      IREC #{{ tokenId }}
    </h3>

    <v-row>
      <v-col xl="8" lg="8" md="8" cols="12">
        <v-row>
          <v-col xl="5" lg="5" cols="12">
            <v-card class="card cards-rec">
              <div class="jspace divrow mb-1">
                <span style="color: #475467;">Type</span>
                <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                  <img :src="energiesColored[tokenDetail?.assetInfo.assetType]" :alt="`${tokenDetail?.assetInfo.assetType} icon`" style="width: 20px;">
                  {{ tokenDetail?.assetInfo.assetType }} energy
                </span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">Start date of production</span>
                <span>{{ tokenDetail?.assetInfo.startDate }}</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">End date of production</span>
                <span>{{ tokenDetail?.assetInfo.endDate }}</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">CO2 Emission</span>
                <span>{{ tokenDetail?.assetInfo.co2Emission }}%</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">Radioactivity emission</span>
                <span>{{ tokenDetail?.assetInfo.radioactivityEmnission }}%</span>
              </div>
            </v-card>
          </v-col>

          <v-col xl="4" lg="4" cols="12">
            <v-card class="card relative" style="min-height: 100%!important;">
              <!-- TODO ask about this -->
              <span>Total available</span>
              <div id="chart">
                <apexchart type="radialBar" :options="chartOptions" :series="series"></apexchart>
              </div>
            </v-card>
          </v-col>

          <v-col xl="3" lg="3" cols="12">
            <v-card class="card divcol jspace absolute-card-portfolio mb-2">
              <span>Total amount owned</span>
              <h5 class="bold" style="position: absolute; bottom: 0; left: 20px;">{{ tokenDetail?.totalAmount }} MWh</h5>
            </v-card>

            <v-card class="card divcol jspace absolute-card-portfolio">
              <span>Total asset volume</span>
              <h5 class="bold" style="position: absolute; bottom: 0; left: 20px;">{{ remainingToken }} MWh</h5>
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
                          <img :src="energiesColored[tokenDetail?.assetInfo.assetType]" :alt="`${tokenDetail?.assetInfo.assetType} icon`" style="width: 20px;">
                          {{ tokenDetail?.assetInfo.assetType }}
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
                        v-for="(item, index) in tokenDetail?.assetInfo.dates" :key="index"
                        class="jspace divrow mb-1"
                      >
                        <span style="color: #475467;">{{
                          index === 0 ? "Registration Date"
                          : index === 1 ? "Commissioning Date"
                          : "Expire Date"
                        }}</span>
                        <span>{{ item }}</span>
                      </div>
                    </v-col>
                  </v-row>
                </v-window-item>
              </v-window>
            </v-card>
          </v-col>

          <v-col cols="12">
            <h5 class="bold">Other sellers</h5>

            <v-data-table
            v-model:items-per-page="itemsPerPage"
            :headers="headers"
            :items="dataMarketplace"
            items-per-page="-1"
            class="my-data-table deletemobile"
            density="compact"
            >
              <template #[`item.company`]="{ item }">
                <span class="flex-acenter" style="gap: 5px; text-wrap: nowrap">
                  <img :src="companies[item.company]" :alt="`${item.company} icon`" style="width: 20px;">
                  {{ item.company }}
                </span>
              </template>

              <template #[`item.country`]="{ item }">
                <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                  <img :src="countries[item.country]" :alt="`${item.country} Icon`" style="width: 20px;">
                  {{ item.country }}
                </span>
              </template>

              <template #[`item.price`]="{ item }">
                <span class="divrow jspace acenter">
                  {{ item.price }} <v-sheet class="chip-currency bold">{{ item.currency }}</v-sheet>
                </span>
              </template>

              <template #[`item.mwh`]="{ item }">
                <span class="flex-acenter">
                  <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon" class="mr-1" style="width: 15px">
                  {{ item.mwh }}
                </span>
              </template>

              <template #[`item.actions`]="{ item }">
                <div class="center">
                  <img src="@/assets/sources/icons/wallet.svg" alt="wallet" style="width: 16px; height: 16px;"> <span class="bold ml-2">Buy</span>
                </div>
              </template>
            </v-data-table>
          </v-col>

          <v-col v-for="(item,index) in dataMarketplace" :key="index" xl="3" lg="3" md="4" sm="6" cols="12" class="showmobile">
            <v-card class="card cards-marketplace" @click="goDetails(item)">
              <div class="jspace divrow mb-1">
                <span>Facility name</span>
                <span style="color: #475467;" class="acenter">
                  <img :src="companies[item.company]" alt="icon" class="mr-1" style="width: 20px;"> {{ item.company }}
                </span>
              </div>

              <div class="jspace divrow mb-1">
                <span>Country</span>
                <span style="color: #475467;" class="acenter">
                  <img :src="countries[item.country]" alt="icon" class="mr-1" style="width: 20px;"> {{ item.country }}
                </span>
              </div>

              <div class="jspace divrow mb-1">
                <span>Price</span>
                <span style="color: #475467;">{{ item.price }}</span>
              </div>

              <div class="jspace divrow mb-1">
                <span>MWh</span>
                <span style="color: #475467;">
                  <img src="@/assets/sources/icons/lightbulb.svg" alt="lightbulb icon" style="width: 12px">
                  {{ item.mwh }}
                </span>
              </div>

              <v-btn class="btn2 w-100 mt-2" style="max-height: 40px !important">
                <img src="@/assets/sources/icons/wallet-closed.svg" alt="credit-card icon">
                Buy
              </v-btn>
            </v-card>
          </v-col>
        </v-row>
      </v-col>

      <v-col xl="4" lg="4" md="4" cols="12">
        <v-col cols="12" class="pt-0 pl-0">
          <div class="divrow mb-4" style="gap: 10px; flex-wrap: wrap;">
            <v-btn class="btn btn2" @click="dialogStaticPrice = true" style="flex: 1 1 calc(50% - 10px)">
              Sell
            </v-btn>

            <v-btn class="btn btn2" @click="dialogTakeOffMarket = true" style="flex: 1 1 calc(50% - 10px)">
              Take off market
            </v-btn>

            <v-btn class="btn btn2" @click="dialogChooseSeller = true" style="flex: 1 1 calc(50% - 10px)">
              Buy
            </v-btn>

            <v-btn class="btn" @click="dialogRedeemSure = true" style="flex: 1 1 calc(50% - 10px)">
              Reedem Token
            </v-btn>
          </div>

          <!-- TODO ask about this -->
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


          <!-- TODO ask about this -->
          <v-card class="card divcol pt-6">
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
          </v-card>
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

        <v-card class="card mt-6 pa-6" v-for="(item, index) in dataCardEnergy" :key="index">
          <span class="bold mt-3">Checkout review</span>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 150%; position: relative; left: -50px;"></v-divider>
          
          <div class="jspace divrow mb-4 acenter">
            <h5 class="acenter mb-0 bold h5-mobile"><img src="@/assets/sources/images/avatar-rec.svg" alt="Avatar" class="mr-2" style="width: 40px;"> #123455667</h5>
            <div class="divrow mb-0 astart acenter">
              <h5 class="mb-0 mr-2 h5-mobile">
                $ 124.05
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>          
          </div>
          
          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
              {{ item.energy_source }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Country</span>
            <span class="flex-center" style="gap: 5px">
              <img :src="countries[item.country]" :alt="`${item.country} flag`">
              {{ item.country }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Amount</span>
            <span>140MWh</span>
          </div>
        </v-card>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogTakeOffMarket = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogTakeOffMarket = false;" style="border: none!important;">Take off market</v-btn>
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
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogRedeem = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
          </v-sheet>
        </v-sheet>
        <h6>IREC redemption details</h6>
        <span class="tertiary">Please check all information on your tokenized assets’ redemption. You can redeem them to your own name, or to another company’s name by deeming them a beneficiary of yours.</span>

        <div class="flex-column mt-4" style="gap: 5px">
          <label for="beneficiary">Beneficiary account (company)</label>
          <v-select
            id="beneficiary"
            :items="[]"
            variant="solo"
            flat
            menu-icon=""
            class="select mb-8"
            bg-color="transparent"
            placeholder="Select beneficiary account"
          >
            <template #append-inner="{ isFocused }">
              <img
                src="@/assets/sources/icons/chevron-down.svg"
                alt="chevron-down icon"
                :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
              >
            </template>
          </v-select>
        </div>

        <v-btn class="btn2" style="width: max-content !important">Add beneficiary</v-btn>

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
              <img :src="energiesColored[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
              {{ item.energy_source }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Country</span>
            <span class="flex-center" style="gap: 5px">
              <img :src="countries[item.country]" :alt="`${item.country} flag`">
              {{ item.country }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Amount</span>
            <span>140MWh</span>
          </div>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 100%;"></v-divider>

          <div class="jspace divrow mt-4">
            <span>Subtotal</span>
            <span>$124.05</span>
          </div>
          <div class="jspace divrow mt-1">
            <span>IVA (19%)</span>
            <span>$12.41</span>
          </div>
          <div class="jspace divrow mt-1">
            <span class="bold">Total</span>
            <span class="bold">$136.46</span>
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
          <div class="jspace divrow">
            <v-btn class="btn" style="background-color: #fff!important; width: max-content!important;">Change</v-btn>
            <!-- <span class="bold">Credit / Debit cards</span> -->
            <span class="bold">Payment with ICP</span>
          </div>
        </div>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogRedeem = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogRedeem = false" style="border: none!important;">Redeem</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Dialog static price -->
    <v-dialog v-model="dialogStaticPrice" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogStaticPrice = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/sell.svg" alt="Sell" style="width: 20px; height: 20px;">
          </v-sheet>
        </v-sheet>
        <h6 class="bold">Price</h6>
        <span class="tertiary mb-4">Set the price you want to sell every MWh of your tokenized asset for. The price is set in USD.</span>

        <label for="sale_amount">Sale amount</label>

        <div class="div-textfield-select mt-3 mb-2">
          <v-text-field
          id="card-number" class="input" variant="solo"  flat
          elevation="0" placeholder="$ 1,000.00"
          hide-details
          >
            <template #append-inner>
              <img src="@/assets/sources/icons/help-circle.svg" alt="help-circle icon" style="width: 18px">
            </template>
          </v-text-field>
          <v-select
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
          </v-select>
        </div>

        <span>Amount per 1 MWh</span>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogStaticPrice = false;">
            <img src="@/assets/sources/icons/arrow-left.svg" alt="arrow-left icon">
            Back
          </v-btn>
          <v-btn class="btn" @click="dialogStaticPrice = false; dialogSellingDetailsReview = true" style="border: none!important;">Confirm</v-btn>
        </div>
      </v-card>
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

        <v-card class="card mt-6 pa-6" v-for="(item, index) in dataCardEnergy" :key="index">
          <span class="bold mt-3">Checkout review</span>

          <v-divider class="mb-3 mt-4"  thickness="2" style="width: 150%; position: relative; left: -50px;"></v-divider>
          
          <div class="jspace divrow mb-4 acenter">
            <h5 class="acenter mb-0 bold h5-mobile"><img src="@/assets/sources/images/avatar-rec.svg" alt="Avatar" class="mr-2" style="width: 40px;"> #123455667</h5>
            <div class="divrow mb-0 astart acenter">
              <h5 class="mb-0 mr-2 h5-mobile">
                $ 124.05
              </h5>
              <span style="color:#475467">per MWh</span>
            </div>          
          </div>


          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source type</span>
            <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
              <img :src="energiesColored[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
              {{ item.energy_source }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Country</span>
            <span class="flex-center" style="gap: 5px">
              <img :src="countries[item.country]" :alt="`${item.country} flag`">
              {{ item.country }}
            </span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Amount</span>
            <span>140MWh</span>
          </div>
        </v-card>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogSellingDetailsReview = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogSellingDetailsReview = false;" style="border: none!important;">Put on the market</v-btn>
        </div>
      </v-card>
    </v-dialog>

    <!-- Dialog choose seller -->
    <v-dialog v-model="dialogChooseSeller" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogChooseSeller = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/wallet.svg" alt="Wallet" style="width: 20px;">
          </v-sheet>
        </v-sheet>
        <h6>Choose seller</h6>
        <span class="tertiary">This is a list of all sellers of this tokenized asset.</span>

        <div class="d-flex" style="gap: 20px">
          <v-select
            :items="['Sphere']"
            variant="outline"
            flat
            menu-icon=""
            class="select mb-4"
            bg-color="#ffffff"
            hide-details
            density="compact"
          >
            <template #append-inner="{ isFocused }">
              <img
                src="@/assets/sources/icons/chevron-down.svg"
                alt="chevron-down icon"
                :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
              >
            </template>
          </v-select>
          
          <div class="divcol" style="gap: 10px;">
            <label class="text-end">Price</label>
            <h6>$125.04</h6>
          </div>
        </div>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogChooseSeller = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogChooseSeller = false; dialogPurchaseReview = true" style="border: none!important;">Proceed with payment</v-btn>
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
              <img :src="energiesColored[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
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
            <span>IVA (19%)</span>
            <span>$12.41</span>
          </div>
          <div class="jspace divrow mt-1">
            <span class="bold">Total</span>
            <span class="bold">$136.46</span>
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
          <div class="jspace divrow">
            <v-btn class="btn" style="background-color: #fff!important; width: max-content!important;">Change</v-btn>
            <!-- <span class="bold">Credit / Debit cards</span> -->
            <span class="bold">Payment with ICP</span>
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
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogPaymentConfirm = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon" style="width: 22px">
          </v-sheet>
        </v-sheet>
        <h6>Payment confirmation</h6>
        <span class="tertiary">The transaction was done succesfully. You can now check your Portafolio to find your new token. In the receipt bellow you will find all purchase information, feel free to download.</span>

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
              <img :src="energiesColored[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
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
            <img src="@/assets/sources/icons/download.svg" alt="download icon" style="width: 22px">
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
          <v-btn class="btn" @click="dialogRedeemCertificates = false;" style="border: none!important;">Yes, redeem</v-btn>
        </div>
      </v-card>
    </v-dialog>
  </div>
</template>

<script>
import '@/assets/styles/pages/token-details.scss'
import checkboxCheckedIcon from '@/assets/sources/icons/checkbox-checked.svg'
import checkboxBaseIcon from '@/assets/sources/icons/checkbox-base.svg'
import VueApexCharts from "vue3-apexcharts"
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

import HydroEnergyColorIcon from '@/assets/sources/energies/hydro-color.svg'
import WindEnergyColorIcon from '@/assets/sources/energies/wind-color.svg'
import SolarEnergyColorIcon from '@/assets/sources/energies/solar-color.svg'

import ChileIcon from '@/assets/sources/icons/CL.svg'
import { UsersCanister } from '@/repository/users-canister'
import { UserProfileModel } from '@/models/user-profile-model'


export default {
  components:{
    apexchart: VueApexCharts,
  },
  data(){
    return{
      checkboxCheckedIcon,
      checkboxBaseIcon,
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
      energiesColored: {
        hydro: HydroEnergyColorIcon,
        ocean: OceanEnergyIcon,
        geothermal: GeothermalEnergyIcon,
        biome: BiomeEnergyIcon,
        wind: WindEnergyColorIcon,
        sun: SolarEnergyColorIcon,
      },
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
      tokenDetail: undefined,
      remainingToken: undefined,
      headers: [
        { title: 'Company name', sortable: false, key: 'company'},
        { title: 'Country', key: 'country', sortable: false },
        { title: 'Price', key: 'price', sortable: false },
        { title: 'MWh', key: 'mwh', sortable: false },
        { title: 'Actions', key: 'actions', sortable: false, align: 'center'},
      ],
      dataMarketplace: [],

      itemsPerPage: 100,
      dialogTakeOffMarket: false,
      dialogPaymentConfirm: false,
      dialogChooseSeller: false,
      dialogPurchaseReview: false,
      dialogRedeemCertificates: false,
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
      tabsSpecifications: null,
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
          country: 'chile',
          date: '24/12/2023',
          date_start: '12/03/2023',
          co2: '0,12%',
          radioactivity: '0,005%',
          // certification: 'Certification type',
        },
      ],

      series: [43],
      chartOptions: {
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
        labels: ['Available'],
      },
      seriesBar: [
        {
        name: 'PRODUCT A',
        data: [11424, 33355, 32431, 21167, 9212, 44543, 11664, 45155, 12841, 45637, 12122, 19443]
        }, 
      ],
      chartOptionsBar: {
        chart: {
          type: 'bar',
          height: 150,
          stacked: true,
          toolbar: {
            show: false
          },
          zoom: {
            enabled: true
          }
        },
        colors: ['#00393D'],
        responsive: [{
          breakpoint: 480,
          options: {
            legend: {
              position: 'bottom',
              offsetX: -10,
              offsetY: 0
            }
          }
        }],
        plotOptions: {
          bar: {
            horizontal: false,
            borderRadius: 10,
            dataLabels: {
              enabled: false,
            }
          },
        },
        xaxis: {
          type: 'category',
          categories: ['Jan','Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        },
        legend: {
          show: false,
        },
        dataLabels: {
          enabled: false
        },
        fill: {
          opacity: 1
        }
      }
    }
  },
  computed: {
    tokenId() {
      return this.$route.query.tokenId
    },
    prevRoutePatch () {
      const fullPath = this.$router.options.history.state.back,
      path = fullPath.split('?')[0]

      return path.substring(1, path.length).split('-').join(' ')
    }
  },
  created() {
    this.getData()

    const input = this.$route.query.input
    if (input) {
      this.$router.replace({ path: '/token-details', query: { tokenId: this.tokenId } })

      switch (input) {
        case 'sell': this.dialogStaticPrice = true
          break;

        case 'redeem': this.dialogRedeemSure = true
          break;

        case 'takeOff': this.dialogTakeOffMarket = true
          break;
      }
    }
  },

  methods:{
    async getData() {
      try {
        const [token, remainingToken] = await Promise.allSettled([
          UsersCanister.getSinglePortfolio(this.tokenId),
          UsersCanister.getRemainingToken(this.tokenId)
        ])

        this.tokenDetail = token.value
        this.remainingToken = remainingToken.value
        console.log("token", token, "remaining", remainingToken);

        // TODO checkout this
        this.tokenDetail.companyLogo = UserProfileModel.get().companyLogo

        this.dataMarketplace.push({
          company: 'Sphere',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        })
      } catch (error) {
        console.error(error);
      }
    },
    value1(){
      this.radioSell = 1;
    },
    value2(){
      this.radioSell = 2;
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