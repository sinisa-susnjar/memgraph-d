/// Provides a wrapper around a `mg_point_3d`.
module memgraph.point3d;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Represents a single location in 3-dimensional space.
///
/// Contains SRID along with its x, y and z coordinates.
struct Point3d {
	/// Create a deep copy of `other` point 3d.
	this(inout ref Point3d other) {
		this(mg_point_3d_copy(other.ptr));
	}

	/// Create a point 3d from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.Point3d);
		this(mg_point_3d_copy(mg_value_point_3d(value.ptr)));
	}

	/// Assigns a point 3d to another. The target of the assignment gets detached from
	/// whatever point 3d it was attached to, and attaches itself to the new point 3d.
	ref Point3d opAssign(Point3d rhs) @safe return {
		import std.algorithm.mutation : swap;
		swap(this, rhs);
		return this;
	}

	/// Return a printable string representation of this time.
	string toString() const {
		import std.conv : to;
		return to!string(srid) ~ " " ~ to!string(x) ~ " " ~ to!string(y) ~ " " ~ to!string(z);
	}

	/// Compares this point 3d with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Point3d other) const {
		return Detail.arePoint3dsEqual(ptr_, other.ptr);
	}

	/// Returns SRID of the 3D point.
	long srid() const { return mg_point_3d_srid(ptr_); }
	/// Returns the x coordinate of the 3D point.
	double x() const { return mg_point_3d_x(ptr_); }
	/// Returns the y coordinate of the 3D point.
	double y() const { return mg_point_3d_y(ptr_); }
	/// Returns the z coordinate of the 3D point.
	double z() const { return mg_point_3d_z(ptr_); }

	this(this) {
		if (ptr_)
			ptr_ = mg_point_3d_copy(ptr_);
	}

	@safe @nogc ~this() {
		if (ptr_)
			mg_point_3d_destroy(ptr_);
	}

package:
	/// Create a Point3d using the given `mg_point_3d`.
	this(mg_point_3d *ptr) @trusted {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Point3d from a copy of the given `mg_point_3d`.
	this(const mg_point_3d *ptr) {
		assert(ptr != null);
		this(mg_point_3d_copy(ptr));
	}

	const (mg_point_3d *) ptr() const { return ptr_; }

private:
	mg_point_3d *ptr_;
}

unittest {
	import std.conv : to;
	import memgraph.enums;

	auto tm = mg_point_3d_alloc(&mg_system_allocator);
	assert(tm != null);
	tm.srid = 42;
	tm.x = 2;
	tm.y = 3;
	tm.z = 7;

	auto t = Point3d(tm);
	assert(t.srid == 42);
	assert(t.x == 2);
	assert(t.y == 3);
	assert(t.z == 7);

	const t1 = t;
	assert(t1 == t);

	assert(to!string(t) == "42 2 3 7");

	auto t2 = Point3d(mg_point_3d_copy(t.ptr));
	assert(t2 == t);

	const t3 = Point3d(t2);
	assert(t3 == t);

	const v = Value(t);
	const t4 = Point3d(v);
	assert(t4 == t);
	assert(v == t);
	assert(to!string(v) == to!string(t));

	t2 = t;
	assert(t2 == t);

	const v1 = Value(t2);
	assert(v1.type == Type.Point3d);
	const v2 = Value(t2);
	assert(v2.type == Type.Point3d);

	assert(v1 == v2);

	const t5 = Point3d(t3);
	assert(t5 == t3);
}
