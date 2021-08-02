/// Provides a wrapper around a `mg_local_date_time`.
module memgraph.local_date_time;

import memgraph.mgclient, memgraph.detail, memgraph.value;
import memgraph.atomic;

/// Represents date and time without its time zone.
///
/// Date is defined with seconds since the Unix epoch.
/// Time is defined with nanoseconds since midnight.
struct LocalDateTime {
	/// Disable default constructor to guarantee that this always has a valid ptr_.
	@disable this();
	/// Disable postblit in favour of copy-ctor.
	@disable this(this);

	/// Create a copy of `other` local date time.
	this(ref LocalDateTime other) {
		ref_ = other.ref_;
	}

	/// Create a local date time from a Value.
	this(const ref Value value) {
		this(mg_local_date_time_copy(mg_value_local_date_time(value.ptr)));
	}

	/// Assigns a local date time to another. The target of the assignment gets detached from
	/// whatever local date time it was attached to, and attaches itself to the new local date time.
	ref LocalDateTime opAssign(LocalDateTime rhs) @safe return
	{
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this local date time.
	const (string) toString() const {
		import std.conv : to;
		return to!string(seconds) ~ " " ~ to!string(nanoseconds);
	}

	/// Compares this local date time with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref LocalDateTime other) const {
		return Detail.areLocalDateTimesEqual(ref_.data, other.ref_.data);
	}

	/// Returns seconds since Unix epoch.
	const (long) seconds() const { return mg_local_date_time_seconds(ref_.data); }

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_local_date_time_nanoseconds(ref_.data); }

package:
	/// Create a LocalDateTime using the given `mg_local_date_time`.
	this(mg_local_date_time *ptr) @trusted
	{
		ref_ = SharedPtr!mg_local_date_time.make(ptr, (p) { mg_local_date_time_destroy(p); });
	}

	/// Create a LocalDateTime from a copy of the given `mg_local_date_time`.
	this(const mg_local_date_time *ptr) {
		assert(ptr != null);
		this(mg_local_date_time_copy(ptr));
	}

	auto ptr() const { return ref_.data; }

private:
	SharedPtr!mg_local_date_time ref_;
}

unittest {
	{
		import std.conv : to;

		auto tm = mg_local_date_time_alloc(&mg_system_allocator);
		assert(tm != null);
		tm.seconds = 23;
		tm.nanoseconds = 42;

		auto t = LocalDateTime(tm);
		assert(t.seconds == 23);
		assert(t.nanoseconds == 42);

		const t1 = t;
		assert(t1 == t);

		assert(to!string(t) == "23 42");

		auto t2 = LocalDateTime(mg_local_date_time_copy(t.ptr));
		assert(t2 == t);

		const t3 = LocalDateTime(t2);
		assert(t3 == t);

		const v = Value(t);
		const t4 = LocalDateTime(v);
		assert(t4 == t);
		assert(v == t);
		assert(to!string(v) == to!string(t));

		t2 = t;
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
