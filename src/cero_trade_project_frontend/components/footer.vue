<template>
  <v-footer
    id="footer"
    app absolute
    class="flex-center"
  >
    <div id="footer__wrapper">
      <h6 class="text-center">footer</h6>
    </div>
  </v-footer>
</template>

<style scoped lang="scss">
@use '@/assets/styles/main.scss' as *;

#footer {
  transition: 0.5s $ease-return;
  @extend .margin-global;

  &__wrapper {
    @extend .parent;
  }
}
</style>
