/// Provides a wrapper for a `mg_date`. Uses `std.datetime.date.Date` internally.
module memgraph.date;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;
import sd = std.datetime.date;
import ct = core.time;

/// Represents a date.
/// Date is defined with number of days since the Unix epoch.
/// Uses a `std.datetime.date.Date` internally.
struct Date {
  /// Create a shallow copy of `other` Date.
  @nogc this(inout ref Date other) {
    this(other.ptr_);
  }

  /// Create a date from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.Date);
    this(mg_value_date(value.ptr));
  }

  /// Compares this date with `other`.
  /// Return: true if same, false otherwise.
  @nogc auto opEquals(const ref Date other) const {
    return Detail.areDatesEqual(ptr_, other.ptr_);
  }

  /// Return the hash code for this date.
  size_t toHash() const nothrow @safe {
    return cast(ulong)ptr_;
  }

  /// Return a printable string representation of this date.
  string toString() const { return date_.toString; }

  /// Returns days since Unix epoch.
  @nogc auto days() const { return (date_ - epoch_).total!"days"; }

package:
  /// Create a Date using the given `mg_date` pointer.
  @nogc this(const mg_date *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
    date_ = epoch_ + ct.days(mg_date_days(ptr));
  }

  /// Return pointer to internal `mg_date`.
  @nogc auto ptr() inout {
    return ptr_;
  }

private:
  const mg_date *ptr_;
  sd.Date date_;
  alias date_ this;
} // struct Date

static private sd.Date epoch_ = sd.Date(1970, 1, 1);

unittest {
  import testutils : connectContainer;
  import std.algorithm : count;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  auto result = client.execute(`return date('2021-02-12') as a, date('2022-11-12') as b, date('2038-01-20') as c;`);
  assert(result, client.error);
  foreach (r; result) {
    assert(r.length == 3);

    assert(r[0].type() == Type.Date);
    const d1 = to!Date(r[0]);
    assert(d1.days == 18_670, to!string(d1.days));
    assert(d1.toISOExtString == "2021-02-12");
    assert(d1.toISOString == "20210212");
    assert(d1.toString == "2021-Feb-12");
    const sd.Date D1 = d1;
    assert(D1.toISOExtString == "2021-02-12");
    assert(D1.toISOString == "20210212");
    assert(D1.toString == "2021-Feb-12");

    assert(r[1].type() == Type.Date);
    const d2 = to!Date(r[1]);
    assert(d2.days == 19_308, to!string(d2.days));
    assert(d2.toISOExtString == "2022-11-12");
    assert(d2.toISOString == "20221112");
    assert(d2.toString == "2022-Nov-12");
    const sd.Date D2 = d2;
    assert(D2.toISOExtString == "2022-11-12");
    assert(D2.toISOString == "20221112");
    assert(D2.toString == "2022-Nov-12");

    assert(r[2].type() == Type.Date);
    const d3 = to!Date(r[2]);
    assert(d3.days == 24_856, to!string(d3.days));
    assert(d3.toISOExtString == "2038-01-20");
    assert(d3.toISOString == "20380120");
    assert(d3.toString == "2038-Jan-20");
    const sd.Date D3 = d3;
    assert(D3.toISOExtString == "2038-01-20");
    assert(D3.toISOString == "20380120");
    assert(D3.toString == "2038-Jan-20");
  }
}

unittest {
  import memgraph.enums : Type;
  import std.conv : to;

  auto dt = mg_date_make(42);
  assert(dt != null);

  auto d = Date(dt);
  assert(d.days == 42);

  const d1 = d;
  assert(d1 == d);

  assert(to!string(d) == "1970-Feb-12", to!string(d));

  auto d2 = Date(mg_date_copy(d.ptr));
  assert(d2 == d);

  const d3 = Date(d2);
  assert(d3 == d);

  const d5 = Date(d3);
  assert(d5 == d3);

  auto v = Value(mg_value_make_date(dt));
  assert(to!string(v) == "1970-Feb-12", to!string(v));

  assert(cast(ulong)d.ptr == d.toHash);
}
