/// Provides a `Value` list.
module memgraph.list;

import std.string, std.conv;

import memgraph.mgclient, memgraph.detail, memgraph.value, memgraph.enums;
import memgraph.atomic;

/// An ordered sequence of values.
///
/// List may contain a mixture of different types as its elements. A list owns
/// all values stored in it.
///
/// Maximum possible list length allowed by Bolt is `uint.max`.
struct List {
	/// Disable default constructor to guarantee that this always has a valid ptr_.
	// @disable this();
	/// Disable postblit in favour of copy-ctor.
	// @disable this(this);

	this(this) {
		if (ptr_)
			ptr_ = mg_list_copy(ptr_);
	}

	/// Constructs a list that can hold at most `capacity` elements.
	/// Params: capacity = The maximum number of elements that the newly constructed
	///                    list can hold.
	this(uint capacity) {
		this(mg_list_make_empty(capacity));
	}

	/// Create a copy of `other` list.
	/*
	this(ref List other) {
		import std.stdio;
		writefln("List.copy(SharedPtr)");
		ref_ = other.ref_;
	}
	*/

	/// Create a copy of `other` list. Will copy all values into this list from `other`.
	this(inout ref List other) {
		this(mg_list_copy(other.ptr));
	}

	/// Create a list from a Value.
	this(const ref Value value) {
		assert(value.type == Type.List);
		// this(mg_list_copy(mg_value_list(value.ptr)));
		this(mg_value_list(value.ptr));
	}

	/// Compares this list with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref List other) const {
		return Detail.areListsEqual(ptr_, other.ptr_);
	}

	ref List opOpAssign(string op: "~")(const Value value)
	{
		auto rc = mg_list_append(ptr_, mg_value_copy(value.ptr));
		assert(rc == mg_error.MG_SUCCESS);
		return this;
	}

	Value opIndex(uint idx) {
		assert(ptr_ != null);
		assert(idx < mg_list_size(ptr_));
		return Value(mg_list_at(ptr_, idx));
	}

	/// Return a printable string representation of this list.
	string toString() const {
		import std.algorithm : map;
		import std.range : join;
		string ret = "[";
		for (uint i = 0; i < length; i++) {
			auto v = Value(mg_list_at(ptr_, i));
			// ret ~= to!string(Value(mg_list_at(ptr_, i)));
			ret ~= to!string(v);
			if (i < length-1)
				ret ~= ",";
		}
		ret ~= "]";
		return ret;
	}

	@property uint length() const {
		return mg_list_size(ptr_);
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

	@safe @nogc ~this() pure nothrow {
		if (ptr_ != null)
			mg_list_destroy(ptr_);
	}

package:
	/// Create a List using the given `mg_list`.
	this(mg_list *ptr) @trusted
	{
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Create a List from a copy of the given `mg_list`.
	this(const mg_list *ptr) {
		assert(ptr != null);
		// this(mg_list_copy(ptr));
		ptr_ = mg_list_copy(ptr);
	}

	auto ptr() const { return ptr_; }

private:
	mg_list *ptr_;
	// SharedPtr!mg_list ref_;
	// uint idx_;
}

unittest {
	auto l = List(42);

	l ~= Value(42);
	l ~= Value(23L);
	l ~= Value(5.43210);
	l ~= Value(true);
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

	assert(l2.ptr != null);

	const List l3 = List(l2.ptr);

	assert(l3 == l);

	l ~= Value(123_456);
	l ~= Value("Bok!");
	l ~= Value(true);

	assert(l.length == 8);
	assert(to!string(l) == "[42,23,5.4321,true,Hi,123456,Bok!,true]");

	auto v = Value(l);
	assert(v == l);
	assert(to!string(v) == to!string(l));
	assert(v == v);

	auto l4 = List(l);
	assert(l4.ptr != null);
	assert(l4.ptr != l.ptr);
	assert(l4.length == 8);
	assert(to!string(l4) == "[42,23,5.4321,true,Hi,123456,Bok!,true]");

	l ~= Value("another entry");
	assert(l.length == 9);
	assert(to!string(l) == "[42,23,5.4321,true,Hi,123456,Bok!,true,another entry]");
	v = Value(l);

	auto v2 = Value(l4);
	assert(v2 == l4);
	assert(to!string(v2) == to!string(l4));

	assert(v != v2);
}
