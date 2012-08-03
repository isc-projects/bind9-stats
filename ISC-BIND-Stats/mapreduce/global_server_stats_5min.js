/*
* Map Reduce procedure for the traffic collection hourly
*/


var map_rescode_hourly=function () {
  var date = new Date();
  date.setTime(this._id.sample_time);
  var sample_hour = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), date.getUTCMinutes(), 0, 0);
  emit({
    "sample_time": sample_hour,
  }, {
    "zonestats_qps": {},
    "zonestats_counters": this.zonestat_qps,
    "nsstat_qps": {},
    "nsstat_counters":this.nsstat_qps,
    "rdtype_qps":{},
    "rdtype_counters":this.rdtype_qps,
    "opcode_qps":{},
    "opcode_counters":this.opcode_qps,
    "count": 1,
    "created_time": this.created_time
  });
};

var reduce_hourly=function (key, values) {
  var r = {
    "zonestats_qps": {},
    "zonestats_counters": {},
    "nsstat_qps": {},
    "nsstat_counters":{},
    "rdtype_qps":{},
    "rdtype_counters":{},
    "opcode_qps":{},
    "opcode_counters":{},
    "count": 0,
    "created_time": 0
  };
  values.forEach(function(v) {
    r.zonestats_counters = hash_add(v.zonestats_counters,r.zonestats_counters);
    r.nsstat_counters = hash_add(v.nsstat_counters,r.nsstat_counters);
    r.rdtype_counters = hash_add(v.rdtype_counters,r.rdtype_counters);
    r.opcode_counters = hash_add(v.opcode_counters,r.opcode_counters);
    r.count++;
    r.created_time = v.created_time > r.created_time ? v.created_time:r.created_time;
  });
  return r;
};



var finalize_hourly=function (key, value) {
  // for hourly we divide the counters by 12 (5 minutes per hour)
  var r = {
    "zonestats_qps": hash_divide(value.zonestats_counters,1),
    "nsstat_qps": hash_divide(value.nsstat_counters,1),
    "rdtype_qps" : hash_divide(value.rdtype_counters,1),
    "opcode_qps" : hash_divide(value.opcode_counters,1),
    "zonestats_counters" : value.zonestats_counters,
    "nsstat_counters" : value.nsstat_counters,
    "rdtype_counters" : value.rdtype_counters,
    "opcode_counters" : value.opcode_counters,
    "count": value.count,
    "created_time": value.created_time
  };
  return r;
};





// pull the last sample_time from the DB
var last_processed_cur = db.mr_global_server_stats_5min_log.find({}, {
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
  
  mr_output=db.runCommand( { "mapreduce":"server_stats",
  			      "map": map_rescode_hourly,
  			      "reduce": reduce_hourly,
  			      "query":{ "created_time": { $gt: last_processed_time }},
  			      "out": { reduce: "global_server_stats_5min" },
  			      "finalize":finalize_hourly
  			    });

  print("Done!");


} else {
  print("Running mapreduce for the first time!\n");

  // This is the first time running

  mr_output=db.runCommand( { "mapreduce":"server_stats",
 			      "map": map_rescode_hourly,
 			      "reduce": reduce_hourly,
 			      "out": "global_server_stats_5min",
 			      "finalize":finalize_hourly
 			    });


  // Create index
  db.global_server_stats_5min.ensureIndex({
    "_id.sample_time": 1,
    "_id.pubservhost": 1,
    "_id.zone": 1
  });

  // Index the created time field
  db.global_server_stats_5min.ensureIndex({
    "value.created_time": 1
  });
}


print("Checking for mapreduce result...");
if (mr_output.ok) {
  print("OK\n");
  var last_processed_cur=db.global_server_stats_5min.find({}).sort({"value.created_time":-1}).limit(1);
  if(last_processed_cur.hasNext()){
    var lp = last_processed_cur.next();
    print("Last created_time in global_server_stats_5min: " + lp.value.created_time + "\n");  
    db.mr_global_server_stats_5min_log.insert({
      "last_processed_time": lp.value.created_time,
      "result": mr_output
    });
  }
}
else{
  print("An error occurred processing the set:\n");
}










