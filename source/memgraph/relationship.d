/// Provides a wrapper around a `Relationship`.
module memgraph.relationship;

import memgraph.mgclient, memgraph.detail, memgraph.map, memgraph.value, memgraph.enums;

/// Represents a relationship from a labeled property graph.
///
/// Consists of a unique identifier (within the scope of its origin graph),
/// identifiers for the start and end nodes of that relationship, a type and a
/// map of properties. A relationship owns its type string and property map.
struct Relationship {
  /// Create a shallow copy of `other` relationship.
  @nogc this(inout ref Relationship other) {
    this(other.ptr);
  }

  /// Create a relationship from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.Relationship);
    this(mg_value_relationship(value.ptr));
  }

  /// Return a printable string representation of this relationship.
  string toString() const {
    import std.array : appender;
    import std.conv : to;
    auto str = appender!string;
    str.put("(");
    str.put(to!string(startId));
    str.put(")-[");
    str.put(type());
    str.put("]-(");
    str.put(to!string(endId));
    str.put(")");
    return str.data;
  }

  /// Compares this relationship with `other`.
  /// Return: true if same, false otherwise.
  @nogc auto opEquals(const ref Relationship other) const {
    return Detail.areRelationshipsEqual(ptr_, other.ptr_);
  }

  /// Return the hash code for this relationship.
  size_t toHash() const nothrow @safe {
    return cast(ulong)ptr_;
  }

  /// Returns the relationship id.
  @nogc auto id() const {
    return mg_relationship_id(ptr_);
  }

  /// Returns the relationship start id.
  @nogc auto startId() const {
    return mg_relationship_start_id(ptr_);
  }

  /// Returns the relationship end id.
  @nogc auto endId() const {
    return mg_relationship_end_id(ptr_);
  }

  /// Returns the relationship type.
  @nogc auto type() const {
    return Detail.convertString(mg_relationship_type(ptr_));
  }

  /// Returns the relationship properties.
  @nogc auto properties() const {
    return Map(mg_relationship_properties(ptr_));
  }

package:
  /// Create a Relationship using the given `mg_relationship` pointer.
  @nogc this(const mg_relationship *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
  }

  /// Return pointer to internal mg_relationship.
  @nogc auto ptr() inout { return ptr_; }

private:
  const mg_relationship *ptr_;
}

unittest {
  import testutils : connectContainer, createTestData, deleteTestData;
  import memgraph : Client, Type, Value, Node, Relationship;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  deleteTestData(client);

  createTestData(client);

  auto res = client.execute(
          "MATCH (a:Person)-[r:IS_MANAGER]->(b:Person) " ~
            "RETURN a, r, b;");
  assert(res, client.error);
  foreach (c; res) {
    assert(c[0].type == Type.Node);
    assert(c[1].type == Type.Relationship);
    assert(c[2].type == Type.Node);
    auto a = to!Node(c[0]);
    auto r = to!Relationship(c[1]);
    auto b = to!Node(c[2]);
    assert(to!string(a) == to!string(c[0]));
    assert(to!string(r) == to!string(c[1]));
    assert(to!string(b) == to!string(c[2]));

    const r2 = r;
    assert(r2 == r);

    const r3 = Relationship(r);
    assert(r3 == r);

    const r4 = Relationship(r.ptr);
    assert(r4 == r);

    assert(r.id == r2.id);
    assert(r.startId == r2.startId);
    assert(r.endId == r2.endId);
    assert(r.properties == r2.properties);

    const r5 = Relationship(r3);
    assert(r5 == r3);

    assert(cast(ulong)r.ptr == r.toHash);
  }
  assert(to!string(res.columns) == `["a", "r", "b"]`);
}
