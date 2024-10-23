// styles
import '@/assets/styles/settings.scss'
import '@/assets/styles/main.scss'

// Components
import App from './app.vue'

// Composables
import { createApp } from 'vue'

// Plugins
import { registerPlugins } from './plugins'

export const app = createApp(App)

registerPlugins(app)

app.mount('#app')
