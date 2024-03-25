<template>
  <div id="market-trends">
    <span class="mb-10 acenter" style="color:#475467 ;font-size: 16px; font-weight: 700;">
      <img src="@/assets/sources/icons/home-layout.svg" alt="Home Icon" style="width: 20px;">
      <img src="@/assets/sources/icons/chevron-right-light.svg" alt="arrow right icon" class="mx-1">
      <span style="color: #00555B;">Market trends</span>
    </span>
    <h3>Market trends</h3>
    <span class="mb-16" style="color:#475467">Lorem ipsum dolor sit amet.</span>

    <v-row>
      <v-col xl="6" lg="6" md="4" sm="6" cols="12">
        <v-card class="card" style="min-height: 100%!important;">
          <h6>Renewable sources</h6>
          <apexchart type="bar" height="250" :options="chartOptions" :series="series"></apexchart>
        </v-card>
      </v-col>

      <v-col xl="4" lg="4" md="4" sm="4" cols="12">
        <v-card class="card" style="min-height: 100%!important;">
          <h6>Types of I - RECs sold</h6>
          <apexchart type="donut" :options="donutOptions" :series="donutSeries"></apexchart>
        </v-card>
      </v-col>

      <v-col xl="2" lg="2" md="4" sm="2" cols="12">
        <v-card class="card divcol jspace" style="min-height: 100%!important; position: relative;">
          <h6>Tokens Redeemed</h6>
          <h5 style="position: absolute; bottom: 0; left: 20px;">10MWh</h5>
        </v-card>
      </v-col>
    </v-row>

    <v-row>
      <v-col xl="6" lg="6" cols="12">
        <v-card class="card">
          <h5 class="mb-4">Price trends</h5>
          <div class="jspace acenter divrow mb-6">
            <div>
              <span style="color: #00555B;">+16.87 (8.12%) <v-icon>mdi-triangle-small-up</v-icon></span>
            </div>

            <v-select
            v-model="time_selection_price"
            :items="['Year', 'Month']"
            variant="outline"
            flat
            menu-icon=""
            class="select"
            bg-color="#ffffff"
            hide-details
            density="compact"
            style="max-width: 120px;"
            >
              <template #append-inner="{ isFocused }">
                <img
                  src="@/assets/sources/icons/chevron-down.svg"
                  alt="chevron-down icon"
                  :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
                >
              </template>
            </v-select>
          </div>
        </v-card>
      </v-col>

      <v-col xl="6" lg="6" cols="12">
        <v-card class="card">
          <h5 class="mb-4">Seasonal trends</h5>
          <div class="jspace acenter divrow mb-6">
            <div>
              <span style="color: #00555B;">+16.87 (8.12%) <v-icon>mdi-triangle-small-up</v-icon></span>
            </div>

            <v-select
            v-model="time_selection_seasonal"
            :items="['Year', 'Month']"
            variant="outline"
            flat
            menu-icon=""
            class="select"
            bg-color="#ffffff"
            hide-details
            density="compact"
            style="max-width: 120px;"
            >
              <template #append-inner="{ isFocused }">
                <img
                  src="@/assets/sources/icons/chevron-down.svg"
                  alt="chevron-down icon"
                  :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
                >
              </template>
            </v-select>
          </div>
        </v-card>
      </v-col>
    </v-row>

    <v-row>
      <v-col cols="12">
        <v-card class="card">
          <h5 class="mb-10">Trading volume</h5>
          <div class="jspace acenter divrow mb-6">
            <div>
              <h5 class="mb-2">219.10</h5>
              <span style="color: #00555B;">+16.87 (8.12%) <v-icon>mdi-triangle-small-up</v-icon></span>
            </div>

            <v-select
            v-model="time_selection_trading"
            :items="['Year', 'Month']"
            variant="outline"
            flat
            menu-icon=""
            class="select"
            bg-color="#ffffff"
            hide-details
            density="compact"
            style="max-width: 120px;"
            >
              <template #append-inner="{ isFocused }">
                <img
                  src="@/assets/sources/icons/chevron-down.svg"
                  alt="chevron-down icon"
                  :style="`transform: ${isFocused.value ? 'rotate(180deg)' : 'none'};`"
                >
              </template>
            </v-select>
          </div>
          <apexchart type="candlestick" height="350" :options="chartOptionsCandle" :series="seriesCandle"></apexchart>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script>
import '@/assets/styles/pages/market-trends.scss'
import VueApexCharts from "vue3-apexcharts"

