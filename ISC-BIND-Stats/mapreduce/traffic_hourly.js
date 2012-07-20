/*
* Map Reduce procedure for the traffic collection hourly
*/

var map_rescode_hourly=function () {
  var date = new Date();
  date.setTime(this._id.sample_time);
  var sample_hour = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), 0, 0, 0);
  emit({
    "sample_time": sample_hour,
    "pubservhost": this._id.pubservhost,
    "zone": this._id.zone
  }, {
    "qps": {},
    "counters": this.qps,
    "count": 1,
    "created_time": this.created_time
  });
};

var reduce_hourly=function (key, values) {
  var r = {
    "qps": {},
    "counters": {},
    "count": 0,
    "created_time": 0
  };
  values.forEach(function(v) {
    r.counters = hash_add(v.counters, r.counters);
    r.count++;
    r.created_time = v.created_time;
  });
  return r;
};



var finalize_hourly=function (key, value) {
  // for hourly we divide the counters by 12 (5 minutes per hour)
  var r = {
    "qps": hash_divide(value.counters, 12),
    "counters": value.counters,
    "count": value.count,
    "created_time": value.created_time
  };
  return r;
};





// pull the last sample_time from the DB
var last_processed_cur = db.mr_rescode_traffic_hourly_log.find({}, {
  last_processed_time: 1
}).sort({
  last_processed_time: -1
}).limit(1);

// this is where we store the mapreduce output
var mr_output;
var last_processed_time;

// if we have a previous set processed
if (last_processed_cur.hasNext()) {
  var last_processed = last_processed_cur.next();
  last_processed_time = last_processed.last_processed_time;

  print("Running mapreduce with: gt: " + last_processed_time + "\n");

  // Run mapReduce with the previous value
  /* mr_output = db.traffic.mapReduce(map_rescode_hourly, reduce_hourly, {
    query: {
      created_time: {
        $gt: last_processed_time
      }
    },
    out: {
      reduce: "rescode_traffic_hourly"
    },
    finalize: finalize_hourly
  });
  */
  
  mr_output=db.runCommand( { "mapreduce":"traffic",
  			      "map": map_rescode_hourly,
  			      "reduce": reduce_hourly,
  			      "query":{ "created_time": { $gt: last_processed_time }},
  			      "out": { reduce: "rescode_traffic_hourly" },
  			      "finalize":finalize_hourly
  			    });


} else {
  print("Running mapreduce for the first time!\n");

  // This is the first time running
 /* mr_output = db.traffic.mapReduce(map_rescode_hourly, reduce_hourly, {
    out: {
      reduce: "rescode_traffic_hourly"
    },
    finalize: finalize_hourly
  });
*/

mr_output=db.runCommand( { "mapreduce":"traffic",
 			      "map": map_rescode_hourly,
 			      "reduce": reduce_hourly,
 			      "out": "rescode_traffic_hourly",
 			      "finalize":finalize_hourly
 			    });


  // Create index
  db.rescode_traffic_hourly.ensureIndex({
    "_id.sample_time": 1,
    "_id.pubservhost": 1,
    "_id.zone": 1
  });

  // Index the created time field
  db.rescode_traffic_hourly.ensureIndex({
    created_time: 1
  });
}

if (mr_output.ok) {
  var last_processed_cur=db.rescode_traffic_hourly.find({},{created_time:1}).sort({created_time:-1}).limit(1);
  
  if(last_processed_cur.hasNext()){
    var lp = last_processed_cur.next();  
    db.mr_rescode_traffic_hourly_log.insert({
      "last_processed_time": lp.created_time,
      "result": mr_output
    });
  }
}










