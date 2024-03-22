// styles
import '@/assets/styles/main.scss'

// Components
import App from './app.vue'

// Composables
import { createApp } from 'vue'

// Plugins
import { registerPlugins } from './plugins'

const app = createApp(App)

registerPlugins(app)

app.mount('#app')
