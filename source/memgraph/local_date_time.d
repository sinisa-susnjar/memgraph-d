/// Provides a wrapper around a `mg_local_date_time`. Uses `std.datetime.systime.SysTime` internally.
module memgraph.local_date_time;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;
import st = std.datetime.systime;
import sd = std.datetime.date;
import ct = core.time;

/// Represents date and time without its time zone.
/// Date is defined with seconds since the Unix epoch.
/// Time is defined with nanoseconds since midnight.
struct LocalDateTime {

  /// Create a shallow copy of `other` LocalDateTime.
  this(inout ref LocalDateTime other) {
    this(other.ptr);
  }

  /// Create a local date time from a Value.
  this(inout ref Value value) {
    assert(value.type == Type.LocalDateTime);
    this(mg_value_local_date_time(value.ptr));
  }

  /// Return a printable string representation of this local date time.
  string toString() const { return dateTime_.toString; }

  /// Returns seconds since Unix epoch.
  @nogc auto seconds() const { return epoch_; }

  /// Returns nanoseconds since midnight.
  @nogc auto nanoseconds() const { return nanos_; }

package:
  /// Create a LocalDateTime using the given `mg_local_date_time`.
  this(const mg_local_date_time *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
    epoch_ = mg_local_date_time_seconds(ptr);
    nanos_ = mg_local_date_time_nanoseconds(ptr);
    dateTime_ = st.SysTime(st.unixTimeToStdTime(epoch_));
    dateTime_ += ct.nsecs(nanos_);
    // TODO: This is a baaaad hack, but it is necessary. The situation is the following:
    // The memgraph server runs inside a docker container in the UTC timezone. As long
    // as the client also runs in UTC, everything is fine - but when the client is in a
    // different timezone, e.g. CET, the local date time will have an offset.
    // Note: this will bomb if the server does *not* run in UTC.
    dateTime_ -= dateTime_.utcOffset();
  }

  /// Return pointer to internal `mg_local_date_time`.
  @nogc auto ptr() inout {
    return ptr_;
  }

private:
  const mg_local_date_time *ptr_;
  long epoch_;
  long nanos_;
  st.SysTime dateTime_;
  alias dateTime_ this;
} // struct LocalDateTime

unittest {
  import testutils : connectContainer;
  import std.algorithm : count;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  auto result = client.execute(`return localdatetime('2021-12-13T12:34:56.100');`);
  assert(result, client.error);
  foreach (r; result) {
    assert(r.length == 1);
    assert(r[0].type() == Type.LocalDateTime);
    auto t = to!LocalDateTime(r[0]);
    assert(t.toString == "2021-Dec-13 12:34:56.1", t.toString);
    assert(t.toISOString == "20211213T123456.1", t.toISOString);
    assert(t.toISOExtString == "2021-12-13T12:34:56.1", t.toISOExtString);
    assert(t.seconds == 1_639_398_896, to!string(t.seconds));
    assert(t.nanoseconds == 100_000_000, to!string(t.nanoseconds));
  }
}

unittest {
  import std.conv : to;
  import memgraph.enums;

  auto tm = mg_local_date_time_make(1_639_398_896, 100_000_000);
  assert(tm != null);

  auto t = LocalDateTime(tm);
  assert(t.seconds == 1_639_398_896);
  assert(t.nanoseconds == 100_000_000);

  const t1 = t;
  assert(t1 == t);

  assert(to!string(t) == "2021-Dec-13 12:34:56.1", to!string(t));

  st.SysTime st = t;
  assert(to!string(st) == "2021-Dec-13 12:34:56.1", to!string(st));

  auto t2 = LocalDateTime(t.ptr);
  assert(t2 == t);

  const t3 = LocalDateTime(t2);
  assert(t3 == t);

  const t5 = LocalDateTime(t3);
  assert(t5 == t3);
}
