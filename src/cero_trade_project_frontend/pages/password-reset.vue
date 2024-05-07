<template>
  <div id="password-reset">
    <img src="@/assets/sources/images/side-img-3.png" alt="Side banner" class="side-banner">
    <v-window v-model="windowStep" :show-arrows="false">
      <!-- registration -->
      <v-window-item :value="1">
        <div class="container-windows-step">
          <v-card class="card ml-2 card-register">
            <v-sheet class="sheet-img mb-6">
              <img src="@/assets/sources/icons/logo.svg" alt="Logo" class="img-logo">
            </v-sheet>
            <h5 class="mb-1">Password reset</h5>
            <p class="font300 color-grey">Enter your email for password reset</p>
            <v-row>
              <v-col cols="12">
                <label for="email-address">Email address</label>
                <v-text-field id="email-address" class="input" variant="outlined" elevation="0" placeholder="Enter email address"></v-text-field>
              </v-col>

              <v-col cols="12">
                <v-btn class="center btn" @click="windowStep = 2">Reset your password</v-btn>
              </v-col>
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
            <h5 class="mb-1">Please verify your email</h5>
            <p class="font300 color-grey">Please enter security code you received on your email</p>
            
            <v-row>
              <v-col cols="12" class="jstart astart divcol">
                <label for="otp" style="font-weight: 700; color: #000;">Secure Code</label>
                <v-otp-input id="otp"></v-otp-input>
              </v-col>

              <v-col cols="12">
                <v-btn class="btn2">Resend Code</v-btn>
              </v-col>
            </v-row>
          </v-card>
        </div>
      </v-window-item>

      <!-- Change Password -->
      <v-window-item :value="3">
        <div class="container-windows-step">
          <v-card class="card ml-2 card-register">
            <v-sheet class="sheet-img mb-6">
              <img src="@/assets/sources/icons/logo.svg" alt="Logo" class="img-logo">
            </v-sheet>
            <h5 class="mb-1">Password reset</h5>
            <p class="font300 color-grey">Enter your new password</p>
            <v-row>
              <v-col cols="12">
                <label for="password">New Password</label>
                <v-text-field
                id="confirm-password" class="input" variant="outlined" elevation="0" 
                :append-inner-icon="show_password ? 'mdi-eye-outline' : 'mdi-eye-off-outline'"
                :type="show_password ? 'text' : 'password'"
                @click:append-inner="show_password = !show_password"
                placeholder="Enter your password"
                ></v-text-field>
              </v-col>
              <v-col cols="12">
                <label for="confirm-password">Confirm password</label>
                <v-text-field
                id="confirm-password" class="input" variant="outlined" elevation="0" 
                :append-inner-icon="show_password ? 'mdi-eye-outline' : 'mdi-eye-off-outline'"
                :type="show_password ? 'text' : 'password'"
                @click:append-inner="show_password = !show_password"
                placeholder="Enter your password"
                ></v-text-field>
              </v-col>

              <v-col cols="12">
                <v-btn class="center btn" @click="windowStep = 2">Reset your password</v-btn>
              </v-col>
            </v-row>
          </v-card>
        </div>
      </v-window-item>
    </v-window>
  </div>
</template>

<script>
import '@/assets/styles/pages/password-reset.scss'

export default {
  data(){
    return{
      windowStep: 3,
      show_password: false,
    }
  },
}
</script>