/// Provides a wrapper around a `mg_date_time_zone_id`.
module memgraph.date_time_zone_id;

import memgraph.mgclient, memgraph.detail, memgraph.value;
import memgraph.atomic;

/// Represents date and time with its time zone.
///
/// Date is defined with seconds since the adjusted Unix epoch.
/// Time is defined with nanoseconds since midnight.
/// Timezone is defined with an identifier for a specific time zone.
struct DateTimeZoneId {
	/// Disable default constructor to guarantee that this always has a valid ptr_.
	@disable this();
	/// Disable postblit in favour of copy-ctor.
	@disable this(this);

	/// Create a copy of `other` date time zone id.
	this(ref DateTimeZoneId other) {
		ref_ = other.ref_;
	}

	/// Create a date time zone id from a Value.
	this(const ref Value value) {
		this(mg_date_time_zone_id_copy(mg_value_date_time_zone_id(value.ptr)));
	}

	/// Assigns a date time zone id to another. The target of the assignment gets detached from
	/// whatever date time zone id it was attached to, and attaches itself to the new date time zone id.
	ref DateTimeZoneId opAssign(DateTimeZoneId rhs) @safe return
	{
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this date time zone id.
	const (string) toString() const {
		import std.conv : to;
		return to!string(seconds) ~ " " ~ to!string(nanoseconds) ~ " " ~ to!string(tzId);
	}

	/// Compares this date time zone id with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref DateTimeZoneId other) const {
		return Detail.areDateTimeZoneIdsEqual(ref_.data, other.ref_.data);
	}

	/// Returns seconds since Unix epoch.
	const (long) seconds() const { return mg_date_time_zone_id_seconds(ref_.data); }

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_date_time_zone_id_nanoseconds(ref_.data); }

	/// Returns time zone represented by the identifier.
	const (long) tzId() const { return mg_date_time_zone_id_tz_id(ref_.data); }

package:
	/// Create a DateTimeZoneId using the given `mg_date_time_zone_id`.
	this(mg_date_time_zone_id *ptr) @trusted
	{
		ref_ = SharedPtr!mg_date_time_zone_id.make(ptr, (p) { mg_date_time_zone_id_destroy(p); });
	}

	auto ptr() const { return ref_.data; }

private:
	SharedPtr!mg_date_time_zone_id ref_;
}

unittest {
	{
		import std.conv : to;

		auto tm = mg_date_time_zone_id_alloc(&mg_system_allocator);
		assert(tm != null);
		tm.seconds = 23;
		tm.nanoseconds = 42;
		tm.tz_id = 1;

		auto t = DateTimeZoneId(tm);
		assert(t.seconds == 23);
		assert(t.nanoseconds == 42);
		assert(t.tzId == 1);

		const t1 = t;
		assert(t1 == t);

		assert(to!string(t) == "23 42 1");

		auto t2 = DateTimeZoneId(mg_date_time_zone_id_copy(t.ptr));
		assert(t2 == t);

		const t3 = DateTimeZoneId(t2);
		assert(t3 == t);

		const v = Value(t);
		const t4 = DateTimeZoneId(v);
		assert(t4 == t);

		t2 = t;
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}