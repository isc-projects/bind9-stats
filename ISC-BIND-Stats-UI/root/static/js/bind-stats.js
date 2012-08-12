var oldDataSeries=[];



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



var currentResolution="day";
function generateZoomableStackedGraph(prop){
  
    var isLoading=false;
    var chart;
    $(document).ready(function() {
    	chart = new Highcharts.Chart({
    		chart: {
    			renderTo: prop.target,
    			type: 'area',
    			zoomType: 'x',
    			events:{
    			  selection: function selectChartRange(event){
              var chart=this;
  
              oldDataSeries=chart.data;
              
              console.log("Old Data Series: " + JSON.stringify(oldDataSeries));
  
              isLoading=true;
              chart.showLoading("Fetching new dataset from server");
  
               // log the min and max of the primary, datetime x-axis
             if(event.xAxis){
               console.log("Zooming in at");
               console.log(
                 	event.xAxis[0].min,
                 	event.xAxis[0].max
                );
               	
                //perform a query to the server
                var range=event.xAxis[0].max - event.xAxis[0].min;
                var url="/data/" + prop.type;
                console.log("RANGE IS: " + range);
                if(range <= 86400000 ){
                  
                  if(currentResolution != "5min"){
                    currentResolution="5min";
                    console.log("range is day (5 min intervals)");
                  }
                  else{
                    console.log("already at that resolution level ("+ currentResolution+")");
                    if(isLoading){
                      chart.hideLoading();
                      isLoading=false;
                    }
                    return;
                  }
                }
                if(range > 86400000 && range <= 604800000){
                  
                  if(currentResolution != "hourly"){
                    currentResolution="hourly";
                    console.log("Range is week (hourly)");
                    url+="_hourly";
                  }
                  else{
                     console.log("already at that resolution level (" + currentResolution + ")");
                      if(isLoading){
                         chart.hideLoading();
                         isLoading=false;
                       }
                    return;
                  }
                }
                if(range > 604800000){
                  
                  if(currentResolution != "hourly"){
                  
                    currentResolution="daily";
                    console.log("Range is more than a week (daily)");
                    url+="_daily";
                  }
                  else{
                      console.log("already at that resolution level (" + currentResolution + ")");
                       if(isLoading){
                          chart.hideLoading();
                          isLoading=false;
                        }
                      return;
                  }
                
                }
                            
              
                
                var newData;
                $.ajax({
                  url: url + "?from=" + 	event.xAxis[0].min + "&to=" + event.xAxis[0].max,  
                  success: function(data){
                   // console.log("data received: ",JSON.stringify(data));
                    newData=data.series;
                    replaceData(newData,chart);
                    
                    if(isLoading){
                      chart.hideLoading();
                      isLoading=false;
                    }
                    
                    }
                });

              }
              else{
                console.log("Restoring original chart");
                 var newData;
                  $.ajax({
                    url: "/data/" + prop.type + "_daily",  
                    success: function(data){
                    //  console.log("data received: ",JSON.stringify(data));
                      newData=data.series;
                      replaceData(newData,chart);

                      if(isLoading){
                        chart.hideLoading();
                        isLoading=false;
                        currentResolution="day";
                      }

                      }
                  });
              
              
              
              /*                     
                replaceData(oldDataSeries,chart); // replace the data with the original data series
                
                if(isLoading){
                   chart.hideLoading();
                    isLoading=false;
                  
                }
              */
              
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
    			maxZoom: 1  * 3600000, // 1 hour
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
    					return '<b>'+ this.series.name +'</b><br/>'+
    					Highcharts.dateFormat('%b %e %Y @ %H:%M', this.x) +' > '+ this.y +' qps';
    			}
    		},
    		plotOptions: {
    		   area: {
              stacking: "normal"
            },
    		  series:{
    		    marker:{
    		      enabled:false,
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



function writeLocationTable(series,prop){
  target=prop.target;
  var table="<table class=\"table table-striped table-condensed table-bordered\"><thead><tr>";
  table +="<th>#</th>";
  
  var heading=series[0];
  
  heading.forEach(function(h){
    table+="<th>" + h + "</th>";
  });
  
  table+= "</tr></thead><tbody>";
  
  
   var i=0;
   var data=series;
   data.shift();

   data.sort(function(a,b){
     var data_a=a[2];
     var data_b=b[2];

     return data_b - data_a;
   });


   var detail_url=prop.detail_url;

   data.forEach(function(v){
     var row=v;

     table += "<tr><td>" + (++i) + "</td><td>";

       if(detail_url){
         table+="<a href=\"" + prop.detail_url + "/" + v.name +"\">" + row[0] + "</a>";
       }
       else{
         table+= row[0];
       }

       table+="</td><td>" + row[1] + "</td>"
       table+="<td>" + row[2] + "</td>";
       table+="<td>" + row[3] + "</td>";
       
       table+="</tr>";
       
   })

   table+="</tbody></table>";

   $("#"+target).html(table);

  
}



function writeTable(series,prop){
  
  var target=prop.target;

  var table="<table class=\"table table-striped table-condensed table-bordered\"><thead><tr><th>#</th><th>Node</th><th>Last Value in Set (qps)</th></tr></thead><tbody>";
  var i=0;
  
  
  series.sort(function(a,b){
    var data_a=a.data;
    var data_b=b.data;
    
    var last_a=data_a[data_a.length - 1 ];
    var last_b=data_b[data_b.length - 1 ];
    
    return last_b[1] - last_a[1];
  });
  
  
  var detail_url=prop.detail_url;
  
  series.forEach(function(v){
    var data=v.data;
    
    data.sort(function(a,b){
      return a[0] - b[0]; 
    });
    
    console.log(v.name);
    data.forEach(function(v){
      var d=new Date(v[0]);
      console.log( d.getUTCDate() + "/" + d.getUTCHours() + ":" + d.getUTCMinutes() + "," + v[1]);
    });
    console.log("\n");
    
    var last_value=data.pop();
    
    table += "<tr><td>" + (++i) + "</td><td>";
    
      if(detail_url){
        table+="<a href=\"" + prop.detail_url + "/" + v.name +"\">" + v.name + "</a>";
      }
      else{
        table+= v.name;
      }

      table+="</td><td>" + last_value[1] + "</td></tr>";
    
  
  })
  
  table+="</tbody></table>";
  
  $("#"+target).html(table);
  
}



function replaceData(newData,chart){
   
   //console.log("Chart series count: ",chart.series.count());
   
   chart.series.forEach(function(s){
      newData.forEach(function(n){
        if(n.name == s.name){
          s.setData(n.data);
        }
      }) 
     });
}
 




function generateAreaGraph(prop) {
  
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
    },
    tooltip: {
      formatter: function() {
        return '<b>' + this.series.name + '</b><br/>' + Highcharts.dateFormat('%b %e %Y @ %H:%M', this.x) + ' > ' + this.y + ' qps';
      }
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
}
