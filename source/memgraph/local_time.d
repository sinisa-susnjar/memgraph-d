/// Provides a wrapper around a `mg_local_time`.
module memgraph.local_time;

import memgraph.mgclient, memgraph.detail, memgraph.value;
import memgraph.atomic;

/// Represents local time.
///
/// Time is defined with nanoseconds since midnight.
struct LocalTime {
	/// Disable default constructor, to guarantee that this always has a valid ptr_.
	@disable this();
	/// Disable postblit in favour of copy-ctor.
	@disable this(this);

	/// Create a copy of `other` local time.
	this(ref LocalTime other) {
		ref_ = other.ref_;
	}

	/// Create a local time from a Value.
	this(const ref Value value) {
		this(mg_local_time_copy(mg_value_local_time(value.ptr)));
	}

	/// Assigns a local time to another. The target of the assignment gets detached from
	/// whatever local time it was attached to, and attaches itself to the new local time.
	ref LocalTime opAssign(LocalTime rhs) @safe return
	{
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this local time.
	const (string) toString() const {
		import std.conv : to;
		return to!string(nanoseconds);
	}

	/// Compares this local time with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref LocalTime other) const {
		return Detail.areLocalTimesEqual(ref_.data, other.ref_.data);
	}

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_local_time_nanoseconds(ref_.data); }

package:
	/// Create a LocalTime using the given `mg_local_time`.
	this(mg_local_time *ptr) @trusted
	{
		ref_ = SharedPtr!mg_local_time.make(ptr, (p) { mg_local_time_destroy(p); });
	}

	/// Create a LocalTime from a copy of the given `mg_local_time`.
	this(const mg_local_time *ptr) {
		assert(ptr != null);
		this(mg_local_time_copy(ptr));
	}

	auto ptr() const { return ref_.data; }

private:
	SharedPtr!mg_local_time ref_;
}

unittest {
	{
		import std.conv : to;
		import memgraph.enums;

		auto tm = mg_local_time_alloc(&mg_system_allocator);
		assert(tm != null);
		tm.nanoseconds = 42;

		auto t = LocalTime(tm);
		assert(t.nanoseconds == 42);

		const t1 = t;
		assert(t1 == t);

		assert(to!string(t) == "42");

		auto t2 = LocalTime(mg_local_time_copy(t.ptr));
		assert(t2 == t);

		const t3 = LocalTime(t2);
		assert(t3 == t);

		const v = Value(t);
		const t4 = LocalTime(v);
		assert(t4 == t);
		assert(v == t);
		assert(to!string(v) == to!string(t));

		t2 = t;
		assert(t2 == t);

		auto v1 = Value(t2);
		assert(v1.type == Type.LocalTime);
		auto v2 = Value(t2);
		assert(v2.type == Type.LocalTime);

		assert(v1 == v2);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
