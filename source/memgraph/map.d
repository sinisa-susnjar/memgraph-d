/// Provides a map (i.e. key/value) tuple.
module memgraph.map;

import std.string, std.conv;

import memgraph.mgclient, memgraph.detail, memgraph.value;

/// Sized sequence of pairs of keys and values.
/// Maximum possible map size allowed by Bolt protocol is `uint.max`.
///
/// Map may contain a mixture of different types as values. A map owns all keys
/// and values stored in it.
///
/// Can be used like a standard D hash map (because it is one under the hood).
struct Map {

	/// Constructs a map that can hold at most `capacity` elements.
	/// Params: capacity = The maximum number of elements that the newly constructed
	///                    list can hold.
	this(uint capacity) {
		this(mg_map_make_empty(capacity));
	}

	/// Create a copy of `other` map.
	this(inout ref Map other) {
		this(mg_map_copy(other.ptr));
	}

	/// Create a map from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.Map);
		this(mg_map_copy(mg_value_map(value.ptr)));
	}

	this(this) {
		if (ptr_)
			ptr_ = mg_map_copy(ptr_);
	}

	/// Destructor. Destroys the internal `mg_map`.
	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_map_destroy(ptr_);
	}

	/// Returns the value associated with the given `key`.
	/// If the given `key` does not exist, an empty `Value` is returned.
	/// The time complexity is constant.
	ref Value opIndex(const string key) {
		return map_.require(key, Value());
	}

	/// Returns the value associated with the given `key`.
	/// This method will `assert` that the `key` exists.
	auto opIndex(const string key) const {
		assert(key in map_);
		return map_[key];
	}

	/// Compares this map with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const Map other) const {
		return map_ == other.map_;
	}

	/// Remove given `key` from map.
	/// Return: true if key was removed, false otherwise.
	/*
	auto remove(const string key) {
		return map_.remove(key);
	}
	/// Clears the map.
	void clear() {
		map_.clear();
	}
	*/

	/*
	auto opDispatch(string name, T...)(T vals) {
		return mixin("map_." ~ name)(vals);
	}

	auto opBinary(string op)(const string key) {
		static assert(op == "in");
		return key in map_;
	}
	*/

	// @property auto toAA() const { return map_; }

	@property @safe @nogc ref inout(Value[string]) toAA() inout pure nothrow {
		return map_;
	}

	/// Return a printable string representation of this map.
	const (string) toString() const {
		import std.algorithm : map;
		import std.range : join;
		return "{" ~ map_.byKeyValue.map!(p => p.key ~ ":" ~ to!string(p.value)).join(" ") ~ "}";
	}

package:
	/// Create a Map using the given `mg_map`.
	this(mg_map *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a Map from a copy of the given `mg_map`.
	this(const mg_map *ptr) {
		assert(ptr != null);
		this(mg_map_copy(ptr));
	}

	/// Return pointer to internal mg_map.
	const (mg_map *) ptr() const { return ptr_; }

private:
	// Copy the contents from the mg_map into an associative array
	// for faster processing and also to enable range semantics.
	void mapToAA() {
		if (ptr_) {
			const auto sz = mg_map_size(ptr_);
			for (auto i=0; i < sz; i++) {
				auto key = Detail.convertString(mg_map_key_at(ptr_, i));
				auto value = Value(mg_map_value_at(ptr_, i));
				map_[key] = value;
			}
		}
	}

	// Copy the contents from the associative array into the mg_map
	// when requested.
	void AAToMap() {
		if (ptr_ == null) {
			ptr_ = mg_map_make_empty(to!uint(map_.length));
			foreach (k, v; map_) {
				mg_map_insert_unsafe(ptr_, toStringz(k), mg_value_copy(v.ptr));
			}
		}
	}

	mg_map *ptr_;
}

unittest {
	Map m;
	m["answer_to_life_the_universe_and_everything"] = 42;
	assert("answer_to_life_the_universe_and_everything" in m);
	assert(m["answer_to_life_the_universe_and_everything"] == 42);
	assert(m.length == 1);
	assert(to!string(m) == "{answer_to_life_the_universe_and_everything:42}");

	assert(m.remove("answer_to_life_the_universe_and_everything"));
	assert("answer_to_life_the_universe_and_everything" ! in m);
	assert(m.length == 0);
	assert(to!string(m) == "{}");

	m["id"] = 0;
	m["age"] = 40;
	m["name"] = "John";
	m["isStudent"] = false;
	m["score"] = 5.0;
	assert(m.length == 5);

	assert("id" in m);
	assert(m["id"] == 0);
	assert("age" in m);
	assert(m["age"] == 40);
	assert("name" in m);
	assert(m["name"] == "John");
	assert("isStudent" in m);
	assert(m["isStudent"] == false);
	assert("score" in m);
	assert(m["score"] == 5.0);

	// This is a package internal method, not for public consumption.
	assert(m.ptr_ == null);
	const p = m.ptr();
	assert(p != null);

	m.clear();
	assert(m.length == 0);
}
