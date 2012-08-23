var oldDataSeries = [];
var dataSeries = [];


/*
* getData(prop)
*
* Description: this is a wrapper that receives a of properties
* to construct a chart and an optional table.
*
* Arguments:
* {
*   "type": type of request (rdtype, zone, site, etc.) 
*           must match a /data/type AJAX request
*
*   "resolution": daily, hourly or '' (5min).
*
*   "extra_args": used to pass as an argument to the URL
*                 i.e.: /data/rdtype/extra_args
*                 this was created to pass the current
*                 detail to the AJAX URL.
*
*   "detail_url": when constructing a table, this url is
*                 used to provide additional detail to
*                 the key element.
*
*   "table_target": id of the <div> to be used to write
*                   the table to.
*
*   "graph_target": id of the <div> to be used to write
*                  the chart to.
*
*   "title": Title of the chart to be generated.
*
*   "subtitle": Subtitle of the chart.
* }
*
*/
function getData(prop) {
  
  console.log('getData() for ' + prop.type);
  prop.isLoaded=true;
  
  var data_url = "/data/" + prop.type;
  if (prop.resolution) {
    data_url += "_" + prop.resolution;
  }

  if(prop.extra_args){
    data_url += "/" + prop.extra_args;
  }

  $.ajax({
    url: data_url,
    success: function(data) {
      newData = data.series;

      // Only write the table if the table_target param is set
      if(prop.table_target){
        console.log("Writing data table...");
        writeTable(data.series, {
          target: prop.table_target,
          detail_url: prop.detail_url
        });
      }

      var chartData = [];
      var otherData = {
        "name": "other",
        "data": []
      };
      var i = 0;
      data.series.forEach(function(s) {

        if (i < 10) {
          chartData.push(s);
          i++;
        } else {
          if (otherData.data.length > 0) {
            s.data.forEach(function(seriesData) {
              otherData.data.forEach(function(otherData) {
                //console.log("otherData: " + otherData[0] + " == " + seriesData[0]);
                if (otherData[0] == seriesData[0]) {
                  otherData[1] += seriesData[1];
                }
              });
            });
          } else {
          //  console.log("first iteration");
            otherData.data = s.data;
          }
        }
      });

      if(otherData.data.length > 0){
        chartData.push(otherData);
      }

      console.log("Writing new chart...");
      chart = generateZoomableStackedGraph({
        title: prop.title,
        data: chartData,
        subtitle: prop.subtitle,
        target: prop.graph_target,
        type: prop.type,
        extra_args: prop.extra_args
      });

      if (chart) {
        chart.hideLoading();
      }

      console.log("All Done!");
    }
  });


}


var currentResolution = "day";

