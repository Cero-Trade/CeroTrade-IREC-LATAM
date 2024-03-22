<template>
  <apexchart type="bar" :height="height" :options="options" :series="series" />
</template>

<script setup>
import Apexchart from "vue3-apexcharts"

const
  props = defineProps({
    height: String,
    series: {
      type: Array,
      default: undefined
    }
  }),

options = {
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
      columnWidth: '70%',
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
    categories: ['Wind', 'Solar', 'Biomass', 'Geothermal', 'Hydro', 'Ocean'],
      floating: true,
      position: 'bottom',
      labels: { 
        show: true,
        rotate: -90,
        rotateAlways: true,
        style: {
            fontSize: '12px',
            fontFamily: 'Grotesk, sans-serif',
            fontWeight: 700,
            cssClass: 'apexcharts-xaxis-label',
        },
        offsetX: 0,
        offsetY: -80,
      },
  },
  dataLabels: {
    enabled: false
  },
  legend: {
    show: false,
  },
}
</script>

<style lang="scss">
.apexcharts-xaxis-label {
}
</style>
