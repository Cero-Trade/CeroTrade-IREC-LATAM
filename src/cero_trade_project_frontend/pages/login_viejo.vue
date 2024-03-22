<template>
  <section id="login">
    <img src="@/assets/sources/logos/logo.svg" style="width: min(450px, 100%)">

    <v-form v-model="validForm">
      <v-text-field
        v-model="dataLogin.email"
        variant="solo"
        placeholder="Correo electronico"
        append-inner-icon="mdi-email"
        :rules="[globalRules.email]"
        @keydown="e => {
          if (e.key !== 'Enter') return
          passwordInput.focus()
        }"
      ></v-text-field>

      <v-text-field
        ref="passwordInput"
        v-model="dataLogin.password" solo
        variant="solo"
        placeholder="Contraseña"
        :type="showPassword ? 'text' : 'password'"
        :append-inner-icon="showPassword ? 'mdi-eye-off' : 'mdi-eye'"
        :rules="[rules.password]"
        @click:appendInner="showPassword = !showPassword"
        @keydown="e => {
          if (e.key !== 'Enter') return
          handleLogin()
        }"
      ></v-text-field>

      <div class="flex-space-center">
        <v-checkbox
          v-model="rememberMe"
          label="Recuérdame"
          density="compact"
          hide-details
          color="rgb(var(--v-theme-primary))"
          class="flex-grow-0"
        >
          <template #input="{ model }">
            <img
              :src="model.value ? checkboxCheckedIcon : checkboxBaseIcon"
              alt="checkbox icon"
              style="width: 22px"
              @click="model.value = !model.value"
            >
          </template>
        </v-checkbox>

        <a class="text-end">¿Olvidaste tu contraseña?</a>
      </div>

      <v-btn
        class="my-2 bg-primary"
        :disabled="!validForm"
        :loading="isLoading"
        @click="handleLogin()"
      >Iniciar Sesión</v-btn>
      
      <v-btn
        class="bg-secondary"
        @click="handleRegister()"
      >Registrarse</v-btn>
    </v-form>
  </section>
</template>

<script setup>
import '@/assets/styles/pages/login.scss'
import checkboxCheckedIcon from '@/assets/sources/icons/checkbox-checked.svg'
import checkboxBaseIcon from '@/assets/sources/icons/checkbox-base.svg'
import variables from '@/mixins/variables';
import AuthApi from '@/repository/auth_api';
import { onBeforeMount, ref } from 'vue';
import { useRouter } from 'vue-router';
import { useToast } from "vue-toastification";
import { useStorage } from 'vue3-storage-secure';
const
  toast = useToast(),
  storage = useStorage(),
  router = useRouter(),
  { globalRules } = variables,

validForm = ref(false),
isLoading = ref(false),
rememberMe = ref(false),
showPassword = ref(false),
dataLogin = ref({
  email: undefined,
  password: undefined,
}),
rules = {
  password: (v) => /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%&*-]).{6,}$/.test(v)
    || 'La contraseña debe tener al menos una mayúscula, una minúscula, un número y un caracter especial',
},
passwordInput = ref(null)


onBeforeMount(() => {
  if (storage?.getStorageSync("tokenAuth"))
    storage.removeStorageSync("tokenAuth")

  const rmEmail = storage?.getStorageSync('rmEmail')
  if (rmEmail) {
    dataLogin.value.email = rmEmail
    rememberMe.value = true
  }
})


async function handleLogin() {
  if (isLoading.value || !validForm.value) return
  isLoading.value = true

  await AuthApi.signIn(dataLogin.value)
    .catch(_ => { return isLoading.value = false })

  if (!rememberMe.value) storage?.removeStorageSync('rmEmail')
  else storage?.setStorageSync('rmEmail', dataLogin.value.email)

  toast.success('Sign in successful!')
  router.push('/')
}

function handleRegister() {
  router.push('/register')
}
</script>
