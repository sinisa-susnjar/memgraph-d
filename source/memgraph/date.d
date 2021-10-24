/// Provides a wrapper around a `mg_date`.
module memgraph.date;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;
import sd = std.datetime.date;
import ct = core.time;

/// Represents a date.
///
/// Date is defined with number of days since the Unix epoch.
/// Uses a `std.datetime.date.Date` internally.
struct Date {
	/// Create a copy of `other` Date.
	this(Date other) { date_ = other.date_; }

	/// Create a copy of `other` std.datetime.date.Date.
	this(sd.Date other) { date_ = other; }

	/// Create a date from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.Date);
		date_ = epoch_ + ct.days(mg_date_days(mg_value_date(value.ptr)));
	}

	/// Return a printable string representation of this date.
	const (string) toString() const { return date_.toString; }

	/// Compares this date with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Date other) const { return date_ == other.date_; }

	/// Return internal `std.datetime.date.Date`.
	auto opCast(T : sd.Date)() const { return date_; }

	/// Returns days since Unix epoch.
	const (long) days() const { return (date_ - epoch_).total!"days"; }

package:
	/// Create a Date using the given `mg_date`.
	this(inout mg_date *ptr) {
		assert(ptr != null);
		date_ = epoch_ + ct.days(mg_date_days(ptr));
	}

	/// Returns the internal `mg_date` pointer.
	const (mg_date *) ptr() const {
		auto ptr = mg_date_make((date_ - epoch_).total!"days");
		assert(ptr != null);
		return ptr;
	}

private:
	sd.Date date_;
	alias date_ this;
}

static private sd.Date epoch_ = sd.Date(1970, 1, 1);

unittest {
	import sd = std.datetime.date;
	auto now = Date(sd.Date(2021, 10, 24));
	assert(now.toString == "2021-Oct-24");
	assert(now.toISOExtString == "2021-10-24");
	assert(now.toISOString == "20211024");
}

unittest {
	import testutils : connectContainer;
	import std.algorithm : count;
	import std.conv : to;

	auto client = connectContainer();
	assert(client);

	auto result = client.execute(`RETURN date("2038-01-20");`);
	assert(result, client.error);
	foreach (r; result) {
		assert(r.length == 1);
		assert(r[0].type() == Type.Date);
		assert(to!Date(r[0]).toISOExtString == "2038-01-20");
	}
}

unittest {
	import memgraph.enums : Type;
	import std.conv : to;

	auto dt = mg_date_make(42);
	assert(dt != null);

	auto d = Date(dt);
	assert(d.days == 42);

	const d1 = d;
	assert(d1 == d);

	assert(to!string(d) == "1970-Feb-12", to!string(d));

	auto d2 = Date(mg_date_copy(d.ptr));
	assert(d2 == d);

	const d3 = Date(d2);
	assert(d3 == d);

	const v = Value(d);
	const d4 = Date(v);
	assert(d4 == d);
	assert(v == d);
	assert(to!string(v) == to!string(d));

	d2 = d;
	assert(d2 == d);

	const v1 = Value(d2);
	assert(v1.type == Type.Date);
	const v2 = Value(d2);
	assert(v2.type == Type.Date);

	assert(v1 == v2);

	const d5 = Date(d3);
	assert(d5 == d3);
}
