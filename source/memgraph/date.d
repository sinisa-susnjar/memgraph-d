/// Provides a wrapper around a `mg_date`.
module memgraph.date;

import memgraph.mgclient, memgraph.detail, memgraph.value;

/// Represents a date.
///
/// Date is defined with number of days since the Unix epoch.
struct Date {

	/// Disable default constructor, to guarantee that this always has a valid ptr_.
	@disable this();

	/// Postblit, create a copy of the date from source.
	this(this) {
		if (ptr_)
			ptr_ = mg_date_copy(ptr_);
	}

	/// Create a copy of `other` date.
	this(const ref Date other) {
		this(mg_date_copy(other.ptr_));
	}

	/// Create a date from a Value.
	this(const ref Value value) {
		this(mg_date_copy(mg_value_date(value.ptr)));
	}

	/// Destructor. Destroys the internal `mg_date`.
	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_date_destroy(ptr_);
	}

	/// Return a printable string representation of this date.
	const (string) toString() const {
		import std.conv : to;
		return to!string(days);
	}

	/// Compares this date with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Date other) const {
		return Detail.areDatesEqual(ptr_, other.ptr_);
	}

	/// Returns days since Unix epoch.
	const (long) days() const {
		return mg_date_days(ptr_);
	}

package:
	/// Create a Date using the given `mg_date`.
	this(mg_date *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Date from a copy of the given `mg_date`.
	this(const mg_date *const_ptr) {
		assert(const_ptr != null);
		this(mg_date_copy(const_ptr));
	}

	auto ptr() const { return ptr_; }

private:
	mg_date *ptr_;
}

// Extern C definitions for allocation of memgraph internal types.
extern (C) {
	// Need at least an empty definition for extern struct.
	struct mg_allocator {}
	extern shared mg_allocator mg_system_allocator;
	@safe @nogc mg_date *mg_date_alloc(shared mg_allocator *alloc) pure nothrow;
}

unittest {
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

	const d2 = Date(d.ptr);
	assert(d2 == d);

	const d3 = Date(d2);
	assert(d3 == d);

	const v = Value(d);
	const d4 = Date(v);
	assert(d4 == d);
}