export default{
  components:{
    apexchart: VueApexCharts,
  },
  data(){
    return{
      time_selection_seasonal: 'Year',
      time_selection_price: 'Year',
      time_selection_trading: 'Year',
      series: [{
        name: 'PRODUCT A',
        data: [24, 55, 31, 67, 12, 43]
      },],
      chartOptions: {
        chart: {
          type: 'bar',
          height: 150,
          stacked: true,
          toolbar: {
            show: false
          },
          zoom: {
            enabled: true
          }
        },
        colors: ['#C6F221'],
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
        yaxis: {
          show: false,
        },
        xaxis: {
          type: 'category',
          categories: ['Wind', 'Solar', 'Biomass', 'Geothermal', 'Hydro', 'Ocean'],
        },
        dataLabels: {
          enabled: false
        },
        legend: {
          show: false,
        },
        fill: {
          opacity: 1
        }
      },
      donutSeries: [44, 55, 81],
      donutOptions: {
        chart: {
          type: 'donut',
        },
        colors: ['#00393D', '#00555B', '#C6F221'],
        dataLabels: {
          enabled: false,
        },
        stroke: {
          width: 0, 
        },
        responsive: [{
          breakpoint: 480,
          options: {
            chart: {
              width: 200
            },
            legend: {
              position: 'bottom'
            }
          }
        }]
      },
      seriesCandle: [{
        data: [
          {
            x: new Date(1538778600000),
            y: [180, 185, 179, 182]
          },
          {
            x: new Date(1538780400000),
            y: [182, 188, 179, 183]
          },
          {
            x: new Date(1538782200000),
            y: [179, 186, 180, 184]
          },
          {
            x: new Date(1538784000000),
            y: [183, 184, 182, 185]
          },
          {
            x: new Date(1538785800000),
            y: [181, 187, 178, 183]
          },
          {
            x: new Date(1538787600000),
            y: [180, 185, 179, 182]
          },
          {
            x: new Date(1538789400000),
            y: [183, 184, 179, 182] 
          },
          {
            x: new Date(1538791200000),
            y: [179, 187, 181, 184]
          },
          {
            x: new Date(1538793000000),
            y: [181, 185, 179, 182]
          },
          {
            x: new Date(1538794800000),
            y: [183, 184, 179, 182] 
          },
          {
            x: new Date(1538796600000),
            y: [180, 187, 179, 183]
          },
          {
            x: new Date(1538798400000),
            y: [182, 185, 181, 184]
          },
          {
            x: new Date(1538800200000),
            y: [181, 185, 180, 182]
          },
          {
            x: new Date(1538802000000),
            y: [179, 186, 179, 183]
          },
          {
            x: new Date(1538803800000),
            y: [180, 184, 178, 183]
          },
          {
            x: new Date(1538805600000),
            y: [183, 184, 179, 182] 
          },
          {
            x: new Date(1538807400000),
            y: [182, 185, 179, 183]
          },
          {
            x: new Date(1538809200000),
            y: [179, 188, 181, 184]
          },
          {
            x: new Date(1538811000000),
            y: [181, 186, 180, 183]
          },
          {
            x: new Date(1538812800000),
            y: [183, 184, 179, 182] 
          },
          {
            x: new Date(1538814600000),
            y: [180, 185, 179, 182]
          },
          {
            x: new Date(1538816400000),
            y: [182, 187, 180, 183]
          },
          {
            x: new Date(1538818200000),
            y: [179, 186, 181, 184]
          },
          {
            x: new Date(1538820000000),
            y: [183, 184, 179, 182] 
          },
          {
            x: new Date(1538821800000),
            y: [183, 184, 181, 185]
          },
          {
            x: new Date(1538823600000),
            y: [182, 186, 178, 183]
          },
          {
            x: new Date(1538825400000),
            y: [180, 187, 180, 184]
          },
          {
            x: new Date(1538827200000),
            y: [182, 185, 179, 183]
          },
          {
            x: new Date(1538829000000),
            y: [179, 186, 180, 182]
          },
          {
            x: new Date(1538830800000),
            y: [181, 185, 179, 183]
          },
        ]
      }],
      chartOptionsCandle: {
        chart: {
          type: 'candlestick',
          height: 350,
          toolbar: {
            show: false
          },
        },
        title: {
          show: false,
        },
        xaxis: {
          type: 'datetime',
          labels: {
            show: false
          }
        },
        yaxis: {
          tooltip: {
            enabled: true
          }
        },
        plotOptions: {
          candlestick: {
            colors: {
              upward: '#00555B',
              downward: '#F97066'
            },
          },
        },
      },
    }
  }
}
</script>