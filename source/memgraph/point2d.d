/// Provides a wrapper around a `mg_point_2d`.
module memgraph.point2d;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Represents a single location in 2-dimensional space.
///
/// Contains SRID along with its x and y coordinates.
struct Point2d {
  /// Create a shallow copy of `other` point 2d.
  @nogc this(inout ref Point2d other) {
    this(other.ptr);
  }

  /// Create a point 2d from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.Point2d);
    this(mg_value_point_2d(value.ptr));
  }

  /// Compares this point 2d with `other`.
  /// Return: true if same, false otherwise.
  @nogc auto opEquals(const ref Point2d other) const {
    return Detail.arePoint2dsEqual(ptr_, other.ptr_);
  }

  /// Return the hash code for this point 2d.
  size_t toHash() const nothrow @safe {
    return cast(ulong)ptr_;
  }

  /// Return a printable string representation of this time.
  string toString() const {
    import std.format : format;
    return format!("{srid:%s, x:%s, y:%s}")(srid, x, y);
  }

  /// Returns SRID of the 2D point.
  @nogc auto srid() const { return mg_point_2d_srid(ptr_); }
  /// Returns the x coordinate of the 2D point.
  @nogc auto x() const { return mg_point_2d_x(ptr_); }
  /// Returns the y coordinate of the 2D point.
  @nogc auto y() const { return mg_point_2d_y(ptr_); }

package:
  /// Create a Point2d using the given `mg_point_2d` pointer.
  @nogc this(const mg_point_2d *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
  }

  /// Return pointer to internal `mg_point_2d`.
  @nogc auto ptr() const {
    return ptr_;
  }

private:
  const mg_point_2d *ptr_;
}

unittest {
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

  assert(to!string(t) == "{srid:42, x:6, y:7}", to!string(t));

  auto t2 = Point2d(mg_point_2d_copy(t.ptr));
  assert(t2 == t);

  const t3 = Point2d(t2);
  assert(t3 == t);

  const t5 = Point2d(t3);
  assert(t5 == t3);

  // only for coverage atm
  auto v1 = Value(mg_value_make_point_2d(mg_point_2d_copy(t.ptr)));
  auto p1 = Point2d(v1);
  assert(v1 == p1);

  assert(to!string(v1) == to!string(p1), to!string(v1));

  assert(cast(ulong)t.ptr == t.toHash);
}
