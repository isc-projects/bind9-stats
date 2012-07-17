db.system.js.save({
    _id: "hash_add",
    value: function hash_add(a, b) {
        var r = {};
        for (var i in a) if (a.hasOwnProperty(i) || b.hasOwnProperty(i))
        {
            a[i] = a[i] || 0;
            b[i] = b[i] || 0;
            r[i] = a[i] + b[i];
        }
        return r;
    }
});


db.system.js.save({
    _id: "hash_divide",
    value: function hash_divide(a, amount) {
        var r = {};
        if (amount == 0) {
            return;
        }
        for (var i in a) if (a.hasOwnProperty(i))
        {
            r[i] = a[i] / amount;
        }
        return r;
    }
});
