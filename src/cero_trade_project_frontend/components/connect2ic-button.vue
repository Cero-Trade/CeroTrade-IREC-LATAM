<template>
  <ConnectButton />
  <ConnectDialog />
</template>

<script setup>
import "@connect2ic/core/style.css"
import icIcon from '@/assets/sources/icons/internet-computer-icon.svg'
import { ConnectButton, ConnectDialog } from "@connect2ic/vue"
import { onMounted } from 'vue'
const connectButtonRef = '.connect-button'

onMounted(connectButtonStyles)

function connectButtonStyles() {
  const connectButton = document.querySelector(connectButtonRef)

  // update styles
  connectButton.className = "connect-button .v-btn btn2 center"

  // update html
  const innerText = connectButton.textContent.trim() !== 'Disconnect' ? 'Login with Internet Identity' : connectButton.textContent
  connectButton.innerHTML = `<span class="center">${innerText} <img src=${icIcon} alt="IC icon" class="ic-icon"></span>`
}
</script>