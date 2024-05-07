<template>
  <v-dialog
    v-model="store.state.loader"
    persistent
    max-width="300"
  >
    <v-card class="bg-primary">
      <v-card-text>
        Loading...
        <v-progress-linear
          indeterminate
        ></v-progress-linear>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { useStore } from 'vuex';
const store = useStore()
</script>
