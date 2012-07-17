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
        count: 1
    });
};

var reduce_daily = function(key, values) {
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

var finalize_daily = function(key, value) {
    var r = {
        qps: {},
        count: 0
    };

    // for daily we divide the counters by 24 (24 hours/day)
    r.qps = hash_divide(value.counters, 24);
    r.counters = value.counters;
    r.count = value.count;
    return r;
}


// pull the last sample_time from the DB
var last_rescode_cur = db.rescode_traffic_daily.find({},
{
    "_id.sample_time": 1
}).sort({
    "_id.sample_time": -1
}).limit(1);

var now = new Date();
var today = new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());

if (last_rescode_cur.hasNext()) {
    var last_rescode = last_rescode_cur.next();
    // Run mapReduce with the previous value
    db.rescode_traffic_hourly.mapReduce(map_rescode_daily, reduce_daily, {
        query: {
            "_id.sample_time": {
                $gt: last_rescode._id.sample_time,
                $lt: today
            }
        },
        out: {
            reduce: "rescode_traffic_daily"
        },
        finalize: finalize_daily
    });

}
 else {
    // This is the first time running
    db.rescode_traffic_hourly.mapReduce(map_rescode_daily, reduce_daily, {
        out: {
            reduce: "rescode_traffic_daily"
        },
        query: {
            "_id.sample_time": {
                $lt: today
            }
        },
        finalize: finalize_daily
    });
    // Create index
    db.rescode_traffic_daily.ensureIndex({
        "_id.sample_time": 1,
        "_id.pubservhost": 1,
        "_id.zone": 1
    });
}



