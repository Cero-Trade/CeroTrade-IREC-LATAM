<template>
  <div class="v-avatar-upload">
    <input ref="file" type="file" accept="image/*" class="d-none" @change="handleLoadFile">

    <v-icon
      class="v-avatar-upload__icon"
      icon="mdi-pencil"
      :size="iconSize"
      :color="iconColor"
      :style="`--icon-size: ${isOnlyDigits(iconSize) ? `${iconSize}px` : iconSize}`"
      @click="file.click()"
    />

    <v-img
      :src="localSrc ?? src"
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
      class="v-avatar-upload__image"
      :style="`
        --border-radius: ${!!rounded ?
            isOnlyDigits(rounded) ? `${rounded}px` : rounded
            : '50%'};
        --border: ${border};
        --box-shadow: ${boxShadow};
      `"
      @click="file.click()"
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
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { getUrlFromFile, isOnlyDigits } from '@/plugins/functions'

defineProps({
  src: String,
  alt: String,
  aspectRatio: Number,
  contentClass: String,
  cover: Boolean,
  eager: Boolean,
  gradient: String,
  height: String,
  maxHeight: String,
  maxWidth: String,
  minHeight: String,
  minWidth: String,
  sizes: String,
  width: String,
  options: Object,
  transition: String,
  inline: Boolean,
  lazySrc: String,
  stopLoading: Boolean,
  rounded: String,
  border: String,
  colorLoader: String,
  iconColor: String,
  iconSize: {
    type: [String, Number],
    default: "20px"
  },
  boxShadow: String,
})

const
file = ref(),
localSrc = ref()

defineExpose({ localSrc })

function handleLoadFile(event: any) {
  const file = event.target.files[0]
  localSrc.value = getUrlFromFile(file)
}
</script>

<style lang="scss">
.v-avatar-upload {
  position: relative;
  width: max-content;

  &:hover .v-avatar-upload__icon {
    transform: translateX(calc(var(--icon-size) + 10px));
    opacity: 1;
  }

  &__icon {
    position: absolute;
    top: 0;
    bottom: 0;
    margin: auto;
    right: 0;
    opacity: 0;

    transition: .4s cubic-bezier(0.445, 0.05, 0.55, 0.95);
  }

  &__image {
    .v-image__image {
      border-radius: var(--border-radius);
      border: var(--border);
      box-shadow: var(--box-shadow);
    }
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
