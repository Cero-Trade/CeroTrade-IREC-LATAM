<template>
  <div id="rec-single">
    <span class="mb-10 acenter" style="color: #475467; font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      My portfolio 
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span style="color: #00555B;">IREC #5</span>
    </span>
    <h3 class="acenter mb-0"><img src="@/assets/sources/images/avatar-rec.svg" alt="Avatar" class="mr-2"> IREC #5</h3>
    <span class="bold mb-6 ml-16" style="color: #475467;">#1223456778</span>

    <v-row>
      <v-col xl="8" lg="8" md="8" cols="12">
        <v-row>
          <v-col xl="5" lg="5" cols="12">
            <v-card class="card cards-rec" v-for="(item, index) in dataCardEnergy" :key="index">
              <div class="jspace divrow mb-1">
                <span style="color: #475467;">Type</span>
                <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                  <img :src="energiesColored[item.energy_source]" :alt="`${item.energy_source} icon`" style="width: 20px;">
                  {{ item.energy_source }}
                </span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">Start date of production</span>
                <span>{{ item.date_start }}</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">End date of production</span>
                <span>{{ item.date }}</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">CO2 Emission</span>
                <span>{{ item.co2 }}</span>
              </div>

              <div class="jspace divrow mt-3 mb-1">
                <span style="color: #475467;">Radioactivity emission</span>
                <span>{{ item.radioactivity }}</span>
              </div>
            </v-card>
          </v-col>

          <v-col xl="4" lg="4" cols="12">
            <v-card class="card relative" style="min-height: 100%!important;">
              <span>Total available</span>
              <div id="chart">
                <apexchart type="radialBar" :options="chartOptions" :series="series"></apexchart>
              </div>
            </v-card>
          </v-col>

          <v-col xl="3" lg="3" cols="12">
            <v-card class="card divcol jspace absolute-card-portfolio mb-2">
              <span>Total amount owned</span>
              <h5 class="bold" style="position: absolute; bottom: 0; left: 20px;">113.4 MWh</h5>
            </v-card>

            <v-card class="card divcol jspace absolute-card-portfolio">
              <span>Total asset volume</span>
              <h5 class="bold" style="position: absolute; bottom: 0; left: 20px;">113.4 MWh</h5>
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
                <v-window-item value="one" v-for="(item, index) in dataDeviceDetails" :key="index">
                  <h5 class="bold mb-6 mt-4">Device Details</h5>

                  <v-row>
                    <v-col xl="8" lg="8" md="8" cols="12">
                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Name</span>
                        <span>{{ item.name }}</span>
                      </div>

                      <div class="jspace divrow mb-1">
                        <span style="color: #475467;">Type</span>
                        <span>{{ item.type }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Device group</span>
                        <span class="text-capitalize flex-acenter" style="gap: 5px; text-wrap: nowrap">
                          <img :src="energiesColored[item.device_group]" :alt="`${item.device_group} icon`" style="width: 20px;">
                          {{ item.device_group }}
                        </span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1" style="gap: 20px;">
                        <span style="color: #475467;">Description</span>
                        <span style="text-align: right; max-width: 60%;">{{ item.description }}</span>
                      </div>
                    </v-col>
                  </v-row>
                </v-window-item>

                <v-window-item value="two" v-for="(item, index) in dataSpecifications" :key="index">
                  <h5 class="bold mb-6 mt-4">Specifications</h5>

                  <v-row>
                    <v-col xl="8" lg="8" md="8" cols="12">
                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Device Code</span>
                        <span>{{ item.device_code }}</span>
                      </div>

                      <div class="jspace divrow mb-1">
                        <span style="color: #475467;">Capacity</span>
                        <span>{{ item.capacity }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Location</span>
                        <span>{{ item.location }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Latitude</span>
                        <span>{{ item.latitude }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Longitude</span>
                        <span>{{ item.longitude }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Address</span>
                        <span>{{ item.address }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">State/Province</span>
                        <span>{{ item.state }}</span>
                      </div>

                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Country</span>
                        <span>{{ item.country }}</span>
                      </div>
                    </v-col>
                  </v-row>
                </v-window-item>

                <v-window-item value="three" v-for="(item, index) in dataDates" :key="index">
                  <h5 class="bold mb-6 mt-4">Dates</h5>

                  <v-row>
                    <v-col xl="8" lg="8" md="8" cols="12">
                      <div class="jspace divrow mt-3 mb-1">
                        <span style="color: #475467;">Registration Date</span>
                        <span>{{ item.registration_date }}</span>
                      </div>

                      <div class="jspace divrow mb-1">
                        <span style="color: #475467;">Commissioning Date</span>
                        <span>{{ item.commissioning_date }}</span>
                      </div>

                      <div class="jspace divrow mb-1">
                        <span style="color: #475467;">Expire Date</span>
                        <span>{{ item.expire_date }}</span>
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
          <v-card class="card mb-6 divcol astart card-currency">
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
            <v-btn class="btn btn2" @click="dialogStaticPrice = true" style="flex: 1 1 calc(50% - 10px)">
              Sell
            </v-btn>

            <v-btn class="btn btn2" @click="dialogTakeOffMarket = true" style="flex: 1 1 calc(50% - 10px)">
              Take off market
            </v-btn>

            <v-btn class="btn btn2" @click="dialogPurchaseReview = true" style="flex: 1 1 calc(50% - 10px)">
              Buy
            </v-btn>

            <v-btn class="btn" @click="dialogRedeemSure = true" style="flex: 1 1 calc(50% - 10px)">
              Reedem Token
            </v-btn>
          </div>

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

    <!-- Dialog Tokenize Are your sure? -->
    <!-- <v-dialog v-model="dialogAreYouSure" persistent>
      <v-card class="card dialog-card-tokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogAreYouSure = false">
        <v-sheet class="mb-6 double-sheet">      
          <v-sheet>
            <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon" style="width: 22px">
          </v-sheet>
        </v-sheet>
        <h6>Are you sure you want to de-tokenize your I-REC?</h6>
        <span class="tertiary">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Explicabo illum asperiores eaque perferendis iure nemo.</span>

        <div class="div-check-items mt-4 mb-2">
          <span class="tertiary center">
            <img src="@/assets/sources/icons/check-grey.svg" alt="Check icon" class="mr-2"> Lorem ipsum dolor sit amet consectetur adipisicing elit. Ipsam, vitae. 
          </span>
          <span class="tertiary center">
            <img src="@/assets/sources/icons/check-grey.svg" alt="Check icon" class="mr-2"> Lorem ipsum dolor sit amet consectetur adipisicing elit. Ipsam, vitae. 
          </span>
          <span class="tertiary center">
            <img src="@/assets/sources/icons/check-grey.svg" alt="Check icon" class="mr-2"> Lorem ipsum dolor sit amet consectetur adipisicing elit. Ipsam, vitae. 
          </span>
        </div>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogAreYouSure = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogAreYouSure = false;dialogDetokenize = true" style="border: none!important;">Yes I am sure</v-btn>
        </div>
      </v-card>
    </v-dialog> -->

    <!-- Dialog Detokenize -->
    <!-- <v-dialog v-model="dialogDetokenize" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogDetokenize = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon" style="width: 22px">
          </v-sheet>
        </v-sheet>
        <h6>De-tokenization details</h6>
        <span class="tertiary">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Explicabo illum asperiores eaque perferendis iure nemo.</span>

        <v-card class="card cards-rec mt-6" v-for="(item, index) in dataCardEnergy" :key="index">
          <div class="jspace divrow mb-1 acenter">
            <h5 class="acenter h5-mobile"><img src="@/assets/sources/images/avatar-rec.svg" alt="Avatar" class="mr-2" style="width: 40px;"> #123455667</h5>
            <v-icon>mdi-arrow-right</v-icon>
            <h5 class="acenter h5-mobile"><img src="@/assets/sources/images/avatar-rec.svg" alt="Avatar" class="mr-2" style="width: 40px;"> #123455667</h5>
          </div>

          <div class="divrow mb-10 astart acenter">
            <h5 class="mb-0 mr-2 h5-mobile">
              $ 124.05
            </h5>
            <span style="color:#475467">per MWh</span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Energy source</span>
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
            <span style="color: #475467;">Date of Inssuance</span>
            <span>{{ item.date }}</span>
          </div>

          <div class="jspace divrow mb-1">
            <span style="color: #475467;">Certification type</span>
            <span>{{ item.certification }}</span>
          </div>
        </v-card>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogDetokenize = false">Cancel</v-btn>
          <v-btn class="btn" @click="dialogDetokenize = false;" style="border: none!important;">De-Tokenize</v-btn>
        </div>
      </v-card>
    </v-dialog> -->

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

    <!-- Dialog sell options -->
    <!-- <v-dialog v-model="dialogSellOptions" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogSellOptions = false">
        <v-sheet class="double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/sell.svg" alt="Sell icon" style="width: 25px; height: 25px;">
          </v-sheet>
        </v-sheet>
        <h6>Choose price option to sell</h6>
        <span class="tertiary">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Explicabo illum asperiores eaque perferendis iure nemo.</span>

        <div class="div-radio-sell" @click="value1()">
          <v-sheet class="double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/dynamic-price.svg" alt="Dynamic Sell" style="width: 15px;">
            </v-sheet>
          </v-sheet>
          <div class="divcol ml-6">
            <span><b>Dynamic price</b> range</span>
            <span>Lorem ipsum dolor, sit amet consectetur adipisicing elit.</span>
          </div>
          <v-radio v-model="radioSell" :value="1" density="compact" class="radio-right" @click="value1()"></v-radio>
        </div>

        <div class="div-radio-sell" @click="value2()">
          <v-sheet class="double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/static-price.svg" alt="Dynamic Sell" style="width: 20px;   height: 20px;">
            </v-sheet>
          </v-sheet>
          <div class="divcol ml-6">
            <span><b>Static price</b> / MWh</span>
            <span>Lorem ipsum dolor, sit amet consectetur adipisicing elit.</span>
          </div>
          <v-radio v-model="radioSell" :value="2" density="compact" class="radio-right" @click="value2()"></v-radio>
        </div>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogSellOptions = false">Cancel</v-btn>
          <v-btn class="btn" @click="goToStaticOrDynamic()" style="border: none!important;">
            Next
            <v-icon class="ml-2">mdi-arrow-right</v-icon>
          </v-btn>
        </div>
      </v-card>
    </v-dialog> -->

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

    <!-- Dialog dynamic price -->
    <!-- <v-dialog v-model="dialogDynamicPrice" persistent>
      <v-card class="card dialog-card-detokenize">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogDynamicPrice = false">
        <v-sheet class="mb-6 double-sheet">
            <v-sheet>
              <img src="@/assets/sources/icons/dynamic-price.svg" alt="Dynamic Sell" style="width: 20px;">
            </v-sheet>
        </v-sheet>
        <h6>Dynamic price</h6>
        <span class="tertiary mb-4">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Explicabo illum asperiores eaque perferendis iure nemo.</span>

        <div class="border-card jspace acenter mb-4 mobile-border-card">
          <div class="divrow acenter"> 
            <v-sheet class="mr-4 double-sheet">
              <v-sheet>
                <img src="@/assets/sources/icons/alert.svg" alt="Alert" style="width: 15px; height: 15px;">
              </v-sheet>
            </v-sheet>
            <span class="bold">Average selling price</span>
          </div>
          <span>124.00 € / per MWh</span>
        </div>

        <div class="border-card jspace acenter mobile-border-card">
          <div class="divrow acenter"> 
            <v-sheet class="mr-4 double-sheet">
              <v-sheet>
                <img src="@/assets/sources/icons/static-price.svg" alt="Price Range" style="width: 15px; height: 15px;">
              </v-sheet>
            </v-sheet>
            <span class="bold">Price range</span>
          </div>
          <span>min. 100.00 € - max. 148.00 € / per MWh</span>
        </div>

        <div class="divrow center mt-6" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogDynamicPrice = false; dialogSellOptions = true"><v-icon class="mr-2">mdi-arrow-left</v-icon> Back</v-btn>
          <v-btn class="btn" @click="dialogDynamicPrice = false; dialogSellingDetailsReview = true" style="border: none!important;">Confirm</v-btn>
        </div>
      </v-card>
    </v-dialog> -->

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

    <!-- Dialog participant benefits -->
    <!-- <v-dialog v-model="dialogParticipantBenefits" persistent>
      <v-card class="card card-dialog-participant">
        <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="dialogParticipantBenefits = false">
        <v-sheet class="mb-6 double-sheet">
          <v-sheet>
            <img src="@/assets/sources/icons/check-verified.svg" alt="check-verified icon" style="width: 22px">
          </v-sheet>
        </v-sheet>
        <h6>Enjoy participant benefits</h6>
        <span class="tertiary">Lorem ipsum dolor sit amet consectetur adipisicing elit. At alias laboriosam iste eum, repellendus.</span>
        <span class="tertiary mt-4" style="font-weight: 700;"><v-icon>mdi-help-circle-outline</v-icon> How to become a participant</span>
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
        <div class="divrow center mt-6 divcol-mobile" style="gap: 10px;">
          <v-btn class="btn" style="background-color: #fff!important;"  @click="dialogParticipantBenefits = false; dialogPurchaseReview = true">Proceed as non-participant</v-btn>
          <v-btn class="btn" @click="dialogParticipantBenefits = false;" style="border: none!important;">Become a participant</v-btn>
        </div>
      </v-card>
    </v-dialog> -->

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
        <span class="tertiary">Lorem ipsum dolor, sit amet consectetur adipisicing elit. Explicabo illum asperiores eaque perferendis iure nemo.</span>
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
import '@/assets/styles/pages/rec-single.scss'
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
        'hydro energy': HydroEnergyColorIcon,
        ocean: OceanEnergyIcon,
        geothermal: GeothermalEnergyIcon,
        biome: BiomeEnergyIcon,
        'wind energy': WindEnergyColorIcon,
        sun: SolarEnergyColorIcon,
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
        { title: 'Company name', sortable: false, key: 'company'},
        { title: 'Country', key: 'country', sortable: false },
        { title: 'Price', key: 'price', sortable: false },
        { title: 'MWh', key: 'mwh', sortable: false },
        { title: 'Actions', key: 'actions', sortable: false, align: 'center'},
      ],
      dataMarketplace: [
        {
          company: 'Sphere',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'KAPIDAĞ RES',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'Sisyphus',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'Focal Point',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'SIlverstone',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'General Electric',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'BlueSky',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'Zenith',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'Liberty',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'Sunshine',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
        {
          company: 'Prime',
          price: "125.00",
          currency: '$',
          country: 'chile',
          mwh: 32,
        },
      ],

      itemsPerPage: 100,
      dialogTakeOffMarket: false,
      dialogPaymentConfirm: false,
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
          device_group: 'wind energy',
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

      // seriesCandle: [{
      //   data: [
      //     {
      //       x: new Date(1538778600000),
      //       y: [180, 185, 179, 182]
      //     },
      //     {
      //       x: new Date(1538780400000),
      //       y: [182, 188, 179, 183]
      //     },
      //     {
      //       x: new Date(1538782200000),
      //       y: [179, 186, 180, 184]
      //     },
      //     {
      //       x: new Date(1538784000000),
      //       y: [183, 184, 182, 185]
      //     },
      //     {
      //       x: new Date(1538785800000),
      //       y: [181, 187, 178, 183]
      //     },
      //     {
      //       x: new Date(1538787600000),
      //       y: [180, 185, 179, 182]
      //     },
      //     {
      //       x: new Date(1538789400000),
      //       y: [183, 184, 179, 182] 
      //     },
      //     {
      //       x: new Date(1538791200000),
      //       y: [179, 187, 181, 184]
      //     },
      //     {
      //       x: new Date(1538793000000),
      //       y: [181, 185, 179, 182]
      //     },
      //     {
      //       x: new Date(1538794800000),
      //       y: [183, 184, 179, 182] 
      //     },
      //     {
      //       x: new Date(1538796600000),
      //       y: [180, 187, 179, 183]
      //     },
      //     {
      //       x: new Date(1538798400000),
      //       y: [182, 185, 181, 184]
      //     },
      //     {
      //       x: new Date(1538800200000),
      //       y: [181, 185, 180, 182]
      //     },
      //     {
      //       x: new Date(1538802000000),
      //       y: [179, 186, 179, 183]
      //     },
      //     {
      //       x: new Date(1538803800000),
      //       y: [180, 184, 178, 183]
      //     },
      //     {
      //       x: new Date(1538805600000),
      //       y: [183, 184, 179, 182] 
      //     },
      //     {
      //       x: new Date(1538807400000),
      //       y: [182, 185, 179, 183]
      //     },
      //     {
      //       x: new Date(1538809200000),
      //       y: [179, 188, 181, 184]
      //     },
      //     {
      //       x: new Date(1538811000000),
      //       y: [181, 186, 180, 183]
      //     },
      //     {
      //       x: new Date(1538812800000),
      //       y: [183, 184, 179, 182] 
      //     },
      //     {
      //       x: new Date(1538814600000),
      //       y: [180, 185, 179, 182]
      //     },
      //     {
      //       x: new Date(1538816400000),
      //       y: [182, 187, 180, 183]
      //     },
      //     {
      //       x: new Date(1538818200000),
      //       y: [179, 186, 181, 184]
      //     },
      //     {
      //       x: new Date(1538820000000),
      //       y: [183, 184, 179, 182] 
      //     },
      //     {
      //       x: new Date(1538821800000),
      //       y: [183, 184, 181, 185]
      //     },
      //     {
      //       x: new Date(1538823600000),
      //       y: [182, 186, 178, 183]
      //     },
      //     {
      //       x: new Date(1538825400000),
      //       y: [180, 187, 180, 184]
      //     },
      //     {
      //       x: new Date(1538827200000),
      //       y: [182, 185, 179, 183]
      //     },
      //     {
      //       x: new Date(1538829000000),
      //       y: [179, 186, 180, 182]
      //     },
      //     {
      //       x: new Date(1538830800000),
      //       y: [181, 185, 179, 183]
      //     },
      //   ]
      // }],
      // chartOptionsCandle: {
      //   chart: {
      //     type: 'candlestick',
      //     height: 350,
      //     toolbar: {
      //       show: false
      //     },
      //   },
      //   title: {
      //     show: false,
      //   },
      //   xaxis: {
      //     type: 'datetime',
      //     labels: {
      //       show: false
      //     }
      //   },
      //   yaxis: {
      //     tooltip: {
      //       enabled: true
      //     }
      //   },
      //   plotOptions: {
      //     candlestick: {
      //       colors: {
      //         upward: '#00555B',
      //         downward: '#F97066'
      //       },
      //     },
      //   },
      // },
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
      },
    }
  },


  methods:{
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