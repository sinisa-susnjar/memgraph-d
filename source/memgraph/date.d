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
	/// Disable postblit in favour of copy-ctor.
	@disable this(this);

	/// Create a copy of `other` date.
	this(ref Date other) {
		ref_ = other.ref_;
	}

	/// Create a date from a Value.
	this(const ref Value value) {
		this(mg_date_copy(mg_value_date(value.ptr)));
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
		return Detail.areDatesEqual(ref_.data, other.ref_.data);
	}

	/// Returns days since Unix epoch.
	const (long) days() const {
		return mg_date_days(ref_.data);
	}

package:
	/// Create a Date using the given `mg_date`.
	this(mg_date *ptr) {
		assert(ptr != null);
		ref_ = SharedPtr!mg_date.make(ptr, (p) { mg_date_destroy(p); });
	}

	/// Create a Date from a copy of the given `mg_date`.
	this(const mg_date *ptr) {
		assert(ptr != null);
		this(mg_date_copy(ptr));
	}

	auto ptr() const { return ref_.data; }

private:
	SharedPtr!mg_date ref_;
}

unittest {
	{
		import std.conv : to;
		import memgraph.enums;

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
		assert(v == d);
		assert(to!string(v) == to!string(d));

		d2 = d;
		assert(d2 == d);

		auto v1 = Value(d2);
		assert(v1.type == Type.Date);
		auto v2 = Value(d2);
		assert(v2.type == Type.Date);

		assert(v1 == v2);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}
