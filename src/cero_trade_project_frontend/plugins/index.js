// Plugins
import Vue3Storage from './vue3-storage-secure'
import polyfills from './polyfills'
import injects from './injects'
import axiosConfig from './axios'
import directives from './directives'
import vueDebounce from './vue-debounce'
import vuetify from './vuetify'
import router from '../router'
import store from '../store'
import vueI18n from './vue-i18n'
// import { loadFonts } from './webfontloader'
import vueToastification from './vue-toastification'
import googleMaps from './google-maps'

import mixins from './mixins-import'

// Services
import icpProvider from '@/services/icp-provider'

export function registerPlugins (app) {
  // Use principals
  Vue3Storage(app)
  polyfills()
  injects(app)
  axiosConfig(app)
  directives(app)
  vueDebounce(app)

  // Use services
  icpProvider(app)

  // Use plugins
  app
    .use(vuetify)
    .use(router)
    .use(store)


  // Use custom plugins
  // loadFonts()
  vueI18n(app)
  vueToastification(app)
  googleMaps(app)

  mixins(app) // this should be the last one
}
