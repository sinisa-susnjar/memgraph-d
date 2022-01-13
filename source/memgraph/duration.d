/// Provides a wrapper for a `mg_duration`. Uses `core.time.Duration` internally.
module memgraph.duration;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

import ct = core.time;

/// Represents a temporal amount which captures the difference in time
/// between two instants.
/// Duration is defined with months, days, seconds, and nanoseconds.
/// Note: Duration can be negative.
/// Uses a `core.time.Duration` internally.
struct Duration {
  /// Create a shallow copy of `other` Duration.
  @nogc this(inout ref Duration other) {
    this(other.ptr);
  }

  /// Create a duration from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.Duration);
    this(mg_value_duration(value.ptr));
  }

  /// Return a printable string representation of this duration.
  string toString() const { return duration_.toString; }

  /// Returns the months part of the temporal amount.
  @nogc auto months() const { return 0; } // See note in ctor.

  /// Returns the days part of the temporal amount.
  @nogc auto days() const { return duration_.total!"days"; }

  /// Returns the seconds part of the temporal amount.
  @nogc auto seconds() const { return (duration_ - ct.days(duration_.total!"days")).total!"seconds"; }

  /// Returns the nanoseconds part of the temporal amount.
  @nogc auto nanoseconds() const { return (duration_ - ct.seconds(duration_.total!"seconds")).total!"nsecs"; }

package:
  /// Create a Duration using the given `mg_duration`.
  @nogc this(const mg_duration *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
    // Note: there is no "months" duration in core.time because months have variable number of days
    assert(mg_duration_months(ptr) == 0);
    duration_ = ct.days(mg_duration_days(ptr)) +
                ct.seconds(mg_duration_seconds(ptr)) +
                ct.nsecs(mg_duration_nanoseconds(ptr));
  }

  /// Return pointer to internal `mg_duration`.
  @nogc auto ptr() inout {
    return ptr_;
  }

private:
  const mg_duration *ptr_;
  ct.Duration duration_;
  alias duration_ this;
} // struct Duration

unittest {
  import testutils : connectContainer;
  import std.algorithm : count;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  auto result = client.execute(`return duration('P9DT11H23M7S');`);
  assert(result, client.error);
  foreach (r; result) {
    assert(r.length == 1);
    assert(r[0].type() == Type.Duration);
    const d = to!Duration(r[0]);
    assert(d.toString == "1 week, 2 days, 11 hours, 23 minutes, and 7 secs", d.toString);
    assert(d.months == 0);
    assert(d.days == 9);
    assert(d.seconds == 11*60*60+23*60+7);
    assert(d.nanoseconds == 0);
  }
}

unittest {
  import std.conv : to;
  import memgraph.enums;

  auto du = mg_duration_make(0, 5, 42, 230_000);
  assert(du != null);

  auto d = Duration(du);
  assert(d.months == 0);
  assert(d.days == 5);
  assert(d.seconds == 42);
  assert(d.nanoseconds == 230_000);

  const d1 = d;
  assert(d1 == d);

  assert(to!string(d) == "5 days, 42 secs, and 230 μs", to!string(d));
  assert(d.toString == "5 days, 42 secs, and 230 μs", to!string(d));

  const ct.Duration dur = d;
  assert(dur.toString == "5 days, 42 secs, and 230 μs", to!string(d));

  auto v = Value(mg_value_make_duration(du));
  assert(to!string(v) == "5 days, 42 secs, and 230 μs", to!string(v));
}
