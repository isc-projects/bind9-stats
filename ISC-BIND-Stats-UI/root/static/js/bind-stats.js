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
    			min: 0
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
