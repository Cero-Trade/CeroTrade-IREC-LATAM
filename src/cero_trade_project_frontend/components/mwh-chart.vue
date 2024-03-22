<template>
  <apexchart type="area" :height="height" :options="options" :series="series" />
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
    height: 80,
    type: 'area'
  },
  dataLabels: {
    enabled: false
  },
  stroke: {
    curve: 'straight',
    colors: ['#00555B'] 
  },
  xaxis: {
    type: 'datetime',
    categories: ["2018-09-19T00:00:00.000Z", "2018-09-19T01:30:00.000Z", "2018-09-19T02:30:00.000Z", "2018-09-19T03:30:00.000Z", "2018-09-19T04:30:00.000Z", "2018-09-19T05:30:00.000Z", "2018-09-19T06:30:00.000Z", "2018-09-19T07:30:00.000Z", "2018-09-19T08:00:00.000Z", "2018-09-19T08:30:00.000Z", "2018-09-19T09:00:00.000Z", "2018-09-19T09:30:00.000Z", "2018-09-19T10:00:00.000Z", "2018-09-19T10:30:00.000Z"],
    labels: {
      show: false
    },
    axisBorder: {
      show: false
    }
  },
  yaxis: {
    labels: {
      show: false 
    }
  },
  grid: {
    show: false
  },
}
</script>
