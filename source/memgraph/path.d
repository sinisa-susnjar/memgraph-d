/// Provides a wrapper around a `Path`.
module memgraph.path;

import memgraph.mgclient, memgraph.detail, memgraph.map, memgraph.value, memgraph.node, memgraph.unboundrelationship;
import memgraph.enums;

/// Represents a sequence of alternating nodes and relationships
/// corresponding to a walk in a labeled property graph.
///
/// A path of length L consists of L + 1 nodes indexed from 0 to L, and L
/// unbound relationships, indexed from 0 to L - 1. Each relationship has a
/// direction. A relationship is said to be reversed if it was traversed in the
/// direction opposite of the direction of the underlying relationship in the
/// data graph.
struct Path {
  /// Create a shallow copy of `other` path.
  @nogc this(inout ref Path other) {
    this(other.ptr);
  }

  /// Create a path from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.Path);
    this(mg_value_path(value.ptr));
  }

  /// Return a printable string representation of this path.
  string toString() const {
    import std.array : appender;
    import std.conv : to;
    auto str = appender!string;
    foreach (i; 0..length+1) {
      auto node = getNodeAt(to!uint(i));
      str.put(to!string(node));
      str.put("\n");
      if (i < length) {
        auto rel = getRelationshipAt(to!uint(i));
        if (isReversedRelationshipAt(i)) {
          str.put("  <-");
          str.put(to!string(rel));
          str.put("- ");
        } else {
          str.put("  -");
          str.put(to!string(rel));
          str.put("-> ");
        }
      }
    }
    return str.data;
  }

  /// Compares this path with `other`.
  /// Return: true if same, false otherwise.
  @nogc auto opEquals(const ref Path other) const {
    return Detail.arePathsEqual(ptr_, other.ptr);
  }

  /// Return the hash code for this path.
  @nogc ulong toHash() const {
    return cast(ulong)ptr_;
  }

  /// Returns the path length.
  /// Length of the path is number of edges.
  @nogc auto length() const {
    return mg_path_length(ptr_);
  }

  /// Returns the vertex at the given `index`.
  /// `index` should be less than or equal to length of the path.
  @nogc auto getNodeAt(uint index) const {
    assert(index <= length);
    const auto vertex_ptr = mg_path_node_at(ptr_, index);
    assert(vertex_ptr != null);
    return Node(vertex_ptr);
  }

  /// Returns the edge at the given `index`.
  /// `index` should be less than length of the path.
  @nogc auto getRelationshipAt(uint index) const {
    assert(index < length);
    const edge_ptr = mg_path_relationship_at(ptr_, index);
    assert(edge_ptr != null);
    return UnboundRelationship(edge_ptr);
  }

  /// Returns the orientation of the edge at the given `index`.
  /// `index` should be less than length of the path.
  /// Return: True if the edge is reversed, false otherwise.
  @nogc auto isReversedRelationshipAt(uint index) const {
    const is_reversed = mg_path_relationship_reversed_at(ptr_, index);
    assert(is_reversed != -1);
    return is_reversed == 1;
  }

package:
  /// Create a Path using the given `mg_path` pointer.
  @nogc this(const mg_path *ptr) {
    assert(ptr != null);
    ptr_ = ptr;
  }

  /// Return pointer to internal `mg_path`.
  @nogc auto ptr() inout { return ptr_; }

private:
  const mg_path *ptr_;
} // struct Path

