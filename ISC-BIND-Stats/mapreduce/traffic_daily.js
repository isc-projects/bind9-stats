/*
* Map Reduce procedure for traffic daily
*/

var map_rescode_daily = function() {
    var date = this._id.sample_time;
    var sample_day = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0, 0);
    emit({
        sample_time: sample_day,
        pubservhost: this._id.pubservhost,
        zone: this._id.zone
    },
    {
        qps: {},
        counters: this.value.qps,
        count: 1,
        created_time: this.value.created_time
    });
};

var reduce_daily = function(key, values) {
    var r = {
        qps: {},
        counters: {},
        count: 0,
        created_time:0
    };
    values.forEach(function(v) {
        r.counters = hash_add(v.counters, r.counters);
        r.count++;
        r.created_time=v.created_time > r.created_time ? v.created_time:r.created_time;
    });
    return r;
}

var finalize_daily = function(key, value) {
    var r = {
        qps: {},
        count: 0,
        created_time:0
    };

    // for daily we divide the counters by 24 (24 hours/day)
    r.qps = hash_divide(value.counters, 24);
    r.counters = value.counters;
    r.count = value.count;
    r.created_time = value.created_time;
    return r;
}




// pull the last sample_time from the DB
var last_processed_cur = db.mr_rescode_traffic_daily_log.find({}, {
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

  print("Running mapreduce with: $gt: " + last_processed_time + "\n");

  // Run mapReduce with the previous value
  
  mr_output=db.runCommand( { "mapreduce":"rescode_traffic_hourly",
  			      "map": map_rescode_daily,
  			      "reduce": reduce_daily,
  			      "query":{ "value.created_time": { $gt: last_processed_time }},
  			      "out": { reduce: "rescode_traffic_daily" },
  			      "finalize":finalize_daily
  			    });

  print("Done!");


} else {
  print("Running mapreduce for the first time!\n");

  // This is the first time running

  mr_output=db.runCommand( { "mapreduce":"rescode_traffic_hourly",
 			      "map": map_rescode_daily,
 			      "reduce": reduce_daily,
 			      "out": "rescode_traffic_daily",
 			      "finalize":finalize_daily
 			    });


  // Create index
  db.rescode_traffic_daily.ensureIndex({
    "_id.sample_time": 1,
    "_id.pubservhost": 1,
    "_id.zone": 1
  });

  // Index the created time field
  db.rescode_traffic_daily.ensureIndex({
    "value.created_time": 1
  });
}


print("Checking for mapreduce result...");
if (mr_output.ok) {
  print("OK\n");
  var last_processed_cur=db.rescode_traffic_daily.find({}).sort({"value.created_time":-1}).limit(1);
  if(last_processed_cur.hasNext()){
    var lp = last_processed_cur.next();
    print("Last created_time in rescode_traffic_daily: " + lp.value.created_time + "\n");  
    db.mr_rescode_traffic_daily_log.insert({
      "last_processed_time": lp.value.created_time,
      "result": mr_output
    });
  }
}
else{
  print("An error occurred processing the set:\n");
}
