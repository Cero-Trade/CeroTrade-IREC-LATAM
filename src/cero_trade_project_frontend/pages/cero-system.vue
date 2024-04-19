<template>
  <div class="d-flex flex-column align-center mt-10">
    <p>Must to provide a valid wasm module like [number] format copied to clipboard</p>

    <v-btn class="mb-4" @click="generateWasmModule('users')">Generate USERS Wasm Module</v-btn>
    <v-btn @click="generateWasmModule('transactions')">Generate TRANSACTIONS Wasm Module</v-btn>
    <v-btn @click="generateWasmModule('token')">Generate TOKEN Wasm Module</v-btn>
  </div>
</template>

<script setup>
import { CeroSystemApi } from '@/repository/cero-system-api';
import { useToast } from 'vue-toastification';

const toast = useToast()

async function generateWasmModule(input) {
  let moduleName = {};
  moduleName[input] = input

  try {
    const wasmModule = await navigator.clipboard.readText()

    await CeroSystemApi.generateWasmModule(moduleName, JSON.parse(wasmModule))
    toast.success("Module updated")
  } catch (error) {
    toast.error(error)
  }
}
</script>
