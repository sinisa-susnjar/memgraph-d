/// Provides a wrapper around a `mg_point_3d`.
module memgraph.point3d;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Represents a single location in 3-dimensional space.
///
/// Contains SRID along with its x, y and z coordinates.
struct Point3d {
  /// Create a shallow copy of `other` point 3d.
  @nogc this(inout ref Point3d other) {
    this(other.ptr);
  }

  /// Create a point 3d from a Value.
  this(inout ref Value value) {
    assert(value.type == Type.Point3d);
    this(mg_value_point_3d(value.ptr));
  }

  /// Return a printable string representation of this time.
  string toString() const {
    import std.format : format;
    return format!("{srid:%s, x:%s, y:%s, z:%s}")(srid, x, y, z);
  }

  /// Compares this point 3d with `other`.
  /// Return: true if same, false otherwise.
  @nogc auto opEquals(const ref Point3d other) const {
    return Detail.arePoint3dsEqual(ptr_, other.ptr);
  }

  /// Return the hash code for this point 3d.
  @nogc ulong toHash() const {
    return cast(ulong)ptr_;
  }

  /// Returns SRID of the 3D point.
  @nogc auto srid() const { return mg_point_3d_srid(ptr_); }
  /// Returns the x coordinate of the 3D point.
  @nogc auto x() const { return mg_point_3d_x(ptr_); }
  /// Returns the y coordinate of the 3D point.
  @nogc auto y() const { return mg_point_3d_y(ptr_); }
  /// Returns the z coordinate of the 3D point.
  @nogc auto z() const { return mg_point_3d_z(ptr_); }

package:
  /// Create a Point3d using the given `mg_point_3d` pointer.
  @nogc this(const mg_point_3d *ptr) @trusted {
    assert(ptr != null);
    ptr_ = ptr;
  }

  /// Return pointer to internal `mg_point_3d`.
  @nogc auto ptr() const {
    return ptr_;
  }

private:
  const mg_point_3d *ptr_;
} // struct Point3d

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

  assert(to!string(t) == "{srid:42, x:2, y:3, z:7}", to!string(t));

  auto t2 = Point3d(mg_point_3d_copy(t.ptr));
  assert(t2 == t);

  const t3 = Point3d(t2);
  assert(t3 == t);

  const t5 = Point3d(t3);
  assert(t5 == t3);

  // only for coverage atm
  auto v1 = Value(mg_value_make_point_3d(mg_point_3d_copy(t.ptr)));
  auto p1 = Point3d(v1);
  assert(v1 == p1);

  assert(to!string(v1) == to!string(p1), to!string(v1));

  assert(cast(ulong)t.ptr == t.toHash);
}
