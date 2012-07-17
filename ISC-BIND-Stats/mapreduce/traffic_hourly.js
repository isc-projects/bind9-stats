/*
* Map Reduce procedure for the traffic collection hourly
*/

var map_rescode_hourly = function() {
    var date = new Date();
    date.setTime(this._id.sample_time);
    var sample_hour = new Date(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), date.getUTCHours(), 0, 0, 0);
    emit({
        sample_time: sample_hour,
        pubservhost: this._id.pubservhost,
        zone: this._id.zone
    },
    {
        qps: {},
        counters: this.qps,
        count: 1
    });
};

var reduce_hourly = function(key, values) {
    var r = {
        qps: {},
        counters: {},
        count: 0
    };
    values.forEach(function(v) {
        r.counters = hash_add(v.counters, r.counters);
        r.count++;
    });
    return r;
}

var finalize_hourly = function(key, value) {
    var r = {
        qps: {},
        count: 0
    };

    // for hourly we divide the counters by 12 (5 minutes per hour)
    r.qps = hash_divide(value.counters, 12);
    r.counters = value.counters;
    r.count = value.count;
    return r;
}


// pull the last sample_time from the DB
var last_rescode_cur = db.rescode_traffic_hourly.find({},
{
    "_id.sample_time": 1
},
{
    _id: 1
}).sort({
    "_id.sample_time": -1
}).limit(1);

var now = new Date();
var hour = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), now.getUTCHours());

if (last_rescode_cur.hasNext()) {
    var last_rescode = last_rescode_cur.next();

    print("Running mapreduce with: gte: "
    + (new Date(last_rescode._id.sample_time.getTime() + 3600000))
    + " ; lt: " + hour + "\n"
    );

    // Run mapReduce with the previous value
    db.traffic.mapReduce(map_rescode_hourly, reduce_hourly, {
        query: {
            "_id.sample_time": {
                $gte: last_rescode._id.sample_time.getTime() + 3600000,
                $lt: hour.getTime()
            }
        },
        out: {
            reduce: "rescode_traffic_hourly"
        },
        finalize: finalize_hourly
    });

}
 else {
    // This is the first time running
    db.traffic.mapReduce(map_rescode_hourly, reduce_hourly, {
        out: {
            reduce: "rescode_traffic_hourly"
        },
        query: {
            "_id.sample_time": {
                $lt: hour.getTime()
            }
        },
        finalize: finalize_hourly
    });
    // Create index
    db.rescode_traffic_hourly.ensureIndex({
        "_id.sample_time": 1,
        "_id.pubservhost": 1,
        "_id.zone": 1
    });
}



