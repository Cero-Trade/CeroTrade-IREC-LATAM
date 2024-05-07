<template>
  <section
    class="full-screen"
    :style="`
      height: ${isOnlyDigits(height) ? `${height}px` : height};
      background: ${color};
      padding: ${isOnlyDigits(padding) ? `${padding}px` : padding};
      padding-inline: ${isOnlyDigits(paddingInline) ? `${paddingInline}px` : paddingInline};
      padding-block: ${isOnlyDigits(paddingBlock) ? `${paddingBlock}px` : paddingBlock};
    `"
  >
    <div
      class="full-screen__wrapper"
      :class="contentClass"
      :style="`
        max-width: ${isOnlyDigits(maxWidth) ? `${maxWidth}px` : maxWidth};
        background: ${contentColor};
        ${contentStyle}
      `"
    >
      <slot />
    </div>
  </section>
</template>

<script setup lang="ts">
import { isOnlyDigits } from '@/plugins/functions'

defineProps({
  color: String,
  maxWidth: [String, Number],
  height: [String, Number],
  padding: [String, Number],
  paddingInline: [String, Number],
  paddingBlock: [String, Number],
  contentColor: String,
  contentClass: String,
  contentStyle: String,
})
</script>
