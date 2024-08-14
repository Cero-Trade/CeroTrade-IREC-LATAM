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
      <v-card-title class="text-center">
        Do you want to approve transaction?
      </v-card-title>

      <v-divider></v-divider>

      <v-card-text>
        <p>
          You must approve to spend {{ totalInICP }} ICP from token canister
        </p>
      </v-card-text>

      <v-card-actions>
        <v-btn
          class="bg-tertiary text-white flex-grow-1"
          :disabled="loading"
          @click="hasCancelEmit ? emit('decline', modelParameter) : model = false"
        >Decline</v-btn>

        <v-btn
          class="bg-primary text-black flex-grow-1"
          :disabled="loading"
          @click="approve"
        >Approve</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</template>

<script setup>
import { ref, computed, watch, getCurrentInstance } from 'vue'
import { useToast } from 'vue-toastification';
import variables from '@/mixins/variables'
import { LedgerCanister } from '@/repository/ledger-canister';
import { convertE8SToICP, convertICPToE8S } from '@/plugins/functions'

const
  props = defineProps({
    fullscreen: Boolean,
    activator: String,
    persistent: Boolean,
    contentClass: String,
    tokenId: String,
    amountInIcp: {
      type: Number,
      default: 0
    },
    feeTxInE8s: {
      type: Number,
      default: 20_000
    },
    maxWidth: {
      type: String,
      default: "350"
    },
  }),
  emit = defineEmits(['approve', 'close', 'decline']),
  instance = getCurrentInstance(),
  toast = useToast(),
  { ceroComisison } = variables,

model = ref(false),
modelParameter = ref(null),
loading = ref(false),
hasCancelEmit = !!instance?.vnode.props?.onCancel,

tokenId = computed(() => props.tokenId),
totalInICP = computed(() => convertE8SToICP(convertICPToE8S(props.amountInIcp) + props.feeTxInE8s + ceroComisison)),
totalInE8S = computed(() => convertICPToE8S(props.amountInIcp) + props.feeTxInE8s + ceroComisison)

function showModal(parameter) {
  modelParameter.value = parameter
  model.value = true
}

defineExpose({ model, showModal })

watch(model, (value) => {
  if (!value) emit('close', modelParameter.value)
})


async function approve() {
  loading.value = true

  try {
    const txBlock = await LedgerCanister.approveICPFromToken({
      tokenId: tokenId.value,
      amount: { e8s: totalInE8S.value },
    })
    console.log(txBlock);

    loading.value = false
    model.value = false
    toast.info(`You have approved to spend ${totalInICP.value} ICP`)

    emit('approve', modelParameter.value)
  } catch (error) {
    loading.value = false
    toast.error(error)
  }
}
</script>
