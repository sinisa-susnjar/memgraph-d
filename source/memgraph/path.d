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

unittest {
	import std.stdio : writefln;
	writefln("testing path...");

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
		writefln("c: %s", c);
		writefln("type: %s", c[0].type);

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

		writefln("p.length: %s", p.length);

		foreach (i; 0..p.length) {
			auto n = p.getNodeAt(to!uint(i));
			writefln("n(%s): %s", i, n);
			auto r = p.getRelationshipAt(to!uint(i));
			writefln("r(%s): %s", i, r);

			auto r2 = r;
			auto r3 = Value(r);
			assert(r2 == r3);
			auto r4 = UnboundRelationship(r);
			assert(r4 == r);
			auto r5 = UnboundRelationship(r3);
			assert(r5 == r);

			assert(r5.id == r.id);
			assert(r5.type == r.type);
			assert(r5.properties == r.properties);

			auto r6 = Value(r);
			assert(r3 == r6);

		}

		assert(p.ptr != null);


		// assert(to!string(l) == to!string(c[0]));

		// foreach (e; l) { writefln("type: %s: %s", e.type, e); }

		/*
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
		*/
	}
}
