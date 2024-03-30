import Vue3Storage from "vue3-storage-secure";

export const storageCollection = {
}

export const storageSecureCollection = {
  tokenAuth: 'tokenAuth', // string
}

export default (app) => app.use(Vue3Storage, {
  namespace: process.env.SECURE_STORAGE_NAME_SPACE,
  secureKey: process.env.SECURE_STORAGE_KEY
})
