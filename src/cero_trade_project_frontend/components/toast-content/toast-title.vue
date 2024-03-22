<template>
  <div class="flex-column">
    <h6 class="mb-2 w500">{{ title }}</h6>
    <p class="mb-0">{{ desc }}</p>
  </div>
</template>

<script setup>
defineProps({
  title: {
    type: String,
    default: "title"
  },
  desc: {
    type: String,
    default: "description"
  },
})
</script>
