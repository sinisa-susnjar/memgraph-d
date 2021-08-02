/// Provides a wrapper around a `UnboundRelationship`.
module memgraph.unboundrelationship;

import memgraph.mgclient, memgraph.detail, memgraph.map, memgraph.value;

/// Represents a relationship from a labeled property graph.
///
/// Like `mg_relationship`, but without identifiers for start and end nodes.
/// Mainly used as a supporting type for `mg_path`. An unbound relationship
/// owns its type string and property map.
struct UnboundRelationship {

	/// Disable default constructor, to guarantee that this always has a valid ptr_.
	@disable this();

	/// Postblit, create a copy of the unbound relationship from source.
	this(this) {
		if (ptr_)
			ptr_ = mg_unbound_relationship_copy(ptr_);
	}

	/// Create a copy of `other` unbound relationship.
	this(const ref UnboundRelationship other) {
		this(mg_unbound_relationship_copy(other.ptr_));
	}

	/// Create a unbound relationship from a Value.
	this(const ref Value value) {
		this(mg_unbound_relationship_copy(mg_value_unbound_relationship(value.ptr)));
	}

	/// Destructor. Destroys the internal `mg_unbound_relationship`.
	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_unbound_relationship_destroy(ptr_);
	}

	/// Return a printable string representation of this unbound relationship.
	const (string) toString() const {
		return type();
	}

	/// Compares this unbound relationship with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref UnboundRelationship other) const {
		return Detail.areUnboundRelationshipsEqual(ptr_, other.ptr_);
	}

	/// Returns the unbound relationship id.
	const (long) id() const {
		return mg_unbound_relationship_id(ptr_);
	}

	/// Returns the unbound relationship type.
	const (string) type() const {
		return Detail.convertString(mg_unbound_relationship_type(ptr_));
	}

	/// Returns the unbound relationship properties.
	const (Map) properties() const {
		return Map(mg_unbound_relationship_properties(ptr_));
	}

package:
	/// Create a Unbound Relationship using the given `mg_unbound_relationship`.
	this(mg_unbound_relationship *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Unbound Relationship from a copy of the given `mg_unbound_relationship`.
	this(const mg_unbound_relationship *const_ptr) {
		assert(const_ptr != null);
		this(mg_unbound_relationship_copy(const_ptr));
	}

	auto ptr() const { return ptr_; }

private:
	mg_unbound_relationship *ptr_;
}

unittest {
	import testutils : connectContainer, createTestData, deleteTestData;
	import memgraph : Client, Optional, Type, Value, Node, Relationship;
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
