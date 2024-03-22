<template>
  <v-img
    :src="src"
    :alt="alt"
    :aspect-ratio="aspectRatio"
    :content-class="contentClass"
    :cover="cover"
    :eager="eager"
    :gradient="gradient"
    :height="sizes ?? height"
    :max-height="maxHeight"
    :max-width="maxWidth"
    :min-height="minHeight"
    :min-width="minWidth"
    :width="sizes ?? width"
    :options="options"
    :transition="transition"
    :inline="inline"
    :lazy-src="lazySrc"
    class="v-img-load"
    :style="`
      --border-radius: ${isOnlyDigits(rounded) ? `${rounded}px` : rounded};
      --border: ${border};
      --box-shadow: ${boxShadow};
      --background-color: ${bgColor};
    `"
  >
    <template v-if="!lazySrc" #placeholder>
      <v-skeleton-loader
        :boilerplate="stopLoading"
        :color="colorLoader"
        width="100%"
        height="100%"
      ></v-skeleton-loader>
    </template>
  </v-img>
</template>

<script setup>
import { isOnlyDigits } from '@/plugins/functions'

defineProps({
  src: String,
  alt: String,
  aspectRatio: Number,
  contentClass: String,
  cover: Boolean,
  eager: Boolean,
  gradient: String,
  height: [String, Number],
  maxHeight: [String, Number],
  maxWidth: [String, Number],
  minHeight: [String, Number],
  minWidth: [String, Number],
  sizes: String,
  width: String,
  options: Object,
  transition: String,
  inline: Boolean,
  lazySrc: String,
  stopLoading: Boolean,
  rounded: [String, Number],
  border: String,
  colorLoader: String,
  boxShadow: String,
  bgColor: String,
})
</script>

<style lang="scss">
.v-img-load {

  .v-img__img {
    border-radius: var(--border-radius);
    border: var(--border);
    box-shadow: var(--box-shadow);
    background-color: var(--background-color);
  }

  .v-img__placeholder .v-skeleton-loader__bone {
    $size: 100%;
    width: $size;
    min-width: $size;
    max-width: $size;
    height: $size;
    min-height: $size;
    max-height: $size;
    margin: 0;
    border-radius: var(--border-radius);
    border: var(--border);
  }
}
</style>
