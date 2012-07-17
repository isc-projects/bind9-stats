function generateStackedGraph(prop) {
  
  
  
  
  chart = new Highcharts.Chart({
    chart: {
      renderTo: prop.target,
      type: 'area',
      zoomType: 'x'
    },
    title: {
      text: prop.title
    },
    subtitle: {
      text: prop.subtitle
    },
    xAxis: {
      type: 'datetime',
      maxZoom: 1  * 3600000, // 1 hour
      dateTimeLabelFormats: { // don't display the dummy year
        month: '%b %e',
        year: '%Y'
      }
    },
    yAxis: {
      title: {
        text: 'Queries per Second (qps)'
      },
      min: 0
    },
    tooltip: {
      formatter: function() {
        return '<b>' + this.series.name + '</b><br/>' + Highcharts.dateFormat('%b %e %Y @ %H:%M', this.x) + ' > ' + this.y + ' qps';
      }
    },
    plotOptions: {
      area: {
        stacking: "normal"
      },
      series: {
        marker: {
          enabled: false,
          states: {
            hover: {
              enabled: true,
              radius: 5
            }
          }
        }
      }
    },
    series: prop.data
  });
}
