/// Provides a wrapper around a `mg_date_time`.
module memgraph.date_time;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;
import std.datetime.timezone :  UTC;

import sd = std.datetime;
import sdd = std.datetime.date;
import ct = core.time;

/// Represents date and time with its time zone.
/// Date is defined with seconds since the adjusted Unix epoch.
/// Time is defined with nanoseconds since midnight.
/// Time zone is defined with minutes from UTC.
struct DateTime {
  /// Create a copy of `other` date time.
  this(DateTime other) { dateTime_ = other; }

  /// Create a copy of `other` std.datetime.SysTime.
  this(sd.SysTime other) { dateTime_ = other; }

  /// Create a date time from a Value.
  this(inout ref Value value) {
    assert(value.type == Type.DateTime);
    auto tzOffsetMinutes = ct.minutes(mg_date_time_tz_offset_minutes(mg_value_date_time(value.ptr)));
    auto nsecsSinceMidnight = ct.nsecs(mg_date_time_nanoseconds(mg_value_date_time(value.ptr)));
    auto secondsSinceEpoch = sd.unixTimeToStdTime(mg_date_time_seconds(mg_value_date_time(value.ptr)));
    import std.conv : to;
    dateTime_ = sd.SysTime(to!(sdd.DateTime)(sd.SysTime(secondsSinceEpoch)),
              to!(sd.TimeZone)(new sd.SimpleTimeZone(tzOffsetMinutes)));
  }

  /// Return a printable string representation of this date time.
  const (string) toString() const { return dateTime_.toString; }

  /// Returns seconds since Unix epoch.
  const (long) seconds() const { return dateTime_.toUnixTime; }

  /// Returns nanoseconds since midnight.
  const (long) nanoseconds() const { return 42; } // TODO

  /// Returns time zone offset in minutes from UTC.
  const (long) tz_offset_minutes() const { return dateTime_.utcOffset.total!"minutes"; }

package:
  /// Create a DateTime using the given `mg_date_time`.
  this(inout mg_date_time *ptr) {
    assert(ptr != null);
    auto tzOffsetMinutes = ct.minutes(mg_date_time_tz_offset_minutes(ptr));
    auto nsecsSinceMidnight = ct.nsecs(mg_date_time_nanoseconds(ptr));
    auto secondsSinceEpoch = sd.unixTimeToStdTime(mg_date_time_seconds(ptr));
    import std.conv : to;
    dateTime_ = sd.SysTime(to!(sdd.DateTime)(sd.SysTime(secondsSinceEpoch)),
              to!(sd.TimeZone)(new sd.SimpleTimeZone(tzOffsetMinutes)));
  }

  /// Returns the internal `mg_date_time` pointer.
  const (mg_date_time *) ptr() const {
    // TODO
    auto ptr = mg_date_time_make(dateTime_.toUnixTime, 0, dateTime_.utcOffset.total!"minutes");
    assert(ptr != null);
    return ptr;
  }

private:
  sd.SysTime dateTime_;
  alias dateTime_ this;
}

static private sd.SysTime stdTime = sd.SysTime(sdd.DateTime(1, 1, 1, 0, 0, 0), UTC());
static private sd.SysTime epoch_ = sd.SysTime(sdd.DateTime(1970, 1, 1, 0, 0, 0), UTC());

unittest {
  import std.conv : to;
  import memgraph.enums;

  auto tm = mg_date_time_alloc(&mg_system_allocator);
  assert(tm != null);
  tm.seconds = 23;
  tm.nanoseconds = 42;
  tm.tz_offset_minutes = 60;

  auto t = DateTime(tm);
  assert(t.seconds == 23, to!string(t.seconds));
  assert(t.nanoseconds == 42);
  assert(t.tz_offset_minutes == 60);

  const t1 = t;
  assert(t1 == t);

  assert(to!string(t) == "1970-Jan-01 01:00:23+01:00", to!string(t));

  auto t2 = DateTime(mg_date_time_copy(t.ptr));
  assert(t2 == t);

  const t3 = DateTime(t2);
  assert(t3 == t);

  const v = Value(t);
  const t4 = DateTime(v);
  assert(t4 == t);
  assert(v == t);
  assert(to!string(v) == to!string(t));

  t2 = t;
  assert(t2 == t);

  const v1 = Value(t2);
  assert(v1.type == Type.DateTime);
  const v2 = Value(t2);
  assert(v2.type == Type.DateTime);

  assert(v1 == v2);

  const t5 = DateTime(t3);
  assert(t5 == t3);
}
