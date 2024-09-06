<template>
  <v-dialog
    v-model="model"
    :fullscreen="fullscreen"
    :max-width="maxWidth"
    :activator="activator"
    :content-class="contentClass"
    :persistent="persistent"
  >
    <v-card :loading="loading">
      <v-card-title :class="{'text-center': titleCenter}">
        <slot name="title">{{ title }}</slot>
      </v-card-title>

      <v-divider v-if="showDivider"></v-divider>

      <v-card-text>
        <slot>
          <p>{{ content }}</p>
        </slot>
      </v-card-text>

      <v-card-actions v-if="!hideActions">
        <v-btn
          class="bg-tertiary text-white flex-grow-1"
          @click="hasCancelEmit ? emit('cancel', modelParameter) : model = false"
        >{{ cancelButtonText }}</v-btn>

        <v-btn
          class="bg-primary text-black flex-grow-1"
          :disabled="disabled || loading"
          @click="emit('accept', modelParameter)"
        >{{ confirmButtonText }}</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { ref, watch, getCurrentInstance } from 'vue'

defineProps({
  fullscreen: Boolean,
  activator: String,
  persistent: Boolean,
  title: String,
  content: String,
  confirmButtonText: {
    type: String,
    default: 'Accept'
  },
  cancelButtonText: {
    type: String,
    default: 'Cancel'
  },
  contentClass: String,
  loading: Boolean,
  disabled: Boolean,
  showDivider: Boolean,
  titleCenter: Boolean,
  maxWidth: {
    type: String,
    default: "350"
  },
  hideActions: Boolean,
})

const
  emit = defineEmits(['accept', 'close', 'cancel']),
  instance = getCurrentInstance(),

model = ref(false),
modelParameter = ref(null),
hasCancelEmit = !!instance?.vnode.props?.onCancel

function showModal(parameter) {
  modelParameter.value = parameter
  model.value = true
}

defineExpose({ model, showModal })


watch(model, (value) => {
  if (!value) emit('close', modelParameter.value)
})
</script>
