/// Provides a wrapper around a `UnboundRelationship`.
module memgraph.unboundrelationship;

import memgraph.mgclient, memgraph.detail, memgraph.map, memgraph.value, memgraph.enums;

/// Represents a relationship from a labeled property graph.
///
/// Like `mg_relationship`, but without identifiers for start and end nodes.
/// Mainly used as a supporting type for `mg_path`. An unbound relationship
/// owns its type string and property map.
struct UnboundRelationship {
  /// Create a shallow copy of `other` unbound relationship.
  @nogc this(inout ref UnboundRelationship other) {
    this(other.ptr);
  }

  /// Create a unbound relationship from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.UnboundRelationship);
    this(mg_value_unbound_relationship(value.ptr));
  }

  /// Return a printable string representation of this unbound relationship.
  string toString() const {
    import std.array : appender;
    import std.conv : to;
    auto str = appender!string;
    str.put("[");
    str.put(type());
    str.put("]");
    return str.data;
  }

  /// Compares this unbound relationship with `other`.
  /// Return: true if same, false otherwise.
  @nogc auto opEquals(const ref UnboundRelationship other) const {
    return Detail.areUnboundRelationshipsEqual(ptr, other.ptr);
  }

  /// Return the hash code for this unbound relationship.
  size_t toHash() const nothrow @safe {
    return cast(ulong)ptr_;
  }

  /// Returns the unbound relationship id.
  @nogc auto id() const {
    return mg_unbound_relationship_id(ptr);
  }

  /// Returns the unbound relationship type.
  @nogc auto type() const {
    return Detail.convertString(mg_unbound_relationship_type(ptr));
  }

  /// Returns the unbound relationship properties.
  @nogc auto properties() const {
    return Map(mg_unbound_relationship_properties(ptr));
  }

package:
  /// Create a Unbound Relationship using the given `mg_unbound_relationship` pointer.
  @nogc this(const mg_unbound_relationship *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
  }

  @nogc auto ptr() inout { return ptr_; }

private:
  const mg_unbound_relationship *ptr_;
} // struct UnboundRelationship

unittest {
  import testutils : connectContainer, createTestData, deleteTestData;
  import memgraph : Client, Type, Value, Node, UnboundRelationship, Path;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  deleteTestData(client);

  createTestData(client);

  auto res = client.execute(
          "MATCH p = ()-[*3]->() " ~
            "RETURN p;");
  assert(res, client.error);
  foreach (c; res) {
    assert(c[0].type == Type.Path);
    const path = to!Path(c[0]);
    assert(to!string(path) == to!string(c[0]));

    immutable auto expectedNames = [ "John", "Peter", "Valery", "Oløf" ];
    foreach (i; 0..path.length+1) {
      const n = path.getNodeAt(to!uint(i));
      const p = n.properties;
      assert(to!string(p["name"]) == expectedNames[i], to!string(p["name"]));
      if (i < path.length) {
        auto r = path.getRelationshipAt(to!uint(i));
        assert(to!string(r) == "[" ~ r.type ~ "]");
      }
    }
  }
  assert(to!string(res.columns) == `["p"]`);
}

unittest {
  auto r = UnboundRelationship(mg_unbound_relationship_make(1, mg_string_make("rel"), mg_map_make_empty(0)));
  auto v = Value(mg_value_make_unbound_relationship(mg_unbound_relationship_copy(r.ptr)));
  const r2 = UnboundRelationship(v);
  assert(r == r2);
  assert(r == v);

  import std.conv : to;
  assert(to!string(v) == "[rel]", to!string(v));

  assert(cast(ulong)r.ptr == r.toHash);
}
