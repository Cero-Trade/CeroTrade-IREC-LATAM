<template>
  <div id="home">
    <img src="@/assets/sources/images/side-img-1.png" alt="Side banner" class="side-banner">
    <v-window v-model="windowStep" :show-arrows="false" :touch="false">
      <!-- registration -->
      <v-window-item :value="1">
        <v-form ref="companyFormRef" class="container-windows-step" @submit.prevent="nextStep">
          <v-card class="card card-register">
            <div class="d-flex align-center mb-6" style="gap: 5px;">
              <v-btn icon style="width: 25px; height: 25px; background: transparent !important" elevation="0" to="/auth/login">
                <img src="@/assets/sources/icons/arrow-left.svg" alt="arrow left">
              </v-btn>
              <v-sheet class="sheet-img">
                <img src="@/assets/sources/icons/logo.svg" alt="Logo" class="img-logo">
              </v-sheet>
            </div>
            <h5 class="mb-2">HELLO</h5>
            <p class="font300 color-grey">Please enter your company details</p>
            <v-row>
              <v-col cols="12">
                <label for="compnay-logo">Company logo</label>
                <v-img-input
                v-model="companyForm.companyLogo" id="compnay-logo" variant="solo"
                border="1px solid #EAECF0"
                rounded="10px"
                accept="image/*"
                sizes="120px"
                prepend-icon=""
                style="max-width: max-content !important;"
                :rules="[globalRules.listRequired, () => globalRules.limitFileSize(companyForm.companyLogo, 3000000)]"
                ></v-img-input>
              </v-col>
              <v-col xl="6" lg="6" md="6" cols="12">
                <label for="companey-name">Company name</label>
                <v-text-field 
                v-model="companyForm.companyName"
                id="company-name" class="input" variant="solo" flat elevation="0" 
                placeholder="olivia@cerotrade.com"
                :rules="[globalRules.required]"
                ></v-text-field>
              </v-col>
              <v-col xl="6" lg="6" md="6" sm="12" cols="12">
                <label for="company-id">Company ID</label>
                <v-text-field 
                v-model="companyForm.companyId"
                id="company-id" class="input" variant="solo" flat elevation="0" 
                placeholder="123456789"
                :rules="[globalRules.required]"
                >
                  <template #append-inner>
                    <img src="@/assets/sources/icons/help-circle.svg" alt="help-circle icon">
                  </template>
                </v-text-field>
              </v-col>
              <v-col xl="6" lg="6" md="6" sm="12" cols="12">
                <label for="evident-id">Evident Account ID</label>
                <v-text-field 
                v-model="companyForm.evidentId"
                id="evident-id" class="input" variant="solo" flat elevation="0" 
                placeholder="ET5T6GHO"
                :rules="[globalRules.required]"
                >
                  <template #append-inner>
                    <img src="@/assets/sources/icons/help-circle.svg" alt="help-circle icon">
                  </template>
                </v-text-field>
              </v-col>
              <v-col xl="6" lg="6" md="6" sm="12" cols="12">
                <label for="country">Country</label>
                <v-autocomplete
                v-model="companyForm.country"
                id="country" class="input" variant="solo" flat 
                :items="Object.values(countries)"
                item-title="name"
                item-value="code"
                elevation="0" placeholder="USA"
                menu-icon=""
                :rules="[globalRules.required]"
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
                    <span class="bold ml-2">{{ item.raw.name }}</span>
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
              </v-col>
              <v-col xl="6" lg="6" md="6" sm="12" cols="12">
                <label for="city">City</label>
                <v-text-field
                  v-model="companyForm.city"
                  id="city" class="input" variant="solo" flat elevation="0" 
                  placeholder="New York"
                  menu-icon=""
                  :rules="[globalRules.required]"
                ></v-text-field>
              </v-col>
              <v-col cols="12">
                <label for="company-address">Company address</label>
                <v-text-field
                v-model="companyForm.address" id="company-address" class="input" variant="solo" flat elevation="0" placeholder="Enter your company full address"
                :rules="[globalRules.required]"
                ></v-text-field>
              </v-col>
              <v-col cols="12">
                <label for="email-address">Email address</label>
                <v-text-field
                v-model="companyForm.email" id="email-address" class="input" variant="solo" flat elevation="0" placeholder="Enter your email address"
                :rules="[globalRules.email]"
                ></v-text-field>
              </v-col>
              <!-- <v-col xl="6" lg="6" md="6" sm="12" cols="12">
                <label for="password">Password</label>
                <v-text-field
                id="confirm-password" class="input" variant="solo" flat elevation="0" 
                :append-inner-icon="show_password ? 'mdi-eye-outline' : 'mdi-eye-off-outline'"
                :type="show_password ? 'text' : 'password'"
                @click:append-inner="show_password = !show_password"
                ></v-text-field>
              </v-col>
              <v-col xl="6" lg="6" md="6" sm="12" cols="12">
                <label for="confirm-password">Confirm password</label>
                <v-text-field
                id="confirm-password" class="input" variant="solo" flat elevation="0" 
                :append-inner-icon="show_password ? 'mdi-eye-outline' : 'mdi-eye-off-outline'"
                :type="show_password ? 'text' : 'password'"
                @click:append-inner="show_password = !show_password"
                ></v-text-field>
              </v-col> -->

              <v-col cols="12" class="mt-4">
                <label for="beneficiary">Beneficiary id</label>
                <v-text-field
                  v-model="beneficiary" id="beneficiary" class="input" variant="solo" flat elevation="0" placeholder="Enter beneficiary id (optional)"
                  :rules="[beneficiary ? globalRules.principalId : true]"
                ></v-text-field>
              </v-col>


              <v-col cols="12">
                <v-btn class="center btn2" :disabled="loadingBtn" @click="createII">
                  {{ AuthClientApi.isAnonymous() ? 'Create Internet Identity ' : 'Change Internet Identity ' }}
                  <img src="@/assets/sources/icons/internet-computer-icon.svg" alt="IC icon" class="ic-icon">
                </v-btn>
              </v-col>

              <v-col cols="12">
                <v-btn class="center btn" :loading="loadingBtn" @click="nextStep">
                  Create account
                  <img src="@/assets/sources/icons/arrow-right.svg" alt="arrow-right icon">
                </v-btn>
              </v-col>
            </v-row>

            <div class="d-flex align-center justify-center mt-10" style="gap: 5px;">
              <span>i have an account </span>
              <a class="text-tertiary wbold pointer" @click="router.push('/auth/login')">Go login</a>
            </div>
          </v-card>
        </v-form>
      </v-window-item>

      <!-- Verification Email -->
      <v-window-item :value="2">
        <div class="container-windows-step">
          <v-card class="card ml-2 card-register pt-10 pb-10">
            <v-sheet class="sheet-img mb-6">
              <img src="@/assets/sources/icons/logo.svg" alt="Logo" class="img-logo">
            </v-sheet>
            <h5 class="mb-2">Please verify your email</h5>
            <p class="font300 color-grey">Please enter security code you received on your email</p>
            
            <v-row>
              <v-col cols="12" class="jstart astart divcol">
                <label for="otp" style="font-weight: 700; color: #000;">Secure Code</label>
                <v-otp-input
                  id="otp"
                  v-model="otp"
                  @finish="register"
                ></v-otp-input>
              </v-col>
            </v-row>

            <div class="d-flex mt-4" style="gap: 10px; width: 100% !important;">
              <v-btn class="btn" @click="previousStep">
                <img src="@/assets/sources/icons/arrow-right.svg" alt="arrow-right icon" style="rotate: 180deg;">
                Go back
              </v-btn>

              <v-btn class="btn2 not flex-grow-1">Resend code</v-btn>
            </div>
          </v-card>
        </div>
      </v-window-item>
    </v-window>
  </div>
