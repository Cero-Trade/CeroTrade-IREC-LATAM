<template>
  <div id="app-loader">
    <div class="loader"><div></div><div></div></div>
  </div>
</template>

<style scoped lang="scss">
#app-loader {
  display: grid;
  place-content: center;
  height: 100dvh;

  .loader {
    color: #C6F221
  }

  .loader,
  .loader div {
    box-sizing: border-box;
  }
  .loader {
    display: inline-block;
    position: relative;
    width: 80px;
    height: 80px;
  }
  .loader div {
    position: absolute;
    border: 4px solid currentColor;
    opacity: 1;
    border-radius: 50%;
    animation: loader 1s cubic-bezier(0, 0.2, 0.8, 1) infinite;
  }
  .loader div:nth-child(2) {
    animation-delay: -0.5s;
  }
  @keyframes loader {
    0% {
      top: 36px;
      left: 36px;
      width: 8px;
      height: 8px;
      opacity: 0;
    }
    4.9% {
      top: 36px;
      left: 36px;
      width: 8px;
      height: 8px;
      opacity: 0;
    }
    5% {
      top: 36px;
      left: 36px;
      width: 8px;
      height: 8px;
      opacity: 1;
    }
    100% {
      top: 0;
      left: 0;
      width: 80px;
      height: 80px;
      opacity: 0;
    }
  }
}
</style>