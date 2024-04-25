<template>
  <v-badge
      :model-value="!hideCountryBadge"
      color="#fff"
      location="top left"
      :style="`--energy-badge-sizes: ${energySizes}; --country-badge-sizes: ${countrySizes}`"
      class="company-logo country-badge"
      :offset-x="badgeOffset"
      :offset-y="badgeOffset"
  >
    <v-badge
      :model-value="!hideEnergyBadge"
      color="#fff"
      location="bottom right"
      class="energy-badge"
      :offset-x="badgeOffset"
      :offset-y="badgeOffset"
    >
      <v-img-load
        :src="src"
        :sizes="sizes"
        rounded="50%"
        cover
        class="flex-grow-0"
      ></v-img-load>

      <template #badge>
        <v-img-load
          :src="energySrc"
          :sizes="energySizes"
          rounded="50%"
          cover
          class="flex-grow-0"
        ></v-img-load>
      </template>
    </v-badge>

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
  src: String,
  sizes: {
    type: String,
    default: "40px"
  },
  hideEnergyBadge: Boolean,
  energySrc: String,
  energySizes: {
    type: String,
    default: "24px"
  },
  hideCountryBadge: Boolean,
  countrySrc: String,
  countrySizes: {
    type: String,
    default: "23px"
  },
  badgeOffset: {
    type: [Number, String],
    default: 3
  }
})
</script>

<style lang="scss">
.company-logo {
  &.country-badge .v-badge__badge {
    min-width: var(--country-badge-sizes) !important;
    max-width: var(--country-badge-sizes) !important;
    width: var(--country-badge-sizes) !important;
    min-height: var(--country-badge-sizes) !important;
    max-height: var(--country-badge-sizes) !important;
    height: var(--country-badge-sizes) !important;
    border-radius: 50% !important;
    border: 1px solid #dedede !important;
    padding: 0px !important
  }
  
  .energy-badge .v-badge__badge {
    min-width: var(--energy-badge-sizes) !important;
    max-width: var(--energy-badge-sizes) !important;
    width: var(--energy-badge-sizes) !important;
    min-height: var(--energy-badge-sizes) !important;
    max-height: var(--energy-badge-sizes) !important;
    height: var(--energy-badge-sizes) !important;
    border-radius: 50% !important;
    border: 1px solid #dedede !important;
    padding: 4px !important
  }
}
</style>
