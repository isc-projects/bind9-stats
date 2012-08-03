/*
* Map Reduce procedure for the traffic collection hourly
*/

var mapf=function () {
  var date = new Date();
  date.setTime(this._id.sample_time);
  var sample_hour = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), 0, 0, 0, 0);
  emit({
    "sample_time": sample_hour,
    "zone": this._id.zone
  }, {
    "qps": {},
    "counters": this.qps,
    "count": 1,
    "created_time": this.created_time
  });
};

var reducef=function (key, values) {
  var r = {
    "qps": {},
    "counters": {},
    "count": 0,
    "created_time": 0
  };
  values.forEach(function(v) {
    r.counters = hash_add(v.counters, r.counters);
    r.count++;
    r.created_time = v.created_time > r.created_time ? v.created_time:r.created_time;
  });
  return r;
};



var finalizef=function (key, value) {
  // for hourly we divide the counters by 12 (5 minutes per hour)
  var r = {
    "qps": hash_divide(value.counters, 288),
    "counters": value.counters,
    "count": value.count,
    "created_time": value.created_time
  };
  return r;
};





// pull the last sample_time from the DB
var last_processed_cur = db.mr_global_traffic_daily_log.find({}, {
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
  
  mr_output=db.runCommand( { "mapreduce":"traffic",
  			      "map": mapf,
  			      "reduce": reducef,
  			      "query":{ "created_time": { $gt: last_processed_time }},
  			      "out": { reduce: "global_traffic_daily" },
  			      "finalize":finalizef
  			    });

  print("Done!");


} else {
  print("Running mapreduce for the first time!\n");

  // This is the first time running

  mr_output=db.runCommand( { "mapreduce":"traffic",
 			      "map": mapf,
 			      "reduce": reducef,
 			      "out": "global_traffic_daily",
 			      "finalize":finalizef
 			    });


  // Create index
  db.global_traffic_daily.ensureIndex({
    "_id.sample_time": 1,
    "_id.pubservhost": 1,
    "_id.zone": 1
  });

  // Index the created time field
  db.global_traffic_daily.ensureIndex({
    "value.created_time": 1
  });
}


print("Checking for mapreduce result...");
if (mr_output.ok) {
  print("OK\n");
  var last_processed_cur=db.global_traffic_daily.find({}).sort({"value.created_time":-1}).limit(1);
  if(last_processed_cur.hasNext()){
    var lp = last_processed_cur.next();
    print("Last created_time in global_traffic_daily: " + lp.value.created_time + "\n");  
    db.mr_global_traffic_daily_log.insert({
      "last_processed_time": lp.value.created_time,
      "result": mr_output
    });
  }
}
else{
  print("An error occurred processing the set:\n");
}










