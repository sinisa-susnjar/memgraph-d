/// Provides a wrapper around a `mg_time`.
module memgraph.time;

import memgraph.mgclient, memgraph.detail, memgraph.value;

/// Represents time with its time zone.
///
/// Time is defined with nanoseconds since midnight.
/// Timezone is defined with seconds from UTC.
struct Time {

	/// Disable default constructor, to guarantee that this always has a valid ptr_.
	@disable this();

	/// Postblit, create a copy of the time from source.
	this(this) {
		if (ptr_)
			ptr_ = mg_time_copy(ptr_);
	}

	/// Create a copy of `other` time.
	this(const ref Time other) {
		this(mg_time_copy(other.ptr_));
	}

	/// Create a time from a Value.
	this(const ref Value value) {
		this(mg_time_copy(mg_value_time(value.ptr)));
	}

	/// Destructor. Destroys the internal `mg_time`.
	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_time_destroy(ptr_);
	}

	/// Return a printable string representation of this time.
	const (string) toString() const {
		import std.conv : to;
		return to!string(nanoseconds) ~ " " ~ to!string(tz_offset_seconds);
	}

	/// Compares this time with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Time other) const {
		return Detail.areTimesEqual(ptr_, other.ptr_);
	}

	/// Returns nanoseconds since midnight.
	const (long) nanoseconds() const { return mg_time_nanoseconds(ptr_); }

	/// Returns time zone offset in seconds from UTC.
	const (long) tz_offset_seconds() const { return mg_time_tz_offset_seconds(ptr_); }

package:
	/// Create a Time using the given `mg_time`.
	this(mg_time *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Time from a copy of the given `mg_time`.
	this(const mg_time *const_ptr) {
		assert(const_ptr != null);
		this(mg_time_copy(const_ptr));
	}

	auto ptr() const { return ptr_; }

private:
	mg_time *ptr_;
}

unittest {
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

	const t2 = Time(t.ptr);
	assert(t2 == t);

	const t3 = Time(t2);
	assert(t3 == t);

	const v = Value(t);
	const t4 = Time(v);
	assert(t4 == t);
}