</template>

<script setup>
import '@/assets/styles/pages/home.scss'
import { ref, onBeforeMount } from 'vue'
import { AgentCanister } from '@/repository/agent-canister';
import { useRoute, useRouter } from 'vue-router';
import variables from '@/mixins/variables';
import { useToast } from 'vue-toastification';
import { AuthClientApi } from '@/repository/auth-client-api';
import { storageCollection } from '@/plugins/vue3-storage-secure';

const
  router = useRouter(),
  route = useRoute(),
  toast = useToast(),
  { globalRules, countries } = variables,

windowStep = ref(1),
companyFormRef = ref(),
companyForm = ref({
  companyId: null,
  evidentId: null,
  companyName: null,
  companyLogo: null,
  country: null,
  city: null,
  address: null,
  email: null,
}),
beneficiary = ref(null),
otp = ref(''),
loadingBtn = ref(false)

onBeforeMount(getData)

function getData() {
  // get beneficiary id provided
  const beneficiaryId = route.query.beneficiary || localStorage.getItem(storageCollection.beneficiaryId)
  if (beneficiaryId) {
    localStorage.setItem(storageCollection.beneficiaryId, beneficiaryId)
    beneficiary.value = beneficiaryId
  }
}

function previousStep() {
  otp.value = ''
  windowStep.value--
}

async function nextStep() {
  const validForm = await companyFormRef.value.validate()
  if (!validForm.valid) return;

  if (AuthClientApi.isAnonymous()) return await createII()

  await register()
  // windowStep.value++
}

async function createII() {
  try {
    await AuthClientApi.signIn(nextStep)
  } catch (error) {
    this.$toast.error(error.toString())
  }
}

async function register() {
  if (loadingBtn.value) return
  loadingBtn.value = true

  try {
    await AgentCanister.register(companyForm.value, beneficiary.value)
    localStorage.removeItem(storageCollection.beneficiaryId)

    router.push('/')
    toast.success("You have registered successfuly")
  } catch (error) {
    loadingBtn.value = false
    toast.error(error)
  }
}
</script>
