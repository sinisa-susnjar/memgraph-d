/// Provides a wrapper for a Bolt value.
module memgraph.value;

import std.string : toStringz;
import std.typecons : tuple;
import std.conv : to;

import memgraph.detail;
import memgraph;

// Internal mapping between D type and a tuple containing the memgraph type and the
// operation to be applied when doing an opCast/opEquals.
private static immutable enum mixinOps = [
  typeid(double):               tuple(Type.Double,              "mg_value_float(ptr_)"),
  typeid(int):                  tuple(Type.Int,                 "to!int(mg_value_integer(ptr_))"),
  typeid(long):                 tuple(Type.Int,                 "to!long(mg_value_integer(ptr_))"),
  typeid(bool):                 tuple(Type.Bool,                "to!bool(mg_value_bool(ptr_))"),
  typeid(Node):                 tuple(Type.Node,                "Node(mg_value_node(ptr_))"),
  typeid(List):                 tuple(Type.List,                "List(mg_value_list(ptr_))"),
  typeid(Map):                  tuple(Type.Map,                 "Map(mg_value_map(ptr_))"),
  typeid(Path):                 tuple(Type.Path,                "Path(mg_value_path(ptr_))"),
  typeid(Relationship):         tuple(Type.Relationship,        "Relationship(mg_value_relationship(ptr_))"),
  typeid(UnboundRelationship):  tuple(Type.UnboundRelationship, "UnboundRelationship(mg_value_unbound_relationship(ptr_))"),
  typeid(string):               tuple(Type.String,              "Detail.convertString(mg_value_string(ptr_))"),
  typeid(char[]):               tuple(Type.String,              "Detail.convertString(mg_value_string(ptr_))"),
  typeid(Date):                 tuple(Type.Date,                "Date(mg_value_date(ptr_))"),
  typeid(LocalTime):            tuple(Type.LocalTime,           "LocalTime(mg_value_local_time(ptr_))"),
  typeid(LocalDateTime):        tuple(Type.LocalDateTime,       "LocalDateTime(mg_value_local_date_time(ptr_))"),
  typeid(Duration):             tuple(Type.Duration,            "Duration(mg_value_duration(ptr_))"),
  typeid(Point2d):              tuple(Type.Point2d,             "Point2d(mg_value_point_2d(ptr_))"),
  typeid(Point3d):              tuple(Type.Point3d,             "Point3d(mg_value_point_3d(ptr_))"),
];

/// A Bolt value, encapsulating all other values.
struct Value {
  /// Copy constructor.
  @nogc this(const ref Value rhs) {
    this(rhs.ptr_);
  }

  /// Cast this value to type `T`.
  /// Note: The code asserts that the current value holds a representation of type `T`.
  auto opCast(T)() const {
    assert(type == mixinOps[typeid(T)][0], "expected " ~ to!string(type) ~ " got " ~ T.stringof);
    return mixin(mixinOps[typeid(T)][1]);
  }

  /// Comparison operator for type `T`.
  /// Note: The code asserts that the current value holds a representation of type `T`.
  bool opEquals(T)(const T val) const {
    assert(type == mixinOps[typeid(T)][0], "expected " ~ to!string(type) ~ " got " ~ T.stringof);
    return mixin(mixinOps[typeid(T)][1]) == val;
  }

  /// Comparison operator for another `Value`.
  @nogc bool opEquals(const Value other) const {
    return Detail.areValuesEqual(ptr_, other.ptr_);
  }

  /// Return the hash code for this value.
  @nogc ulong toHash() const {
    return cast(ulong)ptr_;
  }

  /// Return this value as a string.
  /// If the value held is not of type `Type.String`, then it will
  /// be first converted into the appropriate string representation.
  string toString() const {
    final switch (type) {
      case Type.Null:                return "(null)";
      case Type.Double:              return to!string(mg_value_float(ptr_));
      case Type.Bool:                return to!string(mg_value_bool(ptr_));
      case Type.Int:                 return to!string(mg_value_integer(ptr_));
      case Type.String:              return Detail.convertString(mg_value_string(ptr_));
      case Type.Relationship:        return to!string(Relationship(mg_value_relationship(ptr_)));
      case Type.UnboundRelationship: return to!string(UnboundRelationship(mg_value_unbound_relationship(ptr_)));
      case Type.Node:                return to!string(Node(mg_value_node(ptr_)));
      case Type.List:                return to!string(List(mg_value_list(ptr_)));
      case Type.Map:                 return to!string(Map(mg_value_map(ptr_)));
      case Type.Path:                return to!string(Path(mg_value_path(ptr_)));
      case Type.Date:                return to!string(Date(mg_value_date(ptr_)));
      case Type.LocalTime:           return to!string(LocalTime(mg_value_local_time(ptr_)));
      case Type.LocalDateTime:       return to!string(LocalDateTime(mg_value_local_date_time(ptr_)));
      case Type.Duration:            return to!string(Duration(mg_value_duration(ptr_)));
      case Type.Point2d:             return to!string(Point2d(mg_value_point_2d(ptr_)));
      case Type.Point3d:             return to!string(Point3d(mg_value_point_3d(ptr_)));
    }
  }

  /// Return the type of value being held.
  @nogc @property Type type() const {
    return Detail.convertType(mg_value_get_type(ptr_));
  }

package:
  /// Create a Value using the given `mg_value`.
  @nogc this(const mg_value *p) {
    assert(p != null);
    ptr_ = p;
  }

  /// Returns internal `mg_value` pointer.
  @nogc auto ptr() inout { return ptr_; }

private:
  const mg_value *ptr_;
} // struct Value

// value tests
unittest {
  import testutils : connectContainer;
  import memgraph.local_date_time;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  auto result = client.execute(`return ["Zdravo, svijete!", 42];`);
  assert(result, client.error);
  foreach (r; result) {
    assert(r.length == 1);
    assert(r[0].type() == Type.List);

    auto l = to!List(r[0]);

    assert(l.length == 2);

    assert(l[0].type() == Type.String);
    assert(l[1].type() == Type.Int);

    assert(to!string(l[0]) == "Zdravo, svijete!");
    assert(to!int(l[1]) == 42);
  }
}

unittest {
  auto nullValue = Value(mg_value_make_null());
  assert(to!string(nullValue) == "(null)");
  assert(cast(ulong)nullValue.ptr == nullValue.toHash);
}
