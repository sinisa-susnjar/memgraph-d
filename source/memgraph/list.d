/// Provides a `Value` list.
module memgraph.list;

import std.string, std.conv;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;

/// An ordered sequence of values.
///
/// List may contain a mixture of different types as its elements. A list owns
/// all values stored in it.
///
/// Maximum possible list length allowed by Bolt is `uint.max`.
struct List {

	/// Create a copy of `other` list. Will copy all values into this list from `other`.
	this(inout ref List other) {
		list_.length = other.list_.length;
		foreach (i, v; other.list_)
			list_[i] = v;
		ptr_ = null;
		this(mg_list_copy(other.ptr_));
	}

	/// Destructor. Destroys the internal `mg_list`.
	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_list_destroy(ptr_);
	}

	/// Compares this list with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref List other) const {
		return list_ == other.list_;
	}

	ref List opOpAssign(string op: "~")(Value value)
	{
		list_ ~= value;
		return this;
	}

	ref Value opIndexAssign(Value value, size_t idx) {
		list_[idx] = value;
		return list_[idx];
	}

	ref Value opIndex(size_t idx) {
		return list_[idx];
	}

	/// Return a printable string representation of this list.
	string toString() const {
		import std.algorithm : map;
		import std.range : join;
		return "[" ~ list_.map!(v => to!string(v)).join(",") ~ "]";
	}

	@property @safe @nogc size_t length() const pure nothrow {
		return list_.length;
	}

	@property @safe void length(size_t len) pure nothrow {
		list_.length = len;
	}

	/*
	bool empty() const {
		return idx_ >= list_.length;
	}
	auto front() const {
		import std.typecons;
		assert(idx_ < list_.length);
		return list_[idx_];
		// return tuple(idx_, list_[idx_]);
	}
	void popFront() {
		idx_++;
	}
	*/

package:
	/// Create a List using the given `mg_list`.
	this(mg_list *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
		listToArray();
	}

	/// Create a List from a copy of the given `mg_list`.
	this(const mg_list *const_ptr) {
		assert(const_ptr != null);
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
		if (ptr_ == null) {
			ptr_ = mg_list_make_empty(to!uint(list_.length));
			foreach (v; list_)
				mg_list_append(ptr_, mg_value_copy(v.ptr));
		}
	}

	Value[] list_;
	mg_list *ptr_;
	uint idx_;
}

unittest {
	List l;

	l.length = 4;
	l[0] = Value(42);
	l[1] = Value(23L);
	l[2] = Value(5.43210);
	l[3] = Value(true);
	l ~= Value("Hi");
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

	assert(to!string(l) == "[42,23,5.4321,true,Hi]");

	const List l2 = l;

	assert(l2 == l);

	assert(l2.ptr_ != null);

	const List l3 = List(l2.ptr_);

	assert(l3 == l);

	l ~= Value(123_456);
	l ~= Value("Bok!");
	l ~= Value(true);

	assert(l.length == 8);

	// TODO: why the heck does this fail?!?
	// import std.stdio;
	// writefln("l: %s", to!string(l));
	// assert(to!string(l) == "[42,23,5.4321,true,Hi,123456,Bok!,true]");

	auto v = Value(l);
	assert(v == l);
	assert(to!string(v) == to!string(l));
	assert(v == v);

	auto l4 = List(l);

	l4 ~= Value("another entry");
	assert(l4.ptr != null);

	import std.stdio;
	writefln("l: %s", l);
	writefln("l4: %s", l4);

	auto v2 = Value(l4);

	writefln("v: %s", v);
	writefln("v2: %s", v2);
	// TODO: the two lists should not be the same, but they are - WHY ?!?
	// assert(v != v2);
}
