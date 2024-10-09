<template>
  <loader />
  <router-view />
</template>

<script setup>
import Loader from '@/components/modals/loader.vue'
import { useStore } from 'vuex';

useStore().commit('setCountries')
</script>
