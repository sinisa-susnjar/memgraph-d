/// Provides a wrapper around a `Relationship`.
module memgraph.relationship;

import memgraph.mgclient, memgraph.detail, memgraph.map, memgraph.value;
import memgraph.enums, memgraph.atomic;

/// Represents a relationship from a labeled property graph.
///
/// Consists of a unique identifier (within the scope of its origin graph),
/// identifiers for the start and end nodes of that relationship, a type and a
/// map of properties. A relationship owns its type string and property map.
struct Relationship {
	@disable this();
	@disable this(this);

	/// Create a deep copy of `other` relationship.
	this(const ref Relationship other) {
		this(mg_relationship_copy(other.ref_.data));
	}

	/// Create a shared copy of `other` relationship.
	this(ref Relationship other) {
		ref_ = other.ref_;
	}

	/// Create a relationship from a Value.
	this(const ref Value value) {
		assert(value.type == Type.Relationship);
		this(mg_relationship_copy(mg_value_relationship(value.ptr)));
	}

	/// Return a printable string representation of this relationship.
	const (string) toString() const {
		return type();
	}

	/// Compares this relationship with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Relationship other) const {
		return Detail.areRelationshipsEqual(ref_.data, other.ref_.data);
	}

	/// Returns the relationship id.
	const (long) id() const {
		return mg_relationship_id(ref_.data);
	}

	/// Returns the relationship start id.
	const (long) startId() const {
		return mg_relationship_start_id(ref_.data);
	}

	/// Returns the relationship end id.
	const (long) endId() const {
		return mg_relationship_end_id(ref_.data);
	}

	/// Returns the relationship type.
	const (string) type() const {
		return Detail.convertString(mg_relationship_type(ref_.data));
	}

	/// Returns the relationship properties.
	const (Map) properties() const {
		return Map(mg_relationship_properties(ref_.data));
	}

package:
	/// Create a Relationship using the given `mg_relationship`.
	this(mg_relationship *ptr) {
		assert(ptr != null);
		ref_ = SharedPtr!mg_relationship.make(ptr, (p) { mg_relationship_destroy(p); });
	}

	/// Create a Relationship from a copy of the given `mg_relationship`.
	this(const mg_relationship *const_ptr) {
		assert(const_ptr != null);
		this(mg_relationship_copy(const_ptr));
	}

	const (mg_relationship *) ptr() const { return ref_.data; }

private:
	SharedPtr!mg_relationship ref_;
}

unittest {
	import testutils : connectContainer, createTestData, deleteTestData;
	import memgraph : Client, Optional, Type, Value, Node, Relationship;
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

		const v = Value(r);
		assert(v == r);
		assert(r == v);
		assert(v == c[1]);

		const r5 = Relationship(r3);
		assert(r5 == r3);
	}
	assert(to!string(res.columns) == `["a", "r", "b"]`);
}
