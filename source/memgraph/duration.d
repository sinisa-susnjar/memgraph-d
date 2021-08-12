/// Provides a wrapper around a `mg_duration`.
module memgraph.duration;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Represents a temporal amount which captures the difference in time
/// between two instants.
///
/// Duration is defined with months, days, seconds, and nanoseconds.
/// Note: Duration can be negative.
struct Duration {

	/// Create a copy of `other` duration.
	this(inout ref Duration other) {
		this(mg_duration_copy(other.ptr));
	}

	/// Create a duration from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.Duration);
		this(mg_duration_copy(mg_value_duration(value.ptr)));
	}

	/// Assigns a duration to another. The target of the assignment gets detached from
	/// whatever duration it was attached to, and attaches itself to the new duration.
	ref Duration opAssign(Duration rhs) @safe return {
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this duration.
	const (string) toString() const {
		import std.conv : to;
		return to!string(months) ~ " " ~ to!string(days) ~ " " ~ to!string(seconds) ~ " " ~ to!string(nanoseconds);
	}

	/// Compares this duration with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Duration other) const {
		return Detail.areDurationsEqual(ptr_, other.ptr);
	}

	/// Returns the months part of the temporal amount.
	const (long) months() const { return mg_duration_months(ptr_); }

	/// Returns the days part of the temporal amount.
	const (long) days() const { return mg_duration_days(ptr_); }

	/// Returns the seconds part of the temporal amount.
	const (long) seconds() const { return mg_duration_seconds(ptr_); }

	/// Returns the nanoseconds part of the temporal amount.
	const (long) nanoseconds() const { return mg_duration_nanoseconds(ptr_); }

	this(this) {
		if (ptr_)
			ptr_ = mg_duration_copy(ptr_);
	}

	@safe @nogc ~this() {
		if (ptr_)
			mg_duration_destroy(ptr_);
	}

package:
	/// Create a Duration using the given `mg_duration`.
	this(mg_duration *ptr) @trusted {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Duration from a copy of the given `mg_duration`.
	this(const mg_duration *ptr) {
		assert(ptr != null);
		this(mg_duration_copy(ptr));
	}

	const (mg_duration *) ptr() const { return ptr_; }

private:
	mg_duration *ptr_;
}

unittest {
	import std.conv : to;
	import memgraph.enums;

	auto tm = mg_duration_alloc(&mg_system_allocator);
	assert(tm != null);
	tm.months = 3;
	tm.days = 10;
	tm.seconds = 42;
	tm.nanoseconds = 23;

	auto t = Duration(tm);
	assert(t.months == 3);
	assert(t.days == 10);
	assert(t.seconds == 42);
	assert(t.nanoseconds == 23);

	const t1 = t;
	assert(t1 == t);

	assert(to!string(t) == "3 10 42 23");

	auto t2 = Duration(t.ptr);
	assert(t2 == t);

	const t3 = Duration(t2);
	assert(t3 == t);

	const v = Value(t);
	const t4 = Duration(v);
	assert(t4 == t);
	assert(v == t);
	assert(to!string(v) == to!string(t));

	t2 = t;
	assert(t2 == t);

	const v1 = Value(t2);
	assert(v1.type == Type.Duration);
	const v2 = Value(t2);
	assert(v2.type == Type.Duration);

	assert(v1 == v2);

	const t5 = Duration(t3);
	assert(t5 == t3);
}
