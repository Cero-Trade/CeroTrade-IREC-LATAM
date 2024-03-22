<template>
  <section id="error-page" class="flex-column-center">
    <h1 class="mb-0 wbol">{{error.title ?? $t("error.title")}}</h1>
    <span class="wbold">{{error.description ?? $t("error.description")}}</span>
    <v-btn :to="error.to" class="wbold text-white">{{error.button ?? $t("error.button")}}</v-btn>
  </section>
</template>

<script setup>
import '@/assets/styles/pages/error.scss'
defineProps({
  error: {
    type: Object,
    default:() => ({
      title: undefined,
      description: undefined,
      button: undefined,
      to: "/",
    }),
  },
})
</script>
