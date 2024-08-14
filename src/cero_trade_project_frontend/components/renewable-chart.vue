<template>
  <apexchart type="bar" :height="height" :options="options" :series="series" />
</template>

<script setup>
import { computed } from "vue";
import Apexchart from "vue3-apexcharts"

const
  props = defineProps({
    height: String,
    categories: {
      type: Array,
      default: []
    },
    series: {
      type: Array,
      default: []
    }
  }),

totalLength = 6,
series = computed(() => props.series),
categories = computed(() => props.categories),
options = computed(() => ({
  chart: {
    type: 'bar',
    height: 200,
    stacked: true,
    toolbar: {
      show: false
    },
    zoom: {
      enabled: true
    }
  },
  colors: ['#C6F221'],
  dataLabels: {
    enabled: true,
    position: 'center', // Centra el texto dentro de la barra
    orientation: 'vertical', // Orientación vertical
    textAnchor: 'middle', // Alinea el texto al centro verticalmente
    offsetY: 0,
    style: {
      fontSize: '12px', // Tamaño del texto
      fontWeight: 700,
      colors: ['#ffffff'] // Color del texto (puedes ajustar según tus necesidades)
    }
  },
  
  plotOptions: {
    bar: {
      horizontal: false,
      borderRadius: 10,
      columnWidth: '52px',
      borderRadiusWhenStacked: 'all',
      colors: {
        backgroundBarColors: ['#F2F4F7'],
        backgroundBarOpacity: 1,
        backgroundBarRadius: 10,
      },
      dataLabels: {
        enabled: false,
      }
    },
  },
  yaxis: {
    show: false,
  },
  xaxis: {
    type: 'category',
    categories: categories.value,
    floating: true,
    position: 'bottom',
    labels: {
      show: categories.value.length,
      rotate: -90,
      rotateAlways: true,
      style: {
          fontSize: '12px',
          fontFamily: 'Grotesk, sans-serif',
          fontWeight: 700,
          cssClass: 'apexcharts-xaxis-label',
      },
      offsetX: 0,
      offsetY: -100,
    },
  },
  dataLabels: {
    enabled: false
  },
  legend: {
    show: false,
  },
}))
</script>

<style lang="scss">
// .apexcharts-xaxis-label {
// }
</style>
