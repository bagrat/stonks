import Chart from "chart.js/auto"

const StockChart = {
  mounted() {
    const el = this.el
    const symbol = el.dataset.symbol
    const exchange = el.dataset.exchange
    const canvas = el.querySelector("canvas")

    const dataPointElements = el.querySelectorAll("datapoint")
    const dataPoints = Array.from(dataPointElements).map((dp) => {
      const close = parseFloat(dp.dataset.close)
      const open = parseFloat(dp.dataset.open)
      const high = parseFloat(dp.dataset.high)
      const low = parseFloat(dp.dataset.low)

      return {
        datetime: dp.dataset.datetime,
        close,
        open,
        high,
        low,
        average: (open + close + high + low) / 4,
      }
    })

    console.log(dataPoints)

    const chart = new Chart(canvas, {
      type: "line",
      data: {
        labels: dataPoints.map((dp) => dp.datetime),
        datasets: [
          {
            data: dataPoints.map((dp) => dp.average),
            borderColor: "#4CAF50",
            pointRadius: 0,
            tension: 0.4,
            borderWidth: 1,
          },
        ],
      },
      options: {
        animation: false,
        devicePixelRatio: 2,
        responsive: true,
        maintainAspectRatio: false,
        resizeDelay: 0,
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false },
        },
        hover: { mode: null },
        scales: {
          x: {
            display: false,
          },
          y: {
            display: false,
          },
        },
      },
    })
  },
}

export const hooks = {
  StockChart,
}
