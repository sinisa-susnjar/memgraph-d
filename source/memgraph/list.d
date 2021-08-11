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
	/// List needs an initial capacity.
	@disable this();

	/// Construct a new list from an array of values.
	this(const Value[] valueArray) {
		this(mg_list_make_empty(to!uint(valueArray.length)));
		foreach (ref value; valueArray) {
			immutable rc = mg_list_append(ptr_, mg_value_copy(value.ptr));
			assert(rc == mg_error.MG_SUCCESS);
		}
	}

	/// Constructs a list that can hold at most `capacity` elements.
	/// Params: capacity = The maximum number of elements that the newly constructed
	///                    list can hold.
	this(uint capacity) {
		this(mg_list_make_empty(capacity));
	}

	/// Create a copy of `other` list.
	this(inout ref List other) {
		this(mg_list_copy(other.ptr));
	}

	/// Create a list from a Value.
	this(inout ref Value value) {
		assert(value.type == Type.List);
		this(mg_list_copy(mg_value_list(value.ptr)));
	}

	/// Compares this list with `other`.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref List other) const {
		return Detail.areListsEqual(ptr_, other.ptr_);
	}

	/// Compares this list with an array of values.
	/// Return: true if same, false otherwise.
	bool opEquals(const ref Value[] valueArray) const {
		auto other = List(valueArray);
		return Detail.areListsEqual(ptr_, other.ptr_);
	}

	/// Append `value` to this list.
	ref List opOpAssign(string op: "~")(const Value value) {
		immutable rc = mg_list_append(ptr_, mg_value_copy(value.ptr));
		assert(rc == mg_error.MG_SUCCESS);
		return this;
	}

	/// Return value at position `idx` of this list.
	auto opIndex(size_t idx) const {
		assert(ptr_ != null);
		assert(idx < mg_list_size(ptr_));
		return Value(mg_list_at(ptr_, to!uint(idx)));
	}

	/// Return a printable string representation of this list.
	const (string) toString() const {
		assert(ptr_);
		immutable len = length;
		string ret = "[";
		for (uint i = 0; i < len; i++) {
			ret ~= to!string(Value(mg_list_at(ptr_, i)));
			if (i < len-1)
				ret ~= ",";
		}
		ret ~= "]";
		return ret;
	}

	/// Returns the number of values in this list.
	@property uint length() const {
		assert(ptr_ != null);
		return mg_list_size(ptr_);
	}

	/// Checks if the list as range is empty.
	@property bool empty() const { return idx_ >= length; }

	/// Returns the next element in the list range.
	auto front() const {
		import std.typecons : Tuple;
		assert(idx_ < length);
		return Tuple!(uint, "index", Value, "value")(idx_, Value(mg_list_at(ptr_, idx_)));
	}

	/// Move to the next element in the list range.
	void popFront() { idx_++; }

	this(this) {
		if (ptr_)
			ptr_ = mg_list_copy(ptr_);
	}

	~this() {
		if (ptr_)
			mg_list_destroy(ptr_);
	}

package:
	/// Create a List using the given `mg_list`.
	this(mg_list *ptr) @trusted {
		assert(ptr != null);
		// import std.stdio;
		// writefln("list.this[%s](ptr: %s)", &this, ptr);
		ptr_ = ptr;
	}

	/// Create a List from a copy of the given `mg_list`.
	this(const mg_list *ptr) {
		assert(ptr != null);
		this(mg_list_copy(ptr));
	}

	/// Return pointer to internal mg_list.
	const (mg_list *) ptr() const { return ptr_; }

private:
	mg_list *ptr_;
	uint idx_;
}

unittest {
	import std.range.primitives : isInputRange;
	assert(isInputRange!List);
}

unittest {
	auto l = List(42);

	l ~= Value(42);
	l ~= Value(23L);
	l ~= Value(5.43210);
	l ~= Value(true);
	l ~= Value("Hi");
	assert(l.length == 5);

	assert(l == l);

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

	const l4 = List(l);
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

unittest {
	auto l1 = List(5);
	l1 ~= Value(123);
	l1 ~= Value("Hello");
	l1 ~= Value(true);
	l1 ~= Value(5.5);

	auto l2 = List(5);
	l2 ~= Value(123);
	l2 ~= Value("Hello");
	l2 ~= Value(true);
	l2 ~= Value(5.5);

	assert(l1 == l2);

	l1 ~= Value("new");
	l2 ~= Value("novo");

	assert(l1 != l2);
}

unittest {
	Value[] vl;
	vl ~= Value(42);
	vl ~= Value(23L);
	vl ~= Value(5.43210);
	vl ~= Value(true);
	vl ~= Value("Hi");
	assert(vl.length == 5);

	auto l = List(vl);
	foreach (i, v; vl)
		assert(v == l[i]);
	foreach (i, v; l)
		assert(v == vl[i]);

	assert(l == vl);
}
