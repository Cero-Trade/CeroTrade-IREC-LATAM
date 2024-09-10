import { createStore } from 'vuex'
import countries from '@/assets/sources/json/countries.json'
import { getAsset } from '@/plugins/functions'

const store = createStore({
  state: {
    appLoader: true,
    drawer: true,
    loader: false,
    profile: undefined,
    authClient: null,
    countries: {},
  },
  mutations: {
    setAppLoaderState(state, value) { state.appLoader = value },
    setProfile(state, profile) { state.profile = profile },
    setDrawerState(state, value) {
      state.drawer = value
    },
    setLoaderState(state, value) {
      state.loader = value
    },
    setAuthClient(state, value) {
      state.authClient = value
    },
    async setCountries(state) {
      state.countries = countries

      for (const [key, value] of Object.entries(countries)) {
        state.countries[key].flag = getAsset("flags/"+value.code+".png")
      }
    }
  },
  actions: {
    // modalConnect() {
    //   const layout = this.$router.app.$children
    //     .find(data => data.$el === document.getElementById("layout"));

    //   layout.$refs.connect.modalConnect = true
    // },
  },
  getters: {
    pagination: () => ({items, currentPage, itemsPerPage, search, filterA}) => {
      let filters = [...items]
  
      // search
      if (search) filters = filters.filter(data => data.name.includes(search))
      // filter A (tier)
      if (filterA) filters = filters.filter(data => data.tier === filterA)
  
      return filters.slice((currentPage - 1) * itemsPerPage, currentPage * itemsPerPage)
    }
  },
  modules: {},
})

export default store
