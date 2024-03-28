import axios from "axios"
import store from "@/store"
import { useStorage } from "vue3-storage-secure"
import { useTheme } from "vuetify/lib/framework.mjs"
import { canisterImpl } from '@/services/icp-provider';

export default {
  // ? custom defines
  globalRules: {
    required: (v) => !!v || "Field required",
    listRequired: (v) => !!v?.length || "Field required",
    email: (v) => {
      const pattern = /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/
      return pattern.test(v) || 'Invalid email.'
    },
  },
  isProduction: process.env.NODE_ENV === 'production',

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
