<template>
  <div id="home">
    <img src="@/assets/sources/images/side-img-1.png" alt="Side banner" class="side-banner">
    <v-window v-model="windowStep" :show-arrows="false">
      <!-- registration -->
      <v-window-item :value="1">
        <v-form ref="companyFormRef" class="container-windows-step" @submit.prevent="nextStep">
          <v-card class="card card-register">
            <v-sheet class="sheet-img mb-6">
              <img src="@/assets/sources/icons/logo.svg" alt="Logo" class="img-logo">
            </v-sheet>
            <h5 class="mb-2">HELLO</h5>
            <p class="font300 color-grey">Please enter your company details</p>
            <v-row>
              <v-col cols="12">
                <label for="compnay-logo">Company logo</label>
                <v-img-input
                v-model="companyForm.companyLogo" id="compnay-logo" variant="solo"
                border="1px solid #EAECF0"
                rounded="10px"
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
                <label for="companey-id">Company ID</label>
                <v-text-field 
                v-model="companyForm.companyID"
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
                <label for="country">Country</label>
                <v-select
                v-model="companyForm.country"
                id="country" class="input" variant="solo" flat 
                :items="countries"
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
                </v-select>
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

              <v-col v-if="AuthClientApi.isAnonymous()"cols="12">
                <v-btn class="center btn2" @click="createII">
                  Create Internet Identity <img src="@/assets/sources/icons/internet-computer-icon.svg" alt="IC icon" class="ic-icon">
                </v-btn>
              </v-col>

              <v-col cols="12">
                <v-btn class="center btn" @click="nextStep">
                  Create account
                  <img src="@/assets/sources/icons/arrow-right.svg" alt="arrow-right icon">
                </v-btn>
              </v-col>
            </v-row>
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
                <!-- TODO put here register method on event -->
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
import countries from '@/assets/sources/json/countries-all.json'
import { ref, onBeforeMount } from 'vue'
import { AgentCanister } from '@/repository/agent-canister';
import { useRouter } from 'vue-router';
import variables from '@/mixins/variables';
import { useToast } from 'vue-toastification';
import { AuthClientApi } from '@/repository/auth-client-api';
import { useStorage } from 'vue3-storage-secure';
import { storageSecureCollection } from '@/plugins/vue3-storage-secure'

const
  router = useRouter(),
  toast = useToast(),
  storage = useStorage(),
  { globalRules } = variables,

windowStep = ref(1),
companyFormRef = ref(),
companyForm = ref({
  companyID: null,
  companyName: null,
  companyLogo: null,
  country: null,
  city: null,
  address: null,
  email: null,
}),
otp = ref('')

onBeforeMount(getData)

function getData() {}

function previousStep() {
  otp.value = ''
  windowStep.value--
}

async function nextStep() {
  if (AuthClientApi.isAnonymous()) return await createII()

  const validForm = await companyFormRef.value.validate()
  if (!validForm.valid) return;

  windowStep.value++
}

// TODO checkout this flow about ii creation and asociate to cero trade
async function createII() {
  const validForm = await companyFormRef.value.validate()
  if (!validForm.valid) return;

  try {
    await AuthClientApi.signIn(nextStep)
  } catch (error) {
    this.$toast.error(error.toString())
  }
}

async function register() {
  try {
    const token = await AgentCanister.register(companyForm.value)
    storage.setSecureStorageSync(storageSecureCollection.tokenAuth, token)
    console.log(token);

    this.$router.push('/')
    toast.success("You have registered successfuly")
  } catch (error) {
    toast.error(error)
  }
}
</script>
