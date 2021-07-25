/// Provides a wrapper around a `Path`.
module memgraph.path;

import memgraph.mgclient, memgraph.detail, memgraph.map, memgraph.value, memgraph.node, memgraph.unboundrelationship;

/// Represents a sequence of alternating nodes and relationships
/// corresponding to a walk in a labeled property graph.
///
/// A path of length L consists of L + 1 nodes indexed from 0 to L, and L
/// unbound relationships, indexed from 0 to L - 1. Each relationship has a
/// direction. A relationship is said to be reversed if it was traversed in the
/// direction opposite of the direction of the underlying relationship in the
/// data graph.
struct Path {

	/// Disable default constructor, to guarantee that this always has a valid ptr_.
	@disable this();

	/// Postblit, create a copy of the path from source.
	this(this) {
		if (ptr_)
			ptr_ = mg_path_copy(ptr_);
	}

	/// Create a copy of `other` path.
	this(const ref Path other) {
		this(mg_path_copy(other.ptr_));
	}

	/// Create a path from a Value.
	this(const ref Value value) {
		this(mg_path_copy(mg_value_path(value.ptr)));
	}

	/// Destructor. Destroys the internal `mg_path`.
	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_path_destroy(ptr_);
	}

	/// Return a printable string representation of this path.
	const (string) toString() const {
		return "TODO";
	}

	/// Compares this path with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Path other) const {
		return Detail.arePathsEqual(ptr_, other.ptr_);
	}

	/// Returns the path length.
	/// Length of the path is number of edges.
	const (long) length() const {
		return mg_path_length(ptr_);
	}

	/// Returns the vertex at the given `index`.
	/// `index` should be less than or equal to length of the path.
	const (Node) getNodeAt(uint index) const {
		auto vertex_ptr = mg_path_node_at(ptr_, index);
		assert(vertex_ptr != null);
		return Node(vertex_ptr);
	}

	/// Returns the edge at the given `index`.
	/// `index` should be less than length of the path.
	const (UnboundRelationship) getRelationshipAt(uint index) const {
		auto edge_ptr = mg_path_relationship_at(ptr_, index);
		assert(edge_ptr != null);
		return UnboundRelationship(edge_ptr);
	}

	/// Returns the orientation of the edge at the given `index`.
	/// `index` should be less than length of the path.
	/// Return: True if the edge is reversed, false otherwise.
	bool isReversedRelationshipAt(uint index) const {
		auto is_reversed = mg_path_relationship_reversed_at(ptr_, index);
		assert(is_reversed != -1);
		return is_reversed == 1;
	}

package:
	/// Create a Path using the given `mg_path`.
	this(mg_path *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Path from a copy of the given `mg_path`.
	this(const mg_path *const_ptr) {
		assert(const_ptr != null);
		this(mg_path_copy(const_ptr));
	}

	auto ptr() const { return ptr_; }

private:
	mg_path *ptr_;
}

/*
unittest {
	import std.stdio : writefln;
	writefln("testing path...");

	import testutils : connectContainer, createTestData, deleteTestData;
	import memgraph : Client, Optional, Type, Value, Node, Relationship;
	import std.conv : to;

	auto client = connectContainer();
	assert(client);

	deleteTestData(client);

	createTestData(client);

	// TODO: fix unit test, ie. use unbound relationship
	auto res = client.execute(
			"MATCH (a:Person {name: 'John'})-[edge_list:IS_MANAGER *bfs..10]-(b:Person {name: 'Valery'}) RETURN *;");
	assert(res, client.error);
	foreach (c; res) {
		writefln("c: %s", c);
		assert(c[0].type == Type.Node);
		assert(c[1].type == Type.Relationship);
		assert(c[2].type == Type.Node);
		auto a = to!Node(c[0]);
		auto r = to!Relationship(c[1]);
		auto b = to!Node(c[2]);
		assert(to!string(a) == to!string(c[0]));
		assert(to!string(r) == to!string(c[1]));
		assert(to!string(b) == to!string(c[2]));

		auto r2 = r;
		assert(r2 == r);

		auto r3 = Relationship(r);
		assert(r3 == r);

		auto r4 = Relationship(r.ptr);
		assert(r4 == r);

		assert(r.id == r2.id);
		assert(r.startId == r2.startId);
		assert(r.endId == r2.endId);
		assert(r.properties == r2.properties);

		auto v = Value(r);
		assert(v == r);
		assert(r == v);
	}
	assert(to!string(res.columns) == `["a", "r", "b"]`);
}
*/
