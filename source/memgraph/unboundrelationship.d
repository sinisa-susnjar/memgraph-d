/// Provides a wrapper around a `UnboundRelationship`.
module memgraph.unboundrelationship;

import memgraph.mgclient, memgraph.detail, memgraph.map, memgraph.value, memgraph.enums;

/// Represents a relationship from a labeled property graph.
///
/// Like `mg_relationship`, but without identifiers for start and end nodes.
/// Mainly used as a supporting type for `mg_path`. An unbound relationship
/// owns its type string and property map.
struct UnboundRelationship {
	/// Create a copy of `other` unbound relationship.
	this(inout ref UnboundRelationship other) {
		this(mg_unbound_relationship_copy(other.ptr));
	}

	/// Create a unbound relationship from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.UnboundRelationship);
		this(mg_unbound_relationship_copy(mg_value_unbound_relationship(value.ptr)));
	}

	/// Return a printable string representation of this unbound relationship.
	const (string) toString() const {
		return type;
	}

	/// Compares this unbound relationship with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref UnboundRelationship other) const {
		return Detail.areUnboundRelationshipsEqual(ptr, other.ptr);
	}

	/// Returns the unbound relationship id.
	const (long) id() const {
		assert(ptr != null);
		return mg_unbound_relationship_id(ptr);
	}

	/// Returns the unbound relationship type.
	const (string) type() const {
		assert(ptr != null);
		return Detail.convertString(mg_unbound_relationship_type(ptr));
	}

	/// Returns the unbound relationship properties.
	const (Map) properties() const {
		assert(ptr != null);
		return Map(mg_unbound_relationship_properties(ptr));
	}

	this(this) {
		if (ptr_)
			ptr_ = mg_unbound_relationship_copy(ptr_);
	}

	~this() {
		if (ptr_)
			mg_unbound_relationship_destroy(ptr_);
	}

package:
	/// Create a Unbound Relationship using the given `mg_unbound_relationship`.
	this(mg_unbound_relationship *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Unbound Relationship from a copy of the given `mg_unbound_relationship`.
	this(const mg_unbound_relationship *ptr) {
		assert(ptr != null);
		this(mg_unbound_relationship_copy(ptr));
	}

	const (mg_unbound_relationship *) ptr() const { return ptr_; }

private:
	mg_unbound_relationship *ptr_;
}

unittest {
	import testutils : connectContainer, createTestData, deleteTestData;
	import memgraph : Client, Type, Value, Node, Relationship;
	import std.conv : to;

	auto client = connectContainer();
	assert(client);

	deleteTestData(client);

	createTestData(client);

	// TODO: fix unit test, ie. use unbound relationship, e.g. via Path
	auto res = client.execute(
					"MATCH (a:Person)-[r:IS_MANAGER]-(b:Person) " ~
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

		auto v = Value(r);
		assert(v == r);
		assert(r == v);
		assert(to!string(v) == to!string(r));
	}
	assert(to!string(res.columns) == `["a", "r", "b"]`);
}
