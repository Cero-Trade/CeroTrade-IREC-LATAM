<template>
  <v-dialog v-model="model" persistent>
    <v-card class="card card-dialog-company" style="width: min(100%, 600px) !important">
      <img src="@/assets/sources/icons/close.svg" alt="close icon" class="close" @click="model = false">
      <v-sheet class="mb-10 double-sheet">
        <v-sheet>
          <img src="@/assets/sources/icons/credit-card.svg" alt="credit-card icon">
        </v-sheet>
      </v-sheet>
      <h5>Bank transfer details</h5>

      <div class="divrow mt-6" style="gap: 10px;">
        <v-btn class="btn" style="background-color: #fff!important;"  @click="model = false">
          Cancel
          <img src="@/assets/sources/icons/close.svg" alt="close" style="width: 15px">
        </v-btn>
        <v-btn class="btn" @click="model = false;" style="border: none!important;">
          Confirm
          <img src="@/assets/sources/icons/check-simple.svg" alt="check icon">
        </v-btn>
      </div>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { ref } from 'vue'
const
model = ref(false)


defineExpose({ model })
</script>

<style lang="scss">
</style>
