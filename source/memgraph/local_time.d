/// Provides a wrapper around a `mg_local_time`.
module memgraph.local_time;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Represents local time.
///
/// Time is defined with nanoseconds since midnight.
struct LocalTime {
  /// Create a copy of `other` local time.
  this(inout ref LocalTime other) {
    this(mg_local_time_copy(other.ptr));
  }

  /// Create a local time from a Value.
  this(inout ref Value value) {
    assert(value.type == Type.LocalTime);
    this(mg_local_time_copy(mg_value_local_time(value.ptr)));
  }

  /// Assigns a local time to another. The target of the assignment gets detached from
  /// whatever local time it was attached to, and attaches itself to the new local time.
  ref LocalTime opAssign(LocalTime rhs) @safe return {
    import std.algorithm.mutation : swap;
    swap(this, rhs);
    return this;
  }

  /// Return a printable string representation of this local time.
  const (string) toString() const {
    import std.conv : to;
    return to!string(nanoseconds);
  }

  /// Compares this local time with `other`.
  /// Return: true if same, false otherwise.
  bool opEquals(const ref LocalTime other) const {
    return Detail.areLocalTimesEqual(ptr_, other.ptr);
  }

  /// Returns nanoseconds since midnight.
  const (long) nanoseconds() const { return mg_local_time_nanoseconds(ptr_); }

  this(this) {
    if (ptr_)
      ptr_ = mg_local_time_copy(ptr_);
  }

  @safe @nogc ~this() {
    if (ptr_)
      mg_local_time_destroy(ptr_);
  }

package:
  /// Create a LocalTime using the given `mg_local_time`.
  this(mg_local_time *ptr) @trusted {
    assert(ptr != null);
    ptr_ = ptr;
  }

  /// Create a LocalTime from a copy of the given `mg_local_time`.
  this(const mg_local_time *ptr) {
    assert(ptr != null);
    this(mg_local_time_copy(ptr));
  }

  const (mg_local_time *) ptr() const { return ptr_; }

private:
  mg_local_time *ptr_;
}

unittest {
  import std.conv : to;
  import memgraph.enums;

  auto tm = mg_local_time_alloc(&mg_system_allocator);
  assert(tm != null);
  tm.nanoseconds = 42;

  auto t = LocalTime(tm);
  assert(t.nanoseconds == 42);

  const t1 = t;
  assert(t1 == t);

  assert(to!string(t) == "42");

  auto t2 = LocalTime(t.ptr);
  assert(t2 == t);

  const t3 = LocalTime(t2);
  assert(t3 == t);

  const v = Value(t);
  const t4 = LocalTime(v);
  assert(t4 == t);
  assert(v == t);
  assert(to!string(v) == to!string(t));

  t2 = t;
  assert(t2 == t);

  const v1 = Value(t2);
  assert(v1.type == Type.LocalTime);
  const v2 = Value(t2);
  assert(v2.type == Type.LocalTime);

  assert(v1 == v2);

  const t5 = LocalTime(t3);
  assert(t5 == t3);
}
