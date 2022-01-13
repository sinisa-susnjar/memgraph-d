/// Provides a `Value` list.
module memgraph.list;

import std.string, std.conv;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// An ordered sequence of values.
///
/// List may contain a mixture of different types as its elements. A list owns
/// all values stored in it.
///
/// Maximum possible list length allowed by Bolt is `uint.max`.
struct List {
  /// Create a shallow copy of `other` list.
  @nogc this(inout ref List other) {
    this(other.ptr_);
  }

  /// Create a shallow list copy from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.List);
    this(mg_value_list(value.ptr));
  }

  /// Compares this list with `other`.
  /// Return: true if same, false otherwise.
  @nogc auto opEquals(const ref List other) const {
    return Detail.areListsEqual(ptr_, other.ptr_);
  }

  /// Return the hash code for this list.
  size_t toHash() const nothrow @safe {
    return cast(ulong)ptr_;
  }

  /// Return value at position `idx` of this list.
  @nogc auto opIndex(uint idx) const {
    assert(idx < length);
    return Value(mg_list_at(ptr_, idx));
  }

  /// Returns the number of values in this list.
  @nogc @property uint length() const { return mg_list_size(ptr_); }

  /// Return a printable string representation of this list.
  string toString() const {
    import std.array : appender;
    auto str = appender!string;
    str.put("[");
    immutable len = length;
    for (uint i = 0; i < len; i++) {
      str.put(to!string(Value(mg_list_at(ptr_, i))));
      if (i < len-1)
        str.put(", ");
    }
    str.put("]");
    return str.data;
  }

  /// Checks if the list as range is empty.
  @nogc @property bool empty() const { return idx_ >= length; }

  /// Returns the next element in the list range.
  @nogc @property auto front() const {
    import std.typecons : Tuple;
    assert(idx_ < length);
    return Tuple!(uint, "index", Value, "value")(idx_, Value(mg_list_at(ptr_, idx_)));
  }

  /// Move to the next element in the list range.
  @nogc void popFront() { idx_++; }

package:
  /// Create a List using the given `mg_list` pointer.
  @nogc this(const mg_list *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
  }

  /// Return pointer to internal `mg_list`.
  @nogc auto ptr() inout { return ptr_; }

private:
  const mg_list *ptr_;
  uint idx_;
} // struct List

unittest {
  import std.range.primitives : isInputRange;
  assert(isInputRange!List);
}

unittest {
  import testutils : connectContainer;
  import std.algorithm : count;
  import std.conv : to;
  import memgraph.local_date_time;

  auto client = connectContainer();
  assert(client);

  auto result = client.execute(`return [1, 2, 3, 4.56, true, "Hello", localdatetime('2021-12-13T12:34:56.100')];`);
  assert(result, client.error);
  foreach (r; result) {
    assert(r.length == 1);
    assert(r[0].type() == Type.List);
    auto list = to!List(r[0]);
    assert(list.length == 7);

    assert(list[0].type() == Type.Int);
    assert(list[1].type() == Type.Int);
    assert(list[2].type() == Type.Int);
    assert(list[3].type() == Type.Double);
    assert(list[4].type() == Type.Bool);
    assert(list[5].type() == Type.String);
    assert(list[6].type() == Type.LocalDateTime);

    assert(to!int(list[0]) == 1);
    assert(to!int(list[1]) == 2);
    assert(to!int(list[2]) == 3);
    assert(to!double(list[3]) == 4.56);
    assert(to!bool(list[4]) == true);
    assert(to!string(list[5]) == "Hello");
    assert(to!LocalDateTime(list[6]).toString == "2021-Dec-13 12:34:56.1");

    assert(to!string(list) == "[1, 2, 3, 4.56, true, Hello, 2021-Dec-13 12:34:56.1]", to!string(list));

    const otherList = list;
    assert(otherList == list);

    foreach (ref idx, ref value; list) {
      assert(value == list[idx]);
    }

    assert(list.ptr != null);
    assert(list.ptr == otherList.ptr);

    assert(cast(ulong)list.ptr == list.toHash);
  }
}
