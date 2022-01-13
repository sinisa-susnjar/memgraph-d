/// Provides a node wrapper.
module memgraph.node;

import memgraph.mgclient, memgraph.detail, memgraph.map;
import memgraph.value, memgraph.enums;

import std.conv;

/// Represents a node from a labeled property graph.
///
/// Consists of a unique identifier (withing the scope of its origin graph), a
/// list of labels and a map of properties. A node owns its labels and
/// properties.
///
/// Maximum possible number of labels allowed by Bolt protocol is `uint.max`.
struct Node {
  /// View of the node's labels.
  struct Labels {
    /// Returns the number of labels in the node.
    @nogc size_t size() const {
      return mg_node_label_count(node_);
    }

    /// Return node's label at the `index` position.
    @nogc string opIndex(int index) const {
      return Detail.convertString(mg_node_label_at(node_, index));
    }

    /// Checks if the range is empty.
    @nogc bool empty() const { return idx_ >= size(); }

    /// Returns the next element in the range.
    @nogc auto front() const {
      assert(idx_ < size());
      return Detail.convertString(mg_node_label_at(node_, idx_));
    }

    /// Move to the next element in the range.
    @nogc void popFront() { idx_++; }

    @nogc bool opEquals(const string[] labels) const {
      if (labels.length != size())
        return false;
      // Note: having @nogc is more important than the implicit conversion warning here
      foreach (uint idx, label; labels) {
        if (label != Detail.convertString(mg_node_label_at(node_, idx)))
          return false;
      }
      return true;
    }

    /// Return the hash code for this label.
    @nogc ulong toHash() const {
      return cast(ulong)node_;
    }

  private:
    @nogc this(const mg_node *node) {
      assert(node != null);
      node_ = node;
    }
    const mg_node *node_;
    uint idx_;
  } // struct Labels

  /// Return a printable string representation of this node.
  string toString() const {
    import std.array : appender;
    auto str = appender!string;
    str.put(to!string(labels));
    str.put(" ");
    str.put(to!string(properties));
    return str.data;
  }

  /// Create a shallow copy of the given `node`.
  @nogc this(inout ref Node other) {
    this(other.ptr_);
  }

  /// Create a node from a Value.
  @nogc this(inout ref Value value) {
    assert(value.type == Type.Node);
    this(mg_value_node(value.ptr));
  }

  /// Returns the ID of this node.
  @nogc auto id() inout {
    return mg_node_id(ptr_);
  }

  /// Returns the labels belonging to this node.
  @nogc auto labels() inout { return Labels(ptr_); }

  /// Returns the property map belonging to this node.
  @nogc auto properties() inout { return Map(mg_node_properties(ptr_)); }

  /// Comparison operator.
  @nogc bool opEquals(const ref Node other) const {
    return Detail.areNodesEqual(ptr_, other.ptr_);
  }

  /// Return the hash code for this node.
  @nogc ulong toHash() const {
    return cast(ulong)ptr_;
  }

package:
  /// Create a Node from a copy of the given `mg_node`.
  @nogc this(const mg_node *p) {
    assert(p != null);
    ptr_ = p;
  }

  @nogc auto ptr() inout { return ptr_; }

private:
  /// Pointer to `mg_node` instance.
  const mg_node *ptr_;
} // struct Node

unittest {
  import testutils : startContainer;
  startContainer();
}

unittest {
  import testutils;
  import memgraph;
  import std.algorithm, std.conv, std.range;

  import std.stdio;

  auto client = connectContainer();
  assert(client);

  createTestIndex(client);

  deleteTestData(client);

  createTestData(client);

  auto result = client.execute("MATCH (n) RETURN n;");
  assert(result, client.error);
  assert(!result.empty());
  // TODO: this invalidates the result set
  // assert(result.count == 5);
  auto value = result.front;

  assert(value[0].type() == Type.Node, to!string(value[0].type()));

  auto node = to!Node(value[0]);

  auto labels = node.labels();

  assert(node.id() >= 0);

  immutable auto expectedLabels = [ "Person", "Entrepreneur" ];

  assert(labels.size() == 2);
  assert(labels[0] == expectedLabels[0]);
  assert(labels[1] == expectedLabels[1]);

  assert([] != labels);
  assert([ "Nope", "x" ] != labels);
  assert(expectedLabels == labels);
  assert(expectedLabels.join(":") == labels.join(":"));

  assert(cast(ulong)node.ptr == labels.toHash);

  const other = Node(node);
  assert(other == node);

  const auto props = node.properties();
  assert(props.length == 5);
  assert(props["id"] == 0);
  assert(props["age"] == 40);
  assert(props["name"] == "John");
  assert(props["isStudent"] == false);
  assert(props["score"] == 5.0);

  assert(to!string(node) == `["Person", "Entrepreneur"] {age:40, id:0, isStudent:false, name:John, score:5}`,
            to!string(node));

  const otherProps = props;
  assert(otherProps == props);

  // this is a package internal method
  assert(node.ptr != null);

  assert(cast(ulong)node.ptr == node.toHash);
}
