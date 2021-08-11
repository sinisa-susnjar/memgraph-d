/// Provides a wrapper around a `mg_local_date_time`.
module memgraph.local_date_time;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Represents date and time without its time zone.
///
/// Date is defined with seconds since the Unix epoch.
/// Time is defined with nanoseconds since midnight.
struct LocalDateTime {

	/// Create a copy of `other` local date time.
	this(inout ref LocalDateTime other) {
		this(mg_local_date_time_copy(other.ptr));
	}

	/// Create a local date time from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.LocalDateTime);
		this(mg_local_date_time_copy(mg_value_local_date_time(value.ptr)));
	}

	/// Assigns a local date time to another. The target of the assignment gets detached from
	/// whatever local date time it was attached to, and attaches itself to the new local date time.
	ref LocalDateTime opAssign(LocalDateTime rhs) @safe return {
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
		return Detail.areLocalDateTimesEqual(ptr_, other.ptr);
	}

	/// Returns seconds since Unix epoch.
	const (long) seconds() const { return mg_local_date_time_seconds(ptr_); }

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_local_date_time_nanoseconds(ptr_); }

	this(this) {
		if (ptr_)
			ptr_ = mg_local_date_time_copy(ptr_);
	}

	@safe @nogc ~this() {
		if (ptr_)
			mg_local_date_time_destroy(ptr_);
	}

package:
	/// Create a LocalDateTime using the given `mg_local_date_time`.
	this(mg_local_date_time *ptr) @trusted {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a LocalDateTime from a copy of the given `mg_local_date_time`.
	this(const mg_local_date_time *ptr) {
		assert(ptr != null);
		this(mg_local_date_time_copy(ptr));
	}

	const (mg_local_date_time *) ptr() const { return ptr_; }

private:
	mg_local_date_time *ptr_;
}

unittest {
	{
		import std.conv : to;
		import memgraph.enums;

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

		auto t2 = LocalDateTime(t.ptr);
		assert(t2 == t);

		const t3 = LocalDateTime(t2);
		assert(t3 == t);

		const v = Value(t);
		const t4 = LocalDateTime(v);
		assert(t4 == t);
		assert(v == t);
		assert(to!string(v) == to!string(t));

		t2 = t;
		assert(t2 == t);

		const v1 = Value(t2);
		assert(v1.type == Type.LocalDateTime);
		const v2 = Value(t2);
		assert(v2.type == Type.LocalDateTime);

		assert(v1 == v2);

		const t5 = LocalDateTime(t3);
		assert(t5 == t3);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
