/// Provides a wrapper around a `mg_date_time_zone_id`.
module memgraph.date_time_zone_id;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Represents date and time with its time zone.
///
/// Date is defined with seconds since the adjusted Unix epoch.
/// Time is defined with nanoseconds since midnight.
/// Timezone is defined with an identifier for a specific time zone.
struct DateTimeZoneId {

	/// Create a deep copy of `other` date time zone id.
	this(inout ref DateTimeZoneId other) {
		this(mg_date_time_zone_id_copy(other.ptr));
	}

	/// Create a date time zone id from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.DateTimeZoneId);
		this(mg_date_time_zone_id_copy(mg_value_date_time_zone_id(value.ptr)));
	}

	/// Assigns a date time zone id to another. The target of the assignment gets detached from
	/// whatever date time zone id it was attached to, and attaches itself to the new date time zone id.
	ref DateTimeZoneId opAssign(DateTimeZoneId rhs) @safe return {
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this date time zone id.
	string toString() const {
		import std.conv : to;
		return to!string(seconds) ~ " " ~ to!string(nanoseconds) ~ " " ~ to!string(tzId);
	}

	/// Compares this date time zone id with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref DateTimeZoneId other) const {
		return Detail.areDateTimeZoneIdsEqual(ptr_, other.ptr);
	}

	/// Returns seconds since Unix epoch.
	long seconds() const { return mg_date_time_zone_id_seconds(ptr_); }

	/// Returns nanoseconds since midnight.
	long nanoseconds() const { return mg_date_time_zone_id_nanoseconds(ptr_); }

	/// Returns time zone represented by the identifier.
	long tzId() const { return mg_date_time_zone_id_tz_id(ptr_); }

	this(this) {
		if (ptr_)
			ptr_ = mg_date_time_zone_id_copy(ptr_);
	}

	@safe @nogc ~this() {
		if (ptr_)
			mg_date_time_zone_id_destroy(ptr_);
	}

package:
	/// Create a DateTimeZoneId using the given `mg_date_time_zone_id`.
	this(mg_date_time_zone_id *ptr) @trusted {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a DateTimeZoneId from a copy of the given `mg_date_time_zone_id`.
	this(const mg_date_time_zone_id *ptr) {
		assert(ptr != null);
		this(mg_date_time_zone_id_copy(ptr));
	}

	const (mg_date_time_zone_id *) ptr() const { return ptr_; }

private:
	mg_date_time_zone_id *ptr_;
}

unittest {
	{
		import std.conv : to;
		import memgraph.enums;

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
		assert(v == t);
		assert(to!string(v) == to!string(t));

		t2 = t;
		assert(t2 == t);

		const v1 = Value(t2);
		assert(v1.type == Type.DateTimeZoneId);
		const v2 = Value(t2);
		assert(v2.type == Type.DateTimeZoneId);

		assert(v1 == v2);

		const t5 = DateTimeZoneId(t3);
		assert(t5 == t3);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
