<template>
  <v-app id="layout">
    <v-main>
      <Navbar></Navbar>  
      <router-view />
    </v-main>
  </v-app>
</template>

<script setup>
import '@/assets/styles/layouts/default-layout.scss'
import Navbar from '@/components/navbar.vue'
</script>
