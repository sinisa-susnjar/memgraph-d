/// Provides a wrapper around a `mg_time`.
module memgraph.time;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Represents time with its time zone.
///
/// Time is defined with nanoseconds since midnight.
/// Timezone is defined with seconds from UTC.
struct Time {
	/// Create a copy of `other` time.
	this(inout ref Time other) {
		this(mg_time_copy(other.ptr));
	}

	/// Create a time from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.Time);
		this(mg_time_copy(mg_value_time(value.ptr)));
	}

	/// Assigns a time to another. The target of the assignment gets detached from
	/// whatever time it was attached to, and attaches itself to the new time.
	ref Time opAssign(Time rhs) @safe return {
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this time.
	const (string) toString() const {
		import std.conv : to;
		return to!string(nanoseconds) ~ " " ~ to!string(tz_offset_seconds);
	}

	/// Compares this time with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Time other) const {
		return Detail.areTimesEqual(ptr_, other.ptr);
	}

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_time_nanoseconds(ptr_); }

	/// Returns time zone offset in seconds from UTC.
	const (long) tz_offset_seconds() const { return mg_time_tz_offset_seconds(ptr_); }

	this(this) {
		if (ptr_)
			ptr_ = mg_time_copy(ptr_);
	}

	@safe @nogc ~this() {
		if (ptr_)
			mg_time_destroy(ptr_);
	}

package:
	/// Create a Time using the given `mg_time`.
	this(mg_time *ptr) @trusted {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Time from a copy of the given `mg_time`.
	this(const mg_time *ptr) {
		assert(ptr != null);
		this(mg_time_copy(ptr));
	}

	const (mg_time *) ptr() const { return ptr_; }

private:
	mg_time *ptr_;
}

unittest {
	{
		import std.conv : to;
		import memgraph.enums;

		auto tm = mg_time_alloc(&mg_system_allocator);
		assert(tm != null);
		tm.nanoseconds = 42;
		tm.tz_offset_seconds = 23;

		auto t = Time(tm);
		assert(t.nanoseconds == 42);
		assert(t.tz_offset_seconds == 23);

		const t1 = t;
		assert(t1 == t);

		assert(to!string(t) == "42 23");

		auto t2 = Time(mg_time_copy(t.ptr));
		assert(t2 == t);

		const t3 = Time(t2);
		assert(t3 == t);

		const v = Value(t);
		const t4 = Time(v);
		assert(t4 == t);
		assert(v == t);
		assert(to!string(v) == to!string(t));

		t2 = t;
		assert(t2 == t);

		const v1 = Value(t2);
		assert(v1.type == Type.Time);
		const v2 = Value(t2);
		assert(v2.type == Type.Time);

		assert(v1 == v2);

		const t5 = Time(t3);
		assert(t5 == t3);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
