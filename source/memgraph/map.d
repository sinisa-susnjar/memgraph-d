/// Provides a map (i.e. key/value) tuple.
module memgraph.map;

import std.string, std.conv;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// Sized sequence of pairs of keys and values.
/// Maximum possible map size allowed by Bolt protocol is `uint.max`.
///
/// Map may contain a mixture of different types as values. A map owns all keys
/// and values stored in it.
///
/// Can be used like a standard D hash map (because it is one under the hood).
struct Map {
	/// Map needs an initial capacity.
	@disable this();

	/// Construct a new map from an associative array of key, value pairs.
	this(const ref Value[string] valueMap) {
		this(mg_map_make_empty(to!uint(valueMap.length)));
		foreach (ref key, ref value; valueMap) {
			immutable rc = mg_map_insert(ptr_, toStringz(key), mg_value_copy(value.ptr));
			assert(rc == mg_error.MG_SUCCESS);
		}
	}

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
	/*
	ref Value opIndex(const string key) {
		return map_.require(key, Value());
	}
	*/

	/// Returns the value associated with the given `key`.
	auto opIndex(const string key) const {
		return Value(mg_map_at(ptr_, toStringz(key)));
	}

	/// Compares this map with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const Map other) const {
		return Detail.areMapsEqual(ptr_, other.ptr);
	}

	/// Compares this map with an associative array of key, value pairs.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Value[string] valueMap) const {
		auto other = Map(valueMap);
		return Detail.areMapsEqual(ptr_, other.ptr_);
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
	*/

	/*
	auto opBinary(string op)(const char[] key) if (op == "in") {
		return mg_map_at(ptr_, toStringz(key)) != null;
	}
	*/

	auto opBinaryRight(string op)(const char[] key) if (op == "in") {
		return mg_map_at(ptr_, toStringz(key)) != null;
	}

	auto length() const {
		return mg_map_size(ptr_);
	}

	// @property auto toAA() const { return map_; }

	/*
	@property @safe @nogc ref inout(Value[string]) toAA() inout pure nothrow {
		return map_;
	}
	*/

	/// Return a printable string representation of this map.
	const (string) toString() const {
		assert(ptr_);
		immutable len = length;
		string ret = "{";
		for (uint i = 0; i < len; i++) {
			ret ~= Detail.convertString(mg_map_key_at(ptr_, i)) ~ ":" ~
					to!string(Value(mg_map_value_at(ptr_, i)));
			if (i < len-1)
				ret ~= ",";
		}
		ret ~= "}";
		return ret;
	}

	/*
	ref Value opIndexOpAssign(string op)(int value, const char[] key) if (op == "=") {
		auto val = Value(value);
		immutable rc = mg_map_insert(ptr_, toStringz(key), val.ptr);
		assert(rc == mg_error.MG_SUCCESS);
		return val;
	}
	*/

	Value opIndexAssign(T)(const T value, const string key) {
		auto val = Value(value);
		immutable rc = mg_map_insert(ptr_, toStringz(key), mg_value_copy(val.ptr));
		assert(rc == mg_error.MG_SUCCESS);
		return val;
	}

	/// Checks if the map as range is empty.
	@property bool empty() const { return idx_ >= length; }

	/// Returns the next element in the map range.
	@property auto front() const {
		import std.typecons : Tuple;
		assert(idx_ < length);
		return Tuple!(string, "key", Value, "value")(
					Detail.convertString(mg_map_key_at(ptr_, idx_)),
					Value(mg_map_value_at(ptr_, idx_)));
	}

	/// Move to the next element in the list range.
	void popFront() { idx_++; }

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
	mg_map *ptr_;
	uint idx_;
}

unittest {
	import std.range.primitives : isInputRange;
	assert(isInputRange!Map);
}

unittest {
	auto m1 = Map(10);
	m1["key1"] = 123;
	auto m2 = Map(10);
	assert(m1 != m2);

	m2["key1"] = 456;
	assert(m1 != m2);

	m1["key2"] = "Hi!";
	m2["key99"] = "Bok!";
	assert(m1 != m2);
}

unittest {
	auto m1 = Map(10);
	m1["key1"] = 123;
	auto m2 = Map(10);
	assert(m1 != m2);

	m2["key1"] = 123;
	assert(m1 == m2);

	m1["key2"] = "Hi!";
	m2["key99"] = "Bok!";
	assert(m1 != m2);
}

unittest {
	auto m = Map(32);
	m["answer_to_life_the_universe_and_everything"] = 42;
	assert("answer_to_life_the_universe_and_everything" in m);
	assert(m["answer_to_life_the_universe_and_everything"] == 42);
	assert(m.length == 1);
	assert(to!string(m) == "{answer_to_life_the_universe_and_everything:42}");

	m["id"] = 0;
	m["age"] = 40;
	m["name"] = "John";
	m["isStudent"] = false;
	m["score"] = 5.0;
	assert(m.length == 6);

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
	assert(m.ptr != null);

	import std.algorithm : map;
	assert(m.map!(p => p.key ~ ":" ~ to!string(p.value)).join(",") ==
			"answer_to_life_the_universe_and_everything:42,id:0,age:40,name:John,isStudent:false,score:5");

	auto m2 = Map(m);
	assert(m == m2);

	auto v = Value(m2);
	assert(v == m);

	assert(to!string(v) == to!string(m));
}

unittest {
	Value[string] vm;
	vm["int"] = 42;
	vm["long"] = 23L;
	vm["double"] = 5.43210;
	vm["bool"] = true;
	vm["string"] = "Hi";
	assert(vm.length == 5);

	auto m = Map(vm);
	foreach (k, v; vm)
		assert(v == m[k]);
	foreach (k, v; m)
		assert(v == vm[k]);

	assert(m == vm);
}
