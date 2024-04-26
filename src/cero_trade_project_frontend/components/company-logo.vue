<template>
  <v-badge
    :model-value="!!countrySrc"
    color="#fff"
    location="bottom right"
    class="company-logo"
    :offset-x="badgeOffset"
    :offset-y="badgeOffset"
  >
    <v-img-load
      :src="energySrc"
      :sizes="energySizes"
      rounded="50%"
      border="2px solid #000"
      cover
      class="flex-grow-0"
    ></v-img-load>

    <template #badge>
      <v-img-load
        :src="countrySrc"
        :sizes="countrySizes"
        rounded="50%"
        cover
        class="flex-grow-0"
      ></v-img-load>
    </template>
  </v-badge>
</template>

<script setup>
defineProps({
  energySrc: String,
  energySizes: {
    type: String,
    default: "40px"
  },
  countrySrc: String,
  countrySizes: {
    type: String,
    default: "20px"
  },
  badgeOffset: {
    type: [Number, String],
    default: 8
  }
})
</script>

<style lang="scss">
.company-logo {
  .v-badge__wrapper > .v-img-load .v-img__img {
    padding: 5px;
  }

  .v-badge__badge {
    min-width: var(--energy-badge-sizes) !important;
    max-width: var(--energy-badge-sizes) !important;
    width: var(--energy-badge-sizes) !important;
    min-height: var(--energy-badge-sizes) !important;
    max-height: var(--energy-badge-sizes) !important;
    height: var(--energy-badge-sizes) !important;
    border-radius: 50% !important;
    border: 2px solid #dedede !important;
    padding: 0px !important
  }
}
</style>
