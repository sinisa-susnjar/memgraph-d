/// Provides a wrapper around a `Path`.
module memgraph.path;

import memgraph.mgclient, memgraph.detail, memgraph.map, memgraph.value, memgraph.node, memgraph.unboundrelationship;
import memgraph.enums, memgraph.atomic;

/// Represents a sequence of alternating nodes and relationships
/// corresponding to a walk in a labeled property graph.
///
/// A path of length L consists of L + 1 nodes indexed from 0 to L, and L
/// unbound relationships, indexed from 0 to L - 1. Each relationship has a
/// direction. A relationship is said to be reversed if it was traversed in the
/// direction opposite of the direction of the underlying relationship in the
/// data graph.
struct Path {
	@disable this();
	@disable this(this);

	/// Create a copy of `other` path.
	this(const ref Path other) {
		this(mg_path_copy(other.ref_.data));
	}

	/// Create a copy of `other` path.
	this(ref Path other) {
		ref_ = other.ref_;
	}

	/// Create a path from a Value.
	this(const ref Value value) {
		assert(value.type == Type.Path);
		this(mg_path_copy(mg_value_path(value.ptr)));
	}

	/// Return a printable string representation of this path.
	const (string) toString() const {
		return "TODO";
	}

	/// Compares this path with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Path other) const {
		return Detail.arePathsEqual(ref_.data, other.ref_.data);
	}

	/// Returns the path length.
	/// Length of the path is number of edges.
	const (long) length() const {
		assert(ref_.data != null);
		return mg_path_length(ref_.data);
	}

	/// Returns the vertex at the given `index`.
	/// `index` should be less than or equal to length of the path.
	const (Node) getNodeAt(uint index) const {
		assert(ref_.data != null);
		const auto vertex_ptr = mg_path_node_at(ref_.data, index);
		assert(vertex_ptr != null);
		return Node(vertex_ptr);
	}

	/// Returns the edge at the given `index`.
	/// `index` should be less than length of the path.
	const (UnboundRelationship) getRelationshipAt(uint index) const {
		assert(ref_.data != null);
		auto edge_ptr = mg_path_relationship_at(ref_.data, index);
		assert(edge_ptr != null);
		return UnboundRelationship(edge_ptr);
	}

	/// Returns the orientation of the edge at the given `index`.
	/// `index` should be less than length of the path.
	/// Return: True if the edge is reversed, false otherwise.
	bool isReversedRelationshipAt(uint index) const {
		assert(ref_.data != null);
		auto is_reversed = mg_path_relationship_reversed_at(ref_.data, index);
		assert(is_reversed != -1);
		return is_reversed == 1;
	}

package:
	/// Create a Path using the given `mg_path`.
	this(mg_path *ptr) {
		assert(ptr != null);
		ref_ = SharedPtr!mg_path.make(ptr, (p) { mg_path_destroy(p); });
	}

	/// Create a Path from a copy of the given `mg_path`.
	this(const mg_path *ptr) {
		assert(ptr != null);
		this(mg_path_copy(ptr));
	}

	const (mg_path *) ptr() const { return ref_.data; }

private:
	SharedPtr!mg_path ref_;
}

unittest {
	import testutils : connectContainer, createTestData, deleteTestData;
	import memgraph : Client, Optional, Type, Value, Node, Relationship, List;
	import std.conv : to;

	auto client = connectContainer();
	assert(client);

	deleteTestData(client);

	createTestData(client);

	// TODO: fix unit test, ie. use unbound relationship
	auto res = client.execute(
			"MATCH p = ()-[*]-() RETURN p");
	assert(res, client.error);
	foreach (c; res) {
		assert(c[0].type == Type.Path);
		auto p = to!Path(c[0]);

		auto p2 = p;
		auto p3 = c[0];
		assert(p2 == p3);
		auto p4 = Path(p);
		assert(p4 == p);

		auto p5 = Value(p);

		assert(p3 == p5);

		foreach (i; 0..p.length) {
			assert(p2.isReversedRelationshipAt(to!uint(i)) ==
					p4.isReversedRelationshipAt(to!uint(i)));
		}

		foreach (i; 0..p.length) {
			auto n = p.getNodeAt(to!uint(i));
			auto r = p.getRelationshipAt(to!uint(i));

			auto n2 = n;
			const n3 = Value(n);
			assert(n2 == n3);

			const r2 = r;
			auto r3 = Value(r);
			assert(r2 == r3);
			const r4 = UnboundRelationship(r);
			assert(r4 == r);
			const r5 = UnboundRelationship(r3);
			assert(r5 == r);

			assert(to!string(r) == "IS_MANAGER");

			assert(r5.id == r.id);
			assert(r5.type == r.type);
			assert(r5.properties == r.properties);

			auto r6 = Value(r);
			assert(r3 == r6);
			assert(to!string(r6) == to!string(r));

		}
		assert(p.ptr != null);

		auto v = Value(p);
		assert(v == p);
		assert(to!string(v) == to!string(p));
	}
}
