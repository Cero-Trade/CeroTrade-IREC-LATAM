<template>
  <v-badge
    :model-value="!!energySrc"
    color="#fff"
    location="bottom right"
    class="company-logo"
    :style="`--badge-padding: ${badgePadding}`"
    :offset-x="badgeOffset"
    :offset-y="badgeOffset"
  >
    <v-img-load
      :src="countrySrc"
      :sizes="countrySizes"
      rounded="50%"
      cover
      class="flex-grow-0"
    ></v-img-load>

    <template #badge>
      <v-img-load
        :src="energySrc"
        :sizes="energySizes"
        bg-color="#fff"
        border="2px solid #dedede"
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
    default: "20px"
  },
  countrySrc: String,
  countrySizes: {
    type: String,
    default: "40px"
  },
  badgeOffset: {
    type: [Number, String],
    default: 8
  },
  badgePadding: {
    type: String,
    default: "5px"
  },
})
</script>

<style lang="scss">
.company-logo {
  .v-badge__wrapper > .v-img-load .v-img__img {
    padding: 0px;
  }

  .v-badge__badge {
    min-width: var(--energy-badge-sizes) !important;
    max-width: var(--energy-badge-sizes) !important;
    width: var(--energy-badge-sizes) !important;
    min-height: var(--energy-badge-sizes) !important;
    max-height: var(--energy-badge-sizes) !important;
    height: var(--energy-badge-sizes) !important;
    border-radius: 50% !important;
    padding: var(--badge-padding) !important
  }
}
</style>
