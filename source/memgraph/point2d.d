/// Provides a wrapper around a `mg_point_2d`.
module memgraph.point2d;

import memgraph.mgclient, memgraph.detail, memgraph.value;
import memgraph.atomic;

/// Represents a single location in 2-dimensional space.
///
/// Contains SRID along with its x and y coordinates.
struct Point2d {
	/// Disable default constructor to guarantee that this always has a valid ptr_.
	@disable this();
	/// Disable postblit in favour of copy-ctor.
	@disable this(this);

	/// Create a copy of `other` point 2d.
	this(ref Point2d other) {
		ref_ = other.ref_;
	}

	/// Create a point 2d from a Value.
	this(const ref Value value) {
		assert(value.type == Type.Point2d);
		this(mg_point_2d_copy(mg_value_point_2d(value.ptr)));
	}

	/// Assigns a point 2d to another. The target of the assignment gets detached from
	/// whatever point 2d it was attached to, and attaches itself to the new point 2d.
	ref Point2d opAssign(Point2d rhs) @safe return
	{
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this time.
	string toString() const {
		import std.conv : to;
		return to!string(srid) ~ " " ~ to!string(x) ~ " " ~ to!string(y);
	}

	/// Compares this point 2d with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Point2d other) const {
		return Detail.arePoint2dsEqual(ref_.data, other.ref_.data);
	}

	/// Returns SRID of the 2D point.
	long srid() const { return mg_point_2d_srid(ref_.data); }
	/// Returns the x coordinate of the 2D point.
	double x() const { return mg_point_2d_x(ref_.data); }
	/// Returns the y coordinate of the 2D point.
	double y() const { return mg_point_2d_y(ref_.data); }

package:
	/// Create a Point2d using the given `mg_point_2d`.
	this(mg_point_2d *ptr) @trusted
	{
		assert(ptr != null);
		ref_ = SharedPtr!mg_point_2d.make(ptr, (p) { mg_point_2d_destroy(p); });
	}

	/// Create a Point2d from a copy of the given `mg_point_2d`.
	this(const mg_point_2d *ptr) {
		assert(ptr != null);
		this(mg_point_2d_copy(ptr));
	}

	auto ptr() const { return ref_.data; }

private:
	SharedPtr!mg_point_2d ref_;
}

unittest {
	{
		import std.conv : to;
		import memgraph.enums;

		auto tm = mg_point_2d_alloc(&mg_system_allocator);
		assert(tm != null);
		tm.srid = 42;
		tm.x = 6;
		tm.y = 7;

		auto t = Point2d(tm);
		assert(t.srid == 42);
		assert(t.x == 6);
		assert(t.y == 7);

		const t1 = t;
		assert(t1 == t);

		assert(to!string(t) == "42 6 7");

		auto t2 = Point2d(mg_point_2d_copy(t.ptr));
		assert(t2 == t);

		const t3 = Point2d(t2);
		assert(t3 == t);

		const v = Value(t);
		const t4 = Point2d(v);
		assert(t4 == t);
		assert(v == t);
		assert(to!string(v) == to!string(t));

		t2 = t;
		assert(t2 == t);

		auto v1 = Value(t2);
		assert(v1.type == Type.Point2d);
		auto v2 = Value(t2);
		assert(v2.type == Type.Point2d);

		assert(v1 == v2);
	}
	// Force garbage collection for full code coverage
	import core.memory;
	GC.collect();
}