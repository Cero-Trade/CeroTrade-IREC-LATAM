<template>
  <app-loader v-if="store.state.appLoader" />

  <v-app v-else id="layout">
    <v-main>
      <Navbar></Navbar>
      <router-view  />
    </v-main>
  </v-app>
</template>

<script setup>
import '@/assets/styles/layouts/default-layout.scss'
import Navbar from '@/components/navbar.vue'
import AppLoader from '../app-loader.vue'
import { onBeforeMount } from 'vue'
import { setAppLoader } from '../plugins/functions';
import { AgentCanister } from '../repository/agent-canister';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useToast } from 'vue-toastification';
const
  store = useStore(),
  router = useRouter(),
  toast = useToast()


onBeforeMount(getData)


async function getData() {
  try {
    await AgentCanister.getProfile()

    setAppLoader(false)
  } catch (error) {
    console.error(error);
    router.push('/auth/login')
  }
}
</script>
