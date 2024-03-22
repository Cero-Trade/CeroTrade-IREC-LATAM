/**
 * plugins/vuetify.js
 *
 * Framework documentation: https://vuetifyjs.com`
 */

// Styles
import 'font-awesome/css/font-awesome.min.css'
import '@mdi/font/css/materialdesignicons.css'

// Composables
import { createVuetify } from 'vuetify'
// import { en, es } from 'vuetify/locale'
import { md3 } from 'vuetify/blueprints'
import { aliases as faAliases, fa } from 'vuetify/iconsets/fa4'
import { aliases as mdiAliases, mdi } from 'vuetify/iconsets/mdi'
import components from './components-import'
import themes from './themes.js'

// https://vuetifyjs.com/en/introduction/why-vuetify/#feature-guides
export default createVuetify({
  theme: {
    defaultTheme: 'light',
    themes: themes,
  },
  // locale: {
  //   locale: 'en',
  //   fallback: 'en',
  //   messages: { en, es },
  // },
  blueprint: md3,
  icons: {
    defaultSet: 'mdi',
    aliases: {
      ...faAliases,
      ...mdiAliases,
    },
    sets: { fa, mdi },
  },
  display: {
    mobileBreakpoint: 'sm',
    thresholds: {
      xs: 430,
      sm: 880,
      md: 1200,
      lg: 1440,
      xl: 1800,
    },
  },
  components: components,
  // Set default config to components
  defaults: {
    global: {},
    VBtn: {
      style: 'text-transform: none; letter-spacing: normal',
      class: 'progress-inside'
    },
    // VOtpInput: {
    //   class: 'padless-inside'
    // }
  }
})
