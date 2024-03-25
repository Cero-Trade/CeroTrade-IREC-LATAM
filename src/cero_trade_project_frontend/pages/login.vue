<template>
  <div id="login">
    <img src="@/assets/sources/images/side-img-2.png" alt="Side banner" class="side-banner">
    <v-window v-model="windowStep" :show-arrows="false">
      <!-- login -->
      <v-window-item :value="1">
        <div class="container-windows-step">
          <v-card class="card ml-2 card-register">
            <v-sheet class="sheet-img mb-6 delete-mobile">
              <img src="@/assets/sources/icons/logo.svg" alt="Logo" class="img-logo">
            </v-sheet>
            <h5 class="mb-4 show-mobile">Login here</h5>
            <!-- <p class="font300 color-grey">Please enter your login details</p> -->
            <v-row>
              <!-- <v-col cols="12">
                <label for="email-address">Email address</label>
                <v-text-field id="email-address" class="input" variant="outlined" elevation="0" placeholder="Enter email address"></v-text-field>
              </v-col> -->

              <!-- <v-col cols="12">
                <label for="password">Password</label>
                <v-text-field
                id="password" class="input" variant="outlined" elevation="0" 
                :append-inner-icon="show_password ? 'mdi-eye-outline' : 'mdi-eye-off-outline'"
                :type="show_password ? 'text' : 'password'"
                placeholder="Enter your password"
                @click:append-inner="show_password = !show_password"
                ></v-text-field>
              </v-col> -->

              <!-- <span style="color: #667085; font-weight: 700;" class="ml-4">
                <img src="@/assets/sources/icons/help-octagon.svg" alt="Help Octagon" class="help-octagon"> Forgot your password
              </span> -->

              <v-col cols="12">
                <v-btn class="center btn2" @click="loginII">Login with Internet Identity <img src="@/assets/sources/icons/internet-computer-icon.svg" alt="IC icon" class="ic-icon"></v-btn>
              </v-col>

              <!-- <v-col cols="12">
                <v-btn class="center btn" @click="windowStep = 2; $router.push(basePath('/dashboard'))">Log in <v-icon style="margin-bottom: -3px; margin-left: 5px;">mdi-login</v-icon></v-btn>
              </v-col> -->
            </v-row>
          </v-card>
        </div>
      </v-window-item>

      <!-- Verification Email -->
      <v-window-item :value="2">
        <div class="container-windows-step code">
          <v-card class="card ml-2 card-register pt-10 pb-10">
            <v-sheet class="sheet-img mb-6">
              <img src="@/assets/sources/icons/logo.svg" alt="Logo" class="img-logo">
            </v-sheet>
            <h5 class="mb-1">2-factor verification</h5>
            <p class="font300 color-grey">Please enter security code you received on your email</p>
            
            <v-row>
              <v-col cols="12" class="jstart astart divcol">
                <label for="otp" style="font-weight: 500; color: #000;">Secure Code</label>
                <v-otp-input id="otp"></v-otp-input>
              </v-col>

              <v-col cols="12">
                <v-btn class="btn2">Resend Code</v-btn>
              </v-col>
            </v-row>
          </v-card>
        </div>
      </v-window-item>
    </v-window>
  </div>
</template>

<script>
import '@/assets/styles/pages/login.scss'
import { ClientAuthApi } from '@/repository/auth-client-api'
import { ICP_PROVIDE_COLLECTION } from '@/services/icp-provider'
import { ref, inject } from 'vue'
import variables from '@/mixins/variables'

export default {
  setup() {
    const
      { basePath } = variables,
      client = inject(ICP_PROVIDE_COLLECTION.authClient),
      clientAuthApi = new ClientAuthApi({ client })

    return {
      basePath,
      clientAuthApi,
      windowStep: ref(1),
      show_password: ref(false)
    }
  },
  beforeMount() {
    this.logoutII()
  },
  methods: {
    loginII() {
      this.clientAuthApi.signIn(() => this.$router.push(basePath('/')))
    },
    logoutII() {
      this.clientAuthApi.signOut()
    }
  }
}
</script>
