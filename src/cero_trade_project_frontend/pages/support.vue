<template>
  <div id="support">
    <span class="mb-4 acenter span-navigation">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" class="icon-img">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span class="green-span">Support</span>
    </span>
    <h3 class="bold">Support</h3>
    <span class="mbb16 mb-6 grey-span" style="max-width: 774px">
      Get in touch with us. We will support you in any issues you might be facing.
    </span>

    <v-card class="card divcol mb-4 card-bg-diferent">
      <h5>Quick links</h5>
      <span class="mb-2 green-span font12 d-flex flex-acenter">
        <img src="@/assets/sources/icons/file.svg" alt="file icon" class="mr-2">
        Documentation
      </span>
    </v-card>

    <v-card class="card divcol mb-4" style="min-height: 100px!important; max-width: 300px!important;">
      <h5>Contact information</h5>
      <span class="mb-2 bold green-span font12 d-flex flex-acenter">
        <img src="@/assets/sources/icons/phone-call.svg" alt="phone-call icon" class="mr-2">
        +56 9 5616 0626
      </span>
      <span class="mb-2 bold green-span font12 d-flex flex-acenter">
        <img src="@/assets/sources/icons/mail.svg" alt="phone-call icon" class="mr-2">
        valentina@cerotrade.cl
      </span>
      <span class="mb-2 bold green-span font12 d-flex flex-acenter">
        <img src="@/assets/sources/icons/mail.svg" alt="phone-call icon" class="mr-2">
        joaquin@cerotrade.cl
      </span>
    </v-card>
  </div>
</template>

<script>
import '@/assets/styles/pages/support.scss'

export default{
  setup(){


    return{

    }
  },

  methods:{

  }
}
</script>