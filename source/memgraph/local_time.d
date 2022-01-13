/// Provides a wrapper around a `mg_local_time`. Uses `std.datetime.systime.SysTime` internally.
module memgraph.local_time;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;
import st = std.datetime.systime;
import sd = std.datetime.date;
import ct = core.time;

/// Represents a local time.
/// Time is defined with nanoseconds since midnight.
struct LocalTime {
  /// Create a shallow copy of `other` LocalTime.
  this(inout ref LocalTime other) {
    this(other.ptr);
  }

  /// Create a local time from a Value.
  this(inout ref Value value) {
    assert(value.type == Type.LocalTime);
    this(mg_value_local_time(value.ptr));
  }

  /// Compares this local time with `other`.
  /// Return: true if same, false otherwise.
  @nogc auto opEquals(const ref LocalTime other) const {
    return Detail.areLocalTimesEqual(ptr_, other.ptr_);
  }

  /// Return a printable string representation of this local time.
  string toString() const {
    import std.format;
    return format!("%02d:%02d:%02d.%09d")(localTime_.hour, localTime_.minute, localTime_.second,
                  localTime_.fracSecs.total!"nsecs");
  }

  /// Return the hash code for this local time.
  @nogc ulong toHash() const {
    return cast(ulong)ptr_;
  }

  /// Returns nanoseconds since midnight.
  @nogc auto nanoseconds() const { return nanoSeconds_; }

package:
  /// Create a LocalTime using the given `mg_local_time` pointer.
  this(inout mg_local_time *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
    nanoSeconds_ = mg_local_time_nanoseconds(ptr);
    immutable auto now = st.Clock.currTime();
    localTime_ = st.SysTime(sd.DateTime(now.year, now.month, now.day, 0, 0, 0));
    localTime_ += ct.nsecs(nanoSeconds_);
  }

  /// Returns the internal `mg_local_time` pointer.
  @nogc auto ptr() inout {
    return ptr_;
  }

private:
  const mg_local_time *ptr_;
  st.SysTime localTime_;
  long nanoSeconds_;
  alias localTime_ this;
} // struct LocalTime

unittest {
  import testutils : connectContainer;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  auto result = client.execute(`return localtime('12:34:56.100');`);
  assert(result, client.error);
  foreach (r; result) {
    assert(r.length == 1);
    assert(r[0].type() == Type.LocalTime);
    const t = to!LocalTime(r[0]);
    assert(t.toString == "12:34:56.100000000", t.toString);
    assert(t.nanoseconds == 45_296_100_000_000);
  }
}

unittest {
  import std.conv : to;

  auto tm = mg_local_time_make(45_296_100_000_000);
  assert(tm != null);

  auto t = LocalTime(tm);
  assert(t.nanoseconds == 45_296_100_000_000);

  const t1 = t;
  assert(t1 == t);

  assert(to!string(t) == "12:34:56.100000000");
  assert(t.toString == "12:34:56.100000000");

  st.SysTime st = t;
  import std.format;
  assert(format!("%02d:%02d:%02d.%09d")(st.hour, st.minute, st.second,
                st.fracSecs.total!"nsecs") == t.toString);

  auto t2 = LocalTime(t.ptr);
  assert(t2 == t);

  const t3 = LocalTime(t2);
  assert(t3 == t);

  const t5 = LocalTime(t3);
  assert(t5 == t3);

  auto v = Value(mg_value_make_local_time(tm));
  assert(to!string(v) == "12:34:56.100000000", to!string(v));

  assert(cast(ulong)t.ptr == t.toHash);
}