function generateZoomableStackedGraph(prop) {

  var isLoading = false;
  var chart;
  $(document).ready(function() {
    chart = new Highcharts.Chart({
      chart: {
        renderTo: prop.target,
        type: 'area',
        zoomType: 'x',
        events: {
          selection: function selectChartRange(event) {
            var chart = this;
            
            console.log("Properties: " + JSON.stringify(prop));

            oldDataSeries = chart.data;

            console.log("Old Data Series: " + JSON.stringify(oldDataSeries));

            isLoading = true;
            chart.showLoading("Fetching new dataset from server");

            // log the min and max of the primary, datetime x-axis
            if (event.xAxis) {
              console.log("Zooming in at");
              console.log(
              event.xAxis[0].min, event.xAxis[0].max);

              //perform a query to the server
              var range = event.xAxis[0].max - event.xAxis[0].min;
              var url = "/data/" + prop.type;
            
              console.log("RANGE IS: " + range);
              if (range <= 86400000) {

                if (currentResolution != "5min") {
                  currentResolution = "5min";
                  console.log("range is day (5 min intervals)");
                } else {
                  console.log("already at that resolution level (" + currentResolution + ")");
                  if (isLoading) {
                    chart.hideLoading();
                    isLoading = false;
                  }
                  return;
                }
              }
              if (range > 86400000 && range <= 604800000) {

                if (currentResolution != "hourly") {
                  currentResolution = "hourly";
                  console.log("Range is week (hourly)");
                  url += "_hourly";
                } else {
                  console.log("already at that resolution level (" + currentResolution + ")");
                  if (isLoading) {
                    chart.hideLoading();
                    isLoading = false;
                  }
                  return;
                }
              }
              if (range > 604800000) {

                if (currentResolution != "hourly") {

                  currentResolution = "daily";
                  console.log("Range is more than a week (daily)");
                  url += "_daily";
                } else {
                  console.log("already at that resolution level (" + currentResolution + ")");
                  if (isLoading) {
                    chart.hideLoading();
                    isLoading = false;
                  }
                  return;
                }

              }

                if (prop.extra_args){
                  console.log("adding extra args...");
                  url += "/" + prop.extra_args;
                  console.log("URL to be fetched: " + url);
                }

              var newData;
              $.ajax({
                url: url + "?from=" + event.xAxis[0].min + "&to=" + event.xAxis[0].max,
                success: function(data) {
                  console.log("data received: ",JSON.stringify(data));
                  newData = data.series;
                  replaceData(newData, chart);

                  if (isLoading) {
                    chart.hideLoading();
                    isLoading = false;
                  }

                }
              });

            } else {
              console.log("Restoring original chart");
              var newData;
              
              var url="/data/" + prop.type + "_daily";
              
              if (prop.extra_args){
                    console.log("adding extra args...");
                    url += "/" + prop.extra_args;
                    console.log("URL to be fetched: " + url);
              }
              
              
              
              $.ajax({
                url: url,
                success: function(data) {
                  //  console.log("data received: ",JSON.stringify(data));
                  newData = data.series;
                  replaceData(newData, chart);

                  if (isLoading) {
                    chart.hideLoading();
                    isLoading = false;
                    currentResolution = "day";
                  }

                }
              });

            }
          }
        }
      },
      title: {
        text: prop.title
      },
      subtitle: {
        text: prop.subtitle
      },
      xAxis: {
        type: 'datetime',
        maxZoom: 1 * 3600000,
        // 1 hour
        dateTimeLabelFormats: {
          month: '%b %e',
          year: '%Y'
        }
      },
      yAxis: {
        title: {
          text: 'Queries per Second (qps)'
        },
        //min: 0
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
  });

  return chart;
}



function writeLocationTable(series, prop) {
  target = prop.target;
  var table = "<table class=\"table table-striped table-condensed table-bordered\"><thead><tr>";
  table += "<th>#</th>";

  var heading = series[0];

  heading.forEach(function(h) {
    table += "<th>" + h + "</th>";
  });

  table += "</tr></thead><tbody>";


  var i = 0;
  var data = series;
  data.shift();

  data.sort(function(a, b) {
    var data_a = a[3];
    var data_b = b[3];

    return data_b - data_a;
  });


  var detail_url = prop.detail_url;

  data.forEach(function(v) {
    var row = v;

    table += "<tr><td>" + (++i) + "</td><td>";

    if (detail_url) {
      table += "<a href=\"" + prop.detail_url + "/" + v.name + "\">" + row[0] + "</a>";
    } else {
      table += row[0];
    }

    table += "</td><td>" + row[1] + "</td>"
    table += "<td>" + row[2] + "</td>";
    table += "<td>" + row[3] + "</td>";

    table += "</tr>";

  })

  table += "</tbody></table>";

  $("#" + target).html(table);


}

/* 
* writeTable(series,prop)
*
* arguments: series: [[key,val1,val2,...],[key,val1,val2,...]]
* 
*            prop: {
*                target: where to write the table to
*                detail_url: where to link to for additional detail on the key
*               }
*
*/

function writeTable(series, prop) {

  var target = prop.target;

  var table = "<table class=\"table table-striped table-condensed table-bordered\"><thead><tr><th>#</th><th>Node</th><th>Last Value in Set (qps)</th></tr></thead><tbody>";
  var i = 0;


  series.sort(function(a, b) {
    var data_a = a.data;
    var data_b = b.data;

    var last_a = data_a[data_a.length - 1];
    var last_b = data_b[data_b.length - 1];

    return last_b[1] - last_a[1];
  });


  var detail_url = prop.detail_url;

  series.forEach(function(v) {
    var data = v.data;

    data.sort(function(a, b) {
      return a[0] - b[0];
    });

    //  console.log(v.name);
    data.forEach(function(v) {
      var d = new Date(v[0]);
      // console.log( d.getUTCDate() + "/" + d.getUTCHours() + ":" + d.getUTCMinutes() + "," + v[1]);
    });
    //  console.log("\n");
    var last_value = data[data.length - 1];

    table += "<tr><td>" + (++i) + "</td><td>";

    if (detail_url) {
      table += "<a href=\"" + prop.detail_url + "/" + v.name + "\">" + v.name + "</a>";
    } else {
      table += v.name;
    }

    table += "</td><td>" + last_value[1] + "</td></tr>";


  })

  table += "</tbody></table>";

  $("#" + target).html(table);

}


/*
* replaceData(newData,chart)
* 
* Description: receives a new data series and replaces the 
* one currently being displayed in chart.
*
*/

function replaceData(newData, chart) {

  //console.log("Chart series count: ",chart.series.count());
  chart.series.forEach(function(s) {
    newData.forEach(function(n) {
      if (n.name == s.name) {
        s.setData(n.data);
      }
    })
  });
}

