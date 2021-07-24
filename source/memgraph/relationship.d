/// Provides a wrapper around a `Relationship`.
module memgraph.relationship;

// import std.string, std.conv;

import memgraph.mgclient, memgraph.detail, memgraph.map;

/// Represents a relationship from a labeled property graph.
///
/// Consists of a unique identifier (within the scope of its origin graph),
/// identifiers for the start and end nodes of that relationship, a type and a
/// map of properties. A relationship owns its type string and property map.
struct Relationship {

	/// Disable default constructor, to guarantee that this always has a valid ptr_.
	@disable this();

	/// Postblit, create a copy of the relationship from source.
	this(this) {
		if (ptr_)
			ptr_ = mg_relationship_copy(ptr_);
	}

	/// Create a copy of `other` relationship.
	this(const ref Relationship other) {
		this(mg_relationship_copy(other.ptr_));
	}

	/// Destructor. Destroys the internal `mg_relationship`.
	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_relationship_destroy(ptr_);
	}

	/// Compares this relationship with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Relationship other) const {
		return Detail.areRelationshipsEqual(ptr_, other.ptr_);
	}

	/// Returns the relationship id.
	const (long) id() const {
		return mg_relationship_id(ptr_);
	}

	/// Returns the relationship start id.
	const (long) startId() const {
		return mg_relationship_start_id(ptr_);
	}

	/// Returns the relationship end id.
	const (long) endId() const {
		return mg_relationship_end_id(ptr_);
	}

	/// Returns the relationship type.
	const (string) type() const {
		return Detail.convertString(mg_relationship_type(ptr_));
	}

	/// Returns the relationship properties.
	const (Map) properties() const {
		return Map(mg_relationship_properties(ptr_));
	}

package:
	/// Create a Relationship using the given `mg_relationship`.
	this(mg_relationship *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Relationship from a copy of the given `mg_relationship`.
	this(const mg_relationship *const_ptr) {
		assert(const_ptr != null);
		this(mg_relationship_copy(const_ptr));
	}

	auto ptr() const { return ptr_; }

private:
	mg_relationship *ptr_;
}

unittest {
	import std.stdio;
	writefln("testing relationship...");
}
