<template>
</template>

<script setup>
import { useWallet, useBalance } from "@connect2ic/vue"
import { watch, onMounted } from "vue";
const
  [wallet] = useWallet(),
  [assets] = useBalance()

watch(wallet, (value) => console.log("wallet", value))
watch(assets, (value) => console.log("assets", value))

onMounted(getData)

function getData() {
  console.log("wallet", wallet.value)
  console.log("assets", assets.value)
}
</script>
