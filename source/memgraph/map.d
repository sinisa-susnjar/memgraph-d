/// Provides a map (i.e. key/value) tuple.
module memgraph.map;

import std.string, std.conv;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Sized sequence of pairs of keys and values.
/// Maximum possible map size allowed by Bolt protocol is `uint.max`.
///
/// Map may contain a mixture of different types as values. A map owns all keys
/// and values stored in it.
///
/// Can be used like a standard D hash map.
struct Map {
  /// Create a shallow copy of `other` map.
  @nogc this(inout ref Map other) {
    this(other.ptr);
  }

  /// Create a map from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.Map);
    this(mg_value_map(value.ptr));
  }

  /// Returns the value associated with the given `key`.
  auto opIndex(const string key) const {
    return Value(mg_map_at(ptr_, toStringz(key)));
  }

  /// Compares this map with `other`.
  /// Return: true if same, false otherwise.
  @nogc bool opEquals(const Map other) const {
    return Detail.areMapsEqual(ptr_, other.ptr);
  }

  /// Return the hash code for this map.
  size_t toHash() const nothrow @safe {
    return cast(ulong)ptr_;
  }

  /// Checks if the map contains the given `key`.
  /// Return: `true` if map contains `key`, `false` otherwise.
  auto opBinaryRight(string op)(const char[] key) if (op == "in") {
    return mg_map_at(ptr_, toStringz(key)) != null;
  }

  /// Returns the number of key / value pairs in this map.
  @nogc @property uint length() const { return mg_map_size(ptr_); }

  /// Return a printable string representation of this map.
  string toString() const {
    import std.array : appender;
    auto str = appender!string;
    str.put("{");
    immutable len = length;
    for (uint i = 0; i < len; i++) {
      str.put(Detail.convertString(mg_map_key_at(ptr_, i)));
      str.put(":");
      str.put(to!string(Value(mg_map_value_at(ptr_, i))));
      if (i < len-1)
        str.put(", ");
    }
    str.put("}");
    return str.data;
  }

  /// Checks if the map as range is empty.
  @nogc bool empty() const { return idx_ >= length; }

  /// Returns the next element in the map range.
  @nogc auto front() const {
    import std.typecons : Tuple;
    assert(idx_ < length);
    return Tuple!(string, "key", Value, "value")(
                Detail.convertString(mg_map_key_at(ptr_, idx_)),
                Value(mg_map_value_at(ptr_, idx_)));
  }

  /// Move to the next element in the list range.
  @nogc void popFront() { idx_++; }

package:
  /// Create a Map from a copy of the given `mg_map`.
  @nogc this(inout mg_map *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
  }

  /// Return pointer to internal `mg_map`.
  @nogc auto ptr() inout { return ptr_; }

private:
  const mg_map *ptr_;
  uint idx_;
} // struct Map

unittest {
  import std.range.primitives : isInputRange;
  assert(isInputRange!Map);
}

unittest {
  import testutils : connectContainer;
  import std.algorithm : count;
  import std.conv : to;
  import memgraph.local_date_time;

  auto client = connectContainer();
  assert(client);

  auto result = client.execute(`return {
                        int_val: 123,
                        str_val: "Zdravo",
                        float_val: 3.1415,
                        bool_val: false,
                        dt_val: localdatetime('2021-12-13T12:34:56.100')
                      };`);
  assert(result, client.error);
  foreach (r; result) {
    assert(r.length == 1);
    assert(r[0].type() == Type.Map);
    auto m = to!Map(r[0]);
    assert(m.length == 5);

    assert(m["int_val"].type() == Type.Int);
    assert(m["str_val"].type() == Type.String);
    assert(m["float_val"].type() == Type.Double);
    assert(m["bool_val"].type() == Type.Bool);
    assert(m["dt_val"].type() == Type.LocalDateTime);

    assert(to!int(m["int_val"]) == 123);
    assert(to!string(m["str_val"]) == "Zdravo");
    assert(to!double(m["float_val"]) == 3.1415);
    assert(to!bool(m["bool_val"]) == false);
    assert(to!LocalDateTime(m["dt_val"]).toString == "2021-Dec-13 12:34:56.1");

    assert(to!string(m) == "{bool_val:false, dt_val:2021-Dec-13 12:34:56.1, " ~
                           "float_val:3.1415, int_val:123, str_val:Zdravo}", to!string(m));

    foreach (ref key, ref value; m) {
      assert(key in m);
      assert(m[key] == value);
    }

    const otherMap = m;
    assert(otherMap == m);

    assert(cast(ulong)m.ptr == m.toHash);
  }
}
