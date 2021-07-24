/// Provides a `Value` list.
module memgraph.list;

import std.string, std.conv, std.stdio;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// An ordered sequence of values.
///
/// List may contain a mixture of different types as its elements. A list owns
/// all values stored in it.
///
/// Maximum possible list length allowed by Bolt is `uint.max`.
struct List {

	/// Create a copy of `other` list. Will copy all values into this list from `other`.
	this(const ref List other) {
		list_.length = other.list_.length;
		foreach (i, v; other.list_)
			list_[i] = v;
		this(mg_list_copy(other.ptr_));
	}

	/// Destructor. Destroys the internal `mg_list`.
	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_list_destroy(ptr_);
	}

	/// Returns the value at index `idx`.
	/// Will throw if the given `idx` is out of range.
	/// The time complexity is constant.
	/*
	inout ref Value opIndex(const uint idx) {
		return list_[idx];
	}
	*/

	/*
	/// Returns the value associated with the given `key`.
	/// This method will `assert` that the `key` exists.
	const Value opIndex(const string key) {
		assert(key in map_);
		return map_[key];
	}
	*/

	/// Compares this list with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref List other) const {
		return list_ == other.list_;
	}

	/*
	/// Remove given `key` from map.
	/// Return: true if key was removed, false otherwise.
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

	/*
	auto opOpAssign(op)(const Value v) {
		static if (op == "~=") {
			list_ ~= v;
		}
		static assert(0);
	}
	*/
	// @property auto list() inout { return list_; }
	// @property auto length(size_t len) { list_.length = len; }
	// @property auto length() { return list_.length; }

	@property @safe @nogc ref inout(Value[]) list() inout pure nothrow {
		return list_;
	}

package:
	/// Create a List using the given `mg_list`.
	this(mg_list *ptr) {
		assert(ptr != null);
		// writefln("map mg_map ctor");
		ptr_ = ptr;
		listToArray();
	}

	/// Create a List from a copy of the given `mg_list`.
	this(const mg_list *const_ptr) {
		assert(const_ptr != null);
		// writefln("map const mg_map ctor");
		this(mg_list_copy(const_ptr));
		listToArray();
	}

	auto ptr() { arrayToList(); return ptr_; }

private:
	// Copy the contents from the mg_list into an array for
	// faster processing and also to enable range semantics.
	void listToArray() {
		if (ptr_) {
			const auto sz = mg_list_size(ptr_);
			list_.length = sz;
			for (auto i=0; i < sz; i++)
				list_[i] = Value(mg_value_copy(mg_list_at(ptr_, i)));
		}
	}

	// Copy the contents from the `Value` array into the mg_list
	// when requested.
	void arrayToList() {
		// import std.stdio;
		// writefln("arrayToList: ptr: %s len: %s", ptr_, list_.length);
		if (ptr_ == null) {
			ptr_ = mg_list_make_empty(to!uint(list_.length));
			foreach (v; list_)
				mg_list_append(ptr_, mg_value_copy(v.ptr));
		}
		// writefln("copied %s values to list %s", list_.length, ptr_);
	}

	Value[] list_;
	alias list this;
	mg_list *ptr_;
}

unittest {
	List l;

	l.length = 5;
	l[0] = Value(42);
	l[1] = Value(23L);
	l[2] = Value(5.43210);
	l[3] = Value(true);
	l[4] = Value("Hi");
	assert(l.length == 5);

	assert(l[0].type == Type.Int);
	assert(l[0] == 42);
	assert(l[1].type == Type.Int);
	assert(l[1] == 23L);
	assert(l[2].type == Type.Double);
	assert(l[2] == 5.43210);
	assert(l[3].type == Type.Bool);
	assert(l[3] == true);
	assert(l[4].type == Type.String);
	assert(l[4] == "Hi");

	assert(l.ptr != null);

	const List l2 = l;

	// writefln("%s [%s] %s [%s]", l[0], l[0].ptr, l2[0], l2[0].ptr);

	assert(l2 == l);

	// l.length = 10;
	// assert(l.length == 10);

	assert(l2.ptr_ != null);

	const List l3 = List(l2.ptr_);

	assert(l3 == l);

	foreach (i, v; l3) {
		assert(l[i].type == l3[i].type);
		assert(l[i] == l3[i]);
	}

	l ~= Value(123_456);
	l ~= Value("Bok!");
	l ~= Value(true);

	assert(l.length == 8);
}
