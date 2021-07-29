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

	/// Postblit, create a copy of the local time from source.
	this(this) @safe nothrow
	{
		if (!ref_) return;
		ref_.inc();
	}

	/// Create a copy of `other` local time.
	this(ref LocalTime other) {
		other.ref_.inc();
		ref_ = other.ref_;
	}

	/// Create a local time from a Value.
	this(const ref Value value) {
		this(mg_local_time_copy(mg_value_local_time(value.ptr)));
	}

	/// Destructor. Detaches from the underlying `mg_local_time`.
	@safe @nogc ~this() pure nothrow {
		// Pointer to AtomicRef not needed any more. GC will take care of it.
		ref_ = null;
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
		return Detail.areLocalTimesEqual(ref_.ptr, other.ref_.ptr);
	}

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_local_time_nanoseconds(ref_.ptr); }

package:
	/// Create a LocalTime using the given `mg_local_time`.
	this(mg_local_time *ptr) @trusted
	{
		import core.stdc.stdlib : malloc;
		import std.exception : enforce;
		assert(!ref_);
		ref_ = enforce(new AtomicRef!(mg_local_time, mg_local_time_destroy)(ptr, 1), "Out of memory");
		assert(ref_);
	}

	auto ptr() const { return ref_.ptr; }

private:
	AtomicRef!(mg_local_time, mg_local_time_destroy) *ref_;
}

unittest {
	{
		import std.conv : to;

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

		t2 = t;
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
