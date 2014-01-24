var oldDataSeries = [];
var dataSeries = [];

var DATA_URI = "/data/";



/* This is usted to format an error message */
var flashError = function(args) {
    $("#" + args.target).html("<div class=\"alert alert-error\">" 
    + "<a class=\"close\" data-dismiss=\"alert\" href=\"#\">&times;</a>" 
    + "<h4>Error:</h4>" + args.message + "</div>");
    };





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
      prop.isLoaded = true;

      var xseries=[];

      var data_url = DATA_URI + prop.type;
      if (prop.resolution) {
        data_url += "_" + prop.resolution;
      }

      if (prop.extra_args) {
        data_url += "/" + prop.extra_args;
      }

      $.ajax({
        url: data_url,
        statusCode: {
          404: function() {
            flashError({
              "target": prop.graph_target,
              "message": "Data Source cannot be found"
            });
          },
          500: function() {
            flashError({
              "target": prop.graph_target,
              "message": "Error occurred at the server while retrieving the data, please try again later..."
            });
          }
        },
        success: function(data) {
          newData = data.series;   
          categories = data.categories;


          if($.isArray(newData)){
            console.log("Length of newData is: " + newData.length);

          }
          else{
            console.log('Data returned is not an array');
             flashError({
                "target": prop.graph_target,
                "message": "There was a problem retrieving the data set, please try again later..."
              });
            return false;
          }


          // Only write the table if the table_target param is set
          if (prop.table_target) {
            console.log("Writing data table...");
            writeTable(data.series, {
              target: prop.table_target,
              detail_url: prop.detail_url
            });
          }

          // If the heat map is requested
          if(prop.heat_map){
            console.log("Heat Map requested:");
            writeHeatMap(data.series,{
              target: prop.heat_map
            });
          }

        var chartData=normalizeData(data);

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

                //console.log("Properties: " + JSON.stringify(prop));
                oldDataSeries = chart.data;

                //console.log("Old Data Series: " + JSON.stringify(oldDataSeries));
                isLoading = true;
                chart.showLoading("Fetching new dataset from server");

                // log the min and max of the primary, datetime x-axis
                if (event.xAxis) {
                //  console.log("Zooming in at");
                //  console.log(
                //  event.xAxis[0].min, event.xAxis[0].max);

                  //perform a query to the server
                  var range = event.xAxis[0].max - event.xAxis[0].min;
                  var url = DATA_URI + prop.type;

                  //console.log("RANGE IS: " + range);
                  if (range <= 86400000) {

                    if (currentResolution != "5min") {
                      currentResolution = "5min";
                     // console.log("range is day (5 min intervals)");
                    } else {
                     // console.log("already at that resolution level (" + currentResolution + ")");
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
                   //   console.log("Range is week (hourly)");
                      url += "_hourly";
                    } else {
                    //  console.log("already at that resolution level (" + currentResolution + ")");
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
                     // console.log("Range is more than a week (daily)");
                      url += "_daily";
                    } else {
                    //  console.log("already at that resolution level (" + currentResolution + ")");
                      if (isLoading) {
                        chart.hideLoading();
                        isLoading = false;
                      }
                      return;
                    }

                  }

                  if (prop.extra_args) {
                   // console.log("adding extra args...");
                    url += "/" + prop.extra_args;
                 //   console.log("URL to be fetched: " + url);
                  }

                  var newData;
                  $.ajax({
                    url: url + "?from=" + event.xAxis[0].min + "&to=" + event.xAxis[0].max,
                    success: function(data) {
                     // console.log("data received: ", JSON.stringify(data));
                      newData = normalizeData(data);
                      replaceData(newData, chart);

                      if (isLoading) {
                        chart.hideLoading();
                        isLoading = false;
                      }

                    }
                  });
                } else {
                //  console.log("Restoring original chart");
                  var newData;

                  var url = DATA_URI + prop.type + "_daily";

                  if (prop.extra_args) {
                //    console.log("adding extra args...");
                    url += "/" + prop.extra_args;
                 //   console.log("URL to be fetched: " + url);
                  }

                  $.ajax({
                    url: url,
                    success: function(data) {
                      //  console.log("data received: ",JSON.stringify(data));
                     // newData = data.series;
                      newData=normalizeData(data);
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
          series: prop.data,
          colors: [
              '#2299DD',
              '#FFAA00',
              '#0AA841', 
            	'#2BC2BA',
            	'#BD51BB', 
            	'#AA4643', 
            	'#89A54E', 
            	'#80699B', 
            	'#3D96AE', 
            	'#FFDD77', 
            	'#2B6AA1'
            ]
        });
      });

      return chart;
    }

    // converts the dataset suitable for graphing

    function normalizeData(data){


        console.log("normalizeData() called");

         var chartData = [];
         var otherData = {
            name: "other",
            data: []
          };
          var i = 0;

          sortData(data);

          data.series.forEach(function(s) {

            if (i < 10) {
              console.log("adopting: " + s.name);
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
                //console.log("first iteration");
                otherData.data = s.data;
              }
            }
          });

          if (otherData.data.length > 0) {
            console.log("Pushing Other Data...");
            chartData.push(otherData);
          }
          else{
            console.log("otherData was not used");
          }

      return chartData;

    }




    function sortData(data){
      var series=data.series;
      series.sort(function(a, b) {
        var data_a = a.data;
        var data_b = b.data;
        var last_a = data_a[data_a.length - 1];
        var last_b = data_b[data_b.length - 1];
        return last_b[1] - last_a[1];
      });
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
    * writeHeatMap(series,prop)
    *
    */

    function writeHeatMap(series,prop){

      //needs <script type='text/javascript' src='https://www.google.com/jsapi'></script>
      var options={
        region:'world',
        displayMode:'markers',
        colorAxis: {
          colors:['yellow','orange','red'],
          minValue:0,
          maxValue:2000
        },
        backgroundColor:{
          stroke:"#064284",
          strokeWidth:1
        },
        sizeAxis:{
          minValue:0,
          maxValue:10
        },
        markerOpacity:0.8,
        datalessRegionColor:'#86C2D4'
      };

     // console.log("target is: " + prop.target);

      var target = document.getElementById(prop.target);

      if(target){
       // console.log("target was found...");
      }
      else{
       // console.log(prop.target + ' was not found ');
        return false;
      }

      series.sort(function(a, b) {
         var data_a = a.data;
         var data_b = b.data;
         var last_a = data_a[data_a.length - 1];
         var last_b = data_b[data_b.length - 1];
         return last_b[1] - last_a[1];
       });

       var detail_url = prop.detail_url;

       var geodata=[['City','Queries']];

       series.forEach(function(v) {
         var data = v.data;
         data.sort(function(a, b) {
           return a[0] - b[0];
         });
         data.forEach(function(v) {
           var d = new Date(v[0]);
         });
         var last_value = data[data.length - 1];
         if(last_value[1] == null){
           return false;
         }     
         geodata.push([v.name,last_value[1]]);
       });

       var chart=new google.visualization.GeoChart(target);

    //   console.log(JSON.stringify(geodata));
       chart.draw(google.visualization.arrayToDataTable(geodata), options);

       return chart;
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

      var i = 0;

      sortData({series:series});

      var detail_url = prop.detail_url;



      var last_date=[];
      var table="";

      var first=true;

      series.forEach(function(v) {
        var data = v.data;

        data.sort(function(a, b) {
          return a[0] - b[0];
        });

        //  console.log(v.name);
        data.forEach(function(v) {
          var d = new Date(v[0]);
        });




        if(first){
          for(var j=3 ; j>0;j--){
            if(data[data.length - j]){
              last_date[j]=new Date(data[data.length - j][0]);
            }
          }        
          first=false;
        }

        table += "<tr><td>" + (++i) + "</td><td>";

        if (detail_url) {
          table += "<a href=\"" + prop.detail_url + "/" + v.name + "\">" + v.name + "</a>";
        } else {
          table += v.name;
        }

        table += "</td>";

        for(var j=3;j>0;j--){
          if(data[data.length - j]){
            table+="<td>" + data[data.length - j][1] + "</td>";
          }
        }

        table +="</tr>";
      })

      table += "</tbody></table>";

      var header = "<table class=\"table table-striped table-condensed table-bordered\">";
      header +="<thead><tr><th>#</th><th style=\"width:40%;\">Description</th>";

       for(var j=3 ; j>0;j--){
          if(last_date[j]){
            header+="<th>" + last_date[j].toUTCString() + "</th>";
          }
        }


      header +="</tr></thead><tbody>";

      //console.log(header);
      //console.log(table);

      $("#" + target).html(header+table);

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

      while(chart.series.length > 0){
        chart.series[0].remove(false);
      }

      newData.forEach(function(nd){
        chart.addSeries(nd,false);
      });

      chart.redraw();


    }



    /*
    *
    * generateLineChart(prop)
    *
    * prop= {
    *       "target":"target_div",
    *       "title": "Graph Title",
    *       "subtitle": "Graph Subtitle",
    *       "data":[ { name:"name", data:[[1,3],[4,5],[6,7]] }, { name: "another",data:[[1,3],[4,5],[6,7]]}]
    *   }
    *
    */

    function generateLineChart(prop) {

     // console.log(JSON.stringify(prop));

      var chart = new Highcharts.Chart({
          chart: {
              renderTo: prop.target,
              type: 'line',
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
              maxZoom: 1 * 3600000,
              // 1 hour
              dateTimeLabelFormats: {
                month: '%b %e',
                year: '%Y'
              }
            },
            yAxis: {
              title: {
                text: 'Elapsed time (seconds)'
                },
                min:0
              },
            plotOptions: {
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
      return chart;
    }