unittest {
  import testutils : connectContainer, createTestData, deleteTestData;
  import memgraph : Client, Type, Value, Node, Relationship, List;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  deleteTestData(client);

  createTestData(client);

  auto res = client.execute(
      "MATCH p = ()-[*3]->() RETURN p;");
  assert(res, client.error);
  foreach (c; res) {
    assert(c[0].type == Type.Path);

    auto path = to!Path(c[0]);

    auto p2 = path;
    const p3 = c[0];
    assert(p2 == p3);
    auto p4 = Path(path);
    assert(p4 == path);

    foreach (i; 0..path.length) {
      assert(p2.isReversedRelationshipAt(to!uint(i)) ==
          p4.isReversedRelationshipAt(to!uint(i)));
    }

    assert(to!string(path) ==
`["Person", "Entrepreneur"] {age:40, id:0, isStudent:false, name:John, score:5}
  -[IS_MANAGER]-> ["Person", "Entrepreneur"] {age:50, id:2, isStudent:false, name:Peter, score:4}
  -[IS_MANAGER]-> ["Person", "Entrepreneur"] {age:20, id:1, isStudent:true, name:Valery, score:5}
  -[IS_MANAGER]-> ["Person", "Entrepreneur"] {age:25, id:4, isStudent:true, name:Oløf, score:10}
`, to!string(path));

    immutable auto expectedNames = [ "John", "Peter", "Valery", "Oløf" ];

    foreach (i; 0..path.length+1) {
      const n = path.getNodeAt(to!uint(i));

      auto p = n.properties;
      assert(to!string(p["name"]) == expectedNames[i], to!string(p["name"]));

      const n2 = n;
      assert(n2 == n);

      if (i < path.length) {
        auto r = path.getRelationshipAt(to!uint(i));
        const r2 = r;
        assert(r2 == r);
        const r4 = UnboundRelationship(r);
        assert(r4 == r);
        const r5 = UnboundRelationship(r2);
        assert(r5 == r);

        assert(to!string(r) == "[" ~ r.type ~ "]");

        assert(r5.id == r.id);
        assert(r5.type == r.type);
        assert(r5.properties == r.properties);

        assert(to!string(r5) == to!string(r));
      }
    }
    assert(path.ptr != null);

    const p6 = path;
    const p7 = Path(p6);
    assert(p7 == path);
  }
}

unittest {
  import testutils : connectContainer, createTestData, deleteTestData;
  import memgraph : Client, Type, Value, Node, Relationship, List;
  import std.conv : to;

  auto client = connectContainer();
  assert(client);

  deleteTestData(client);

  createTestData(client);

  auto res = client.execute(
      "MATCH p = ()<-[*3]-() RETURN p;");
  assert(res, client.error);
  foreach (c; res) {
    assert(c[0].type == Type.Path);

    auto path = to!Path(c[0]);

    assert(cast(ulong)path.ptr == path.toHash);

    auto p2 = path;
    const p3 = c[0];
    assert(p2 == p3);
    auto p4 = Path(path);
    assert(p4 == path);

    foreach (i; 0..path.length) {
      assert(p2.isReversedRelationshipAt(to!uint(i)) ==
          p4.isReversedRelationshipAt(to!uint(i)));
    }

    assert(to!string(path) ==
`["Person", "Entrepreneur"] {age:25, id:4, isStudent:true, name:Oløf, score:10}
  <-[IS_MANAGER]- ["Person", "Entrepreneur"] {age:20, id:1, isStudent:true, name:Valery, score:5}
  <-[IS_MANAGER]- ["Person", "Entrepreneur"] {age:50, id:2, isStudent:false, name:Peter, score:4}
  <-[IS_MANAGER]- ["Person", "Entrepreneur"] {age:40, id:0, isStudent:false, name:John, score:5}
`, to!string(path));

    immutable auto expectedNames = [ "Oløf", "Valery", "Peter", "John" ];

    foreach (i; 0..path.length+1) {
      const n = path.getNodeAt(to!uint(i));

      auto p = n.properties;
      assert(to!string(p["name"]) == expectedNames[i], to!string(p["name"]));

      const n2 = n;
      assert(n2 == n);

      if (i < path.length) {
        auto r = path.getRelationshipAt(to!uint(i));
        const r2 = r;
        assert(r2 == r);
        const r4 = UnboundRelationship(r);
        assert(r4 == r);
        const r5 = UnboundRelationship(r2);
        assert(r5 == r);

        assert(to!string(r) == "[" ~ r.type ~ "]");

        assert(r5.id == r.id);
        assert(r5.type == r.type);
        assert(r5.properties == r.properties);

        assert(to!string(r5) == to!string(r));
      }
    }
    assert(path.ptr != null);

    const p6 = path;
    const p7 = Path(p6);
    assert(p7 == path);
  }
}
