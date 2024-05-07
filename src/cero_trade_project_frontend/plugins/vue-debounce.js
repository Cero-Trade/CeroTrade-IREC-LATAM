import { vue3Debounce } from 'vue-debounce'

export default (app) => app
  .directive('debounce', vue3Debounce({
    lock: false,
    // listenTo: 'keyup',
    // defaultTime: '300ms',
    // fireOnEmpty: false,
    // trim: false
  }))
