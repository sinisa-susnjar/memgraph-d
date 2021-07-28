/// Provides a wrapper around a `mg_date`.
module memgraph.date;

import memgraph.mgclient, memgraph.detail, memgraph.value;
import memgraph.atomic;

/// Represents a date.
///
/// Date is defined with number of days since the Unix epoch.
struct Date {
	/// Disable default constructor, to guarantee that this always has a valid ptr_.
	@disable this();

	/// Postblit, create a copy of the date from source.
	this(this) {
		if (!ref_) return;
		ref_.inc();
	}

	/// Create a copy of `other` date.
	this(ref Date other) {
		other.ref_.inc();
		ref_ = other.ref_;
	}

	/// Create a date from a Value.
	this(const ref Value value) {
		this(mg_date_copy(mg_value_date(value.ptr)));
	}

	/// Destructor. Detaches from the underlying `mg_date`.
	@safe @nogc ~this() pure nothrow {
		// Pointer to AtomicRef not needed any more. GC will take care of it.
		ref_ = null;
	}

	/// Assigns a date to another. The target of the assignment gets detached from
	/// whatever date it was attached to, and attaches itself to the new date.
	ref Date opAssign(Date rhs) @safe return
	{
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this date.
	const (string) toString() const {
		import std.conv : to;
		return to!string(days);
	}

	/// Compares this date with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Date other) const {
		return Detail.areDatesEqual(ref_.ptr, other.ref_.ptr);
	}

	/// Returns days since Unix epoch.
	const (long) days() const {
		return mg_date_days(ref_.ptr);
	}

package:
	/// Create a Date using the given `mg_date`.
	this(mg_date *ptr) {
		import core.stdc.stdlib : malloc;
		import std.exception : enforce;
		assert(!ref_);
		ref_ = enforce(new AtomicRef!(mg_date, mg_date_destroy)(ptr, 1), "Out of memory");
		assert(ref_);
	}

	/*
	/// Create a Date from a copy of the given `mg_date`.
	this(const mg_date *const_ptr) {
		assert(const_ptr != null);
		this(mg_date_copy(const_ptr));
	}
	*/

	auto ptr() const { return ref_.ptr; }

private:
	AtomicRef!(mg_date, mg_date_destroy) *ref_;
}

unittest {
	{
		import std.conv : to;

		auto dt = mg_date_alloc(&mg_system_allocator);
		assert(dt != null);
		dt.days = 42;

		auto d = Date(dt);
		assert(d.days == 42);
		assert(d.ptr == dt);

		const d1 = d;
		assert(d1 == d);

		assert(to!string(d) == "42");

		auto d2 = Date(mg_date_copy(d.ptr));
		assert(d2 == d);

		const d3 = Date(d2);
		assert(d3 == d);

		const v = Value(d);
		const d4 = Date(v);
		assert(d4 == d);

		d2 = d;
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
