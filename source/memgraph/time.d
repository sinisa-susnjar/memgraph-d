/// Provides a wrapper around a `mg_time`.
module memgraph.time;

import memgraph.mgclient, memgraph.detail, memgraph.value;
import memgraph.atomic;

/// Represents time with its time zone.
///
/// Time is defined with nanoseconds since midnight.
/// Timezone is defined with seconds from UTC.
struct Time {
	/// Disable default constructor, to guarantee that this always has a valid ptr_.
	@disable this();

	/// Postblit, create a copy of the time from source.
	this(this) @safe nothrow
	{
		// if (!ref_) return;
		// ref_.inc();
	}

	/// Create a copy of `other` time.
	this(ref Time other) {
		// other.ref_.inc();
		ref_ = other.ref_;
	}

	/// Create a time from a Value.
	this(const ref Value value) {
		this(mg_time_copy(mg_value_time(value.ptr)));
	}

	/// Destructor. Detaches from the underlying `mg_time`.
	@safe @nogc ~this() pure nothrow {
		// Pointer to AtomicRef not needed any more. GC will take care of it.
		// ref_ = null;
	}

	/// Assigns a time to another. The target of the assignment gets detached from
	/// whatever time it was attached to, and attaches itself to the new time.
	ref Time opAssign(Time rhs) @safe return
	{
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
		return Detail.areTimesEqual(ref_.ptr, other.ref_.ptr);
	}

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_time_nanoseconds(ref_.ptr); }

	/// Returns time zone offset in seconds from UTC.
	const (long) tz_offset_seconds() const { return mg_time_tz_offset_seconds(ref_.ptr); }

package:
	/*
	/// Create a Time from a copy of the given `mg_time`.
	this(const mg_time *const_ptr) {
		assert(const_ptr != null);
		this(mg_time_copy(const_ptr));
	}
	*/

	/// Create a Time using the given `mg_time`.
	this(mg_time *ptr) @trusted
	{
		// import core.stdc.stdlib : malloc;
		// import std.exception : enforce;
		// assert(!ref_);
		// ref_ = enforce(new AtomicRef!(mg_time, mg_time_destroy)(ptr, 1), "Out of memory");
		// ref_ = SharedPtr!(typeof(ptr)).make(ptr, (p) { mg_time_destroy(cast(mg_time*)p); });
		ref_ = SharedPtr!(shared mg_time*).make(cast(shared mg_time *)ptr, (p) { mg_time_destroy(cast(mg_time*)p); });
		// assert(ref_);
	}

	auto ptr() const { return ref_.ptr; }

private:
	// AtomicRef!(mg_time, mg_time_destroy) *ref_;
	SharedPtr!(shared mg_time*) ref_;
}

unittest {
	{
		import std.conv : to;

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

		t2 = t;
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
