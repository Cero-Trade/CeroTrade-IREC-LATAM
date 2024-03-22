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
    height: 250,
    stacked: true,
    toolbar: {
      show: false
    },
    zoom: {
      enabled: true
    }
  },
  colors: ['#00393D', '#00555B', '#EAECF0'],
  responsive: [{
    breakpoint: 480,
    options: {
      legend: {
        position: 'bottom',
        offsetX: -10,
        offsetY: 0
      }
    }
  }],
  plotOptions: {
    bar: {
      horizontal: false,
      borderRadius: 10,
      dataLabels: {
        enabled: false,
      }
    },
  },
  xaxis: {
    type: 'category',
    categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
  },
  legend: {
    show: false,
  },
  dataLabels: {
    enabled: false
  },
  fill: {
    opacity: 1
  }
}
</script>
