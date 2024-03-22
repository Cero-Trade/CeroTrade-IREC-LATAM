<template>
</template>

<script setup>
import { useCanister } from "@connect2ic/vue"
const
[user] = useCanister("user"),
[user_index] = useCanister("user_index"),
[token] = useCanister("token"),
[token_index] = useCanister("token_index"),
[agent] = useCanister("agent"),
[marketplace] = useCanister("marketplace")

setTimeout(async () => {
  // example test
  // console.log("testing", await user.value.getWallet());
}, 1000)

</script>