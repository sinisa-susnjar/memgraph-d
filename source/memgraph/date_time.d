/// Provides a wrapper around a `mg_date_time`.
module memgraph.date_time;

import memgraph.mgclient, memgraph.detail, memgraph.value;
import memgraph.atomic;

/// Represents date and time with its time zone.
///
/// Date is defined with seconds since the adjusted Unix epoch.
/// Time is defined with nanoseconds since midnight.
/// Time zone is defined with minutes from UTC.
struct DateTime {
	/// Disable default constructor to guarantee that this always has a valid ptr_.
	@disable this();
	/// Disable postblit in favour of copy-ctor.
	@disable this(this);

	/// Create a copy of `other` date time.
	this(ref DateTime other) {
		ref_ = other.ref_;
	}

	/// Create a date time from a Value.
	this(const ref Value value) {
		this(mg_date_time_copy(mg_value_date_time(value.ptr)));
	}

	/// Assigns a date time to another. The target of the assignment gets detached from
	/// whatever date time it was attached to, and attaches itself to the new date time.
	ref DateTime opAssign(DateTime rhs) @safe return
	{
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this date time.
	const (string) toString() const {
		import std.conv : to;
		return to!string(seconds) ~ " " ~ to!string(nanoseconds) ~ " " ~ to!string(tz_offset_minutes);
	}

	/// Compares this date time with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref DateTime other) const {
		return Detail.areDateTimesEqual(ref_.data, other.ref_.data);
	}

	/// Returns seconds since Unix epoch.
	const (long) seconds() const { return mg_date_time_seconds(ref_.data); }

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_date_time_nanoseconds(ref_.data); }

	/// Returns time zone offset in minutes from UTC.
	const (long) tz_offset_minutes() const { return mg_date_time_tz_offset_minutes(ref_.data); }

package:
	/// Create a DateTime using the given `mg_date_time`.
	this(mg_date_time *ptr) @trusted
	{
		assert(ptr != null);
		ref_ = SharedPtr!mg_date_time.make(ptr, (p) { mg_date_time_destroy(p); });
	}

	/// Create a DateTime from a copy of the given `mg_date_time`.
	this(const mg_date_time *ptr) {
		assert(ptr != null);
		this(mg_date_time_copy(ptr));
	}

	auto ptr() const { return ref_.data; }

private:
	SharedPtr!mg_date_time ref_;
}

unittest {
	{
		import std.conv : to;
		import memgraph.enums;

		auto tm = mg_date_time_alloc(&mg_system_allocator);
		assert(tm != null);
		tm.seconds = 23;
		tm.nanoseconds = 42;
		tm.tz_offset_minutes = 60;

		auto t = DateTime(tm);
		assert(t.seconds == 23);
		assert(t.nanoseconds == 42);
		assert(t.tz_offset_minutes == 60);

		const t1 = t;
		assert(t1 == t);

		assert(to!string(t) == "23 42 60");

		auto t2 = DateTime(mg_date_time_copy(t.ptr));
		assert(t2 == t);

		const t3 = DateTime(t2);
		assert(t3 == t);

		const v = Value(t);
		const t4 = DateTime(v);
		assert(t4 == t);
		assert(v == t);
		assert(to!string(v) == to!string(t));

		t2 = t;
		assert(t2 == t);

		const v1 = Value(t2);
		assert(v1.type == Type.DateTime);
		const v2 = Value(t2);
		assert(v2.type == Type.DateTime);

		assert(v1 == v2);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
