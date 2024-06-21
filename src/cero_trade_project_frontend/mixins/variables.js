import axios from "axios"
import store from "@/store"
import { useStorage } from "vue3-storage-secure"
import { useTheme } from "vuetify/lib/framework.mjs"
import { formatBytes } from "@/plugins/functions"
import { computed } from "vue"

export default {
  // ? custom defines
  globalRules: {
    required: (v) => !!v || "Field required",
    requiredNumber: (v) => {
      if (!v || v <= 0) return 'Field required'
      return true
    },
    listRequired: (v) => !!v?.length || "Field required",
    email: (v) => {
      const pattern = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
      return pattern.test(v) || 'Invalid email.'
    },
    limitFileSize: (v, s) => {
      if (!v?.length) return true
      else if (v[0].size > s) return `Max file size is ${formatBytes(s)}`

      return true
    },
    principalId: (v) => /^[a-zA-Z0-9]{3,5}(-[a-zA-Z0-9]{3,5}){10}$/.test(v) || 'Invalid principal id'
  },
  dateFormat: 'YYYY-MM-DDTHH:mm:ss.sssssssssZ',
  // amount in e8s equal to 1 ICP
  e8sEquivalence: Number(process.env.E8S_EQUIVALENCE),
  ceroComisison: Number(process.env.CERO_COMISSION),
  isProduction: process.env.NODE_ENV === 'production',
  beneficiaryUrl: computed(() => `${process.env.NODE_ENV === 'production' ? 'https://z2mgf-dqaaa-aaaak-qihbq-cai.icp0.io' : 'http://localhost:5173'}/auth/register?canisterId=z2mgf-dqaaa-aaaak-qihbq-cai&beneficiary=${store.state.profile?.principalId.toString()}`),

  isSafari: /^((?!chrome|android).)*safari/i.test(navigator.userAgent),
  isLogged() {
    return !!useStorage().getStorageSync('tokenAuth')
  },
  profile() {
    return store.state.profile
  },
  baseDomainPath() {
    return axios.defaults.baseURL
  },
  getTheme() {
    return useTheme().name
  },
  getThemeSrc() {
    return `@/assets/sources/themes/${useTheme().name}/`
  },

  //?  life cycle
  // mounted() {},
}
