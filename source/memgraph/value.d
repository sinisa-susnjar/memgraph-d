/// Provides a wrapper for a Bolt value.
module memgraph.value;

import std.conv, std.string;
import std.typecons : tuple;

import memgraph.detail;
import memgraph;

// Internal mapping between D type and a tuple containing the memgraph type, the
// operation to be applied when doing an opCast/opEquals, and the operation to be
// applied during construction of a value or an opAssign.
private static immutable enum mixinOps = [
	typeid(double): tuple(Type.Double,
		"mg_value_float(ref_.data)", "mg_value_make_float(val)"),
	typeid(int): tuple(Type.Int,
		"to!int(mg_value_integer(ref_.data))", "mg_value_make_integer(val)"),
	typeid(long): tuple(Type.Int,
		"mg_value_integer(ref_.data)", "mg_value_make_integer(val)"),
	typeid(bool): tuple(Type.Bool,
		"to!bool(mg_value_bool(ref_.data))", "mg_value_make_bool(val)"),
	typeid(Node): tuple(Type.Node,
		"Node(mg_value_node(ref_.data))", "mg_value_make_node(mg_node_copy(val.ptr))"),
	typeid(List): tuple(Type.List,
		"List(mg_value_list(ref_.data))", "mg_value_make_list(mg_list_copy(val.ptr))"),
	typeid(Map): tuple(Type.Map,
		"Map(mg_value_map(ref_.data))", "mg_value_make_map(mg_map_copy(val.ptr))"),
	typeid(Path): tuple(Type.Path,
		"Path(mg_value_path(ref_.data))", "mg_value_make_path(mg_path_copy(val.ptr))"),
	typeid(Relationship): tuple(Type.Relationship,
		"Relationship(mg_value_relationship(ref_.data))", "mg_value_make_relationship(mg_relationship_copy(val.ptr))"),
	typeid(UnboundRelationship): tuple(Type.UnboundRelationship,
		"UnboundRelationship(mg_value_unbound_relationship(ref_.data))", "mg_value_make_unbound_relationship(mg_unbound_relationship_copy(val.ptr))"),
	typeid(string): tuple(Type.String,
		"Detail.convertString(mg_value_string(ref_.data))", "mg_value_make_string(toStringz(val))"),
	typeid(char[]): tuple(Type.String,
		"Detail.convertString(mg_value_string(ref_.data))", "mg_value_make_string(toStringz(val))"),
	typeid(Date): tuple(Type.Date,
		"Date(mg_value_date(ref_.data))", "mg_value_make_date(mg_date_copy(val.ptr))"),
	typeid(Time): tuple(Type.Time,
		"Time(mg_value_time(ref_.data))", "mg_value_make_time(mg_time_copy(val.ptr))"),
	typeid(LocalTime): tuple(Type.LocalTime,
		"LocalTime(mg_value_local_time(ref_.data))", "mg_value_make_local_time(mg_local_time_copy(val.ptr))"),
	typeid(DateTime): tuple(Type.DateTime,
		"DateTime(mg_value_date_time(ref_.data))", "mg_value_make_date_time(mg_date_time_copy(val.ptr))"),
	typeid(DateTimeZoneId): tuple(Type.DateTimeZoneId,
		"DateTimeZoneId(mg_value_date_time_zone_id(ref_.data))", "mg_value_make_date_time_zone_id(mg_date_time_zone_id_copy(val.ptr))"),
	typeid(LocalDateTime): tuple(Type.LocalDateTime,
		"LocalDateTime(mg_value_local_date_time(ref_.data))", "mg_value_make_local_date_time(mg_local_date_time_copy(val.ptr))"),
	typeid(Duration): tuple(Type.Duration,
		"Duration(mg_value_duration(ref_.data))", "mg_value_make_duration(mg_duration_copy(val.ptr))"),
	typeid(Point2d): tuple(Type.Point2d,
		"Point2d(mg_value_point_2d(ref_.data))", "mg_value_make_point_2d(mg_point_2d_copy(val.ptr))"),
	typeid(Point3d): tuple(Type.Point3d,
		"Point3d(mg_value_point_3d(ref_.data))", "mg_value_make_point_3d(mg_point_3d_copy(val.ptr))"),
];

/// A Bolt value, encapsulating all other values.
struct Value {

	/// Make a Null value.
	this(typeof(null)) { this(mg_value_make_null()); }

	/// Make a new value of type `T` and initialise it with `val`.
	this(T)(const T val) {
		this(mixin(mixinOps[typeid(T)][2]));
	}

	/// Constructs a new `Value` from a `Map`.
	this(ref Map value) { this(mg_value_make_map(mg_map_copy(value.ptr))); }

	/// Cast this value to type `T`.
	auto opCast(T)() const {
		assert(ref_.data != null);
		assert(type == mixinOps[typeid(T)][0]);
		return mixin(mixinOps[typeid(T)][1]);
	}

	/// Comparison operator for type `T`.
	/// Note: The code asserts that the current value holds a representation of type `T`.
	bool opEquals(T)(const T val) const {
		assert(ref_.data != null);
		assert(type == mixinOps[typeid(T)][0]);
		return mixin(mixinOps[typeid(T)][1]) == val;
	}

	/// Assignment operator for type `T`.
	void opAssign(T)(inout T val) {
		ref_ = SharedPtr!mg_value.make(mixin(mixinOps[typeid(T)][2]), (p) { mg_value_destroy(p); });
	}

	/// Comparison operator for another `Value`.
	/*
	bool opEquals(const ref Value other) const {
		return Detail.areValuesEqual(ref_.data, other.ref_.data);
	}
	*/

	bool opEquals(const Value other) const {
		return Detail.areValuesEqual(ref_.data, other.ref_.data);
	}

	/// Assignment operator for another `Value`.
	ref Value opAssign(Value value) @safe return {
		import std.algorithm.mutation : swap;
		swap(this, value);
		return this;
	}

	/// Return this value as a string.
	/// If the value held is not of type `Type.String`, then
	/// it will be first converted into the appropriate string
	/// representation.
	string toString() const {
		switch (type) {
			case Type.Double:				return to!string(to!double(this));
			case Type.Node:					return to!string(to!Node(this));
			case Type.Bool:					return to!string(to!bool(this));
			case Type.Int:					return to!string(to!int(this));
			case Type.String:				return Detail.convertString(mg_value_string(ref_.data));
			case Type.Relationship:			return to!string(to!Relationship(this));
			case Type.UnboundRelationship:	return to!string(to!UnboundRelationship(this));
			case Type.List:					return to!string(to!List(this));
			case Type.Map:					return to!string(to!Map(this));
			case Type.Path:					return to!string(to!Path(this));
			case Type.Date:					return to!string(to!Date(this));
			case Type.Time:					return to!string(to!Time(this));
			case Type.LocalTime:			return to!string(to!LocalTime(this));
			case Type.DateTime:				return to!string(to!DateTime(this));
			case Type.DateTimeZoneId:		return to!string(to!DateTimeZoneId(this));
			case Type.LocalDateTime:		return to!string(to!LocalDateTime(this));
			case Type.Duration:				return to!string(to!Duration(this));
			case Type.Point2d:				return to!string(to!Point2d(this));
			case Type.Point3d:				return to!string(to!Point3d(this));
			default: assert(0, "unhandled type: " ~ to!string(type()));
		}
	}

	/// Return the type of value being held.
	@property Type type() const {
		assert(ref_.data != null);
		return Detail.convertType(mg_value_get_type(ref_.data));
	}

package:
	/// Create a Value using the given `mg_value`.
	this(mg_value *ptr) {
		assert(ptr != null);
		ref_ = SharedPtr!mg_value.make(ptr, (p) { mg_value_destroy(p); });
	}

	/// Create a Value from a copy of the given `mg_value`.
	this(const mg_value *ptr) {
		assert(ptr != null);
		this(mg_value_copy(ptr));
	}

	auto ptr() const { return ref_.data; }

private:
	SharedPtr!mg_value ref_;
}

// string tests
unittest {
	auto v1 = Value("Zdravo, svijete!");
	assert(v1.type == Type.String);
	assert(v1 == "Zdravo, svijete!");

	auto v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == "Zdravo, svijete!");

	assert(v1.toString == "Zdravo, svijete!");
	assert(to!string(v1) == "Zdravo, svijete!");

	v2 = "Hello there";
	assert(v2 == "Hello there");
	assert(v2.toString == "Hello there");
	assert(to!string(v2) == "Hello there");
}

unittest {
	const v1 = Value("Zdravo, svijete!");
	assert(v1.type == Type.String);
	assert(v1 == "Zdravo, svijete!");

	const v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == "Zdravo, svijete!");

	assert(v1.toString == "Zdravo, svijete!");
	assert(to!string(v1) == "Zdravo, svijete!");
}

// long/int tests
unittest {
	auto v1 = Value(42L);
	assert(v1.type == Type.Int);
	assert(v1 == 42);
	assert(v1 == 42L);

	const v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == 42);

	const v3 = Value(42);
	assert(v1.type == v3.type);
	assert(v1 == v3);
	assert(v3 == 42);

	assert(v1.toString == "42");

	v1 = 23;
	assert(v1 == 23);
	assert(to!int(v1) == 23);
	assert(to!long(v1) == 23);
}

unittest {
	const v1 = Value(42L);
	assert(v1.type == Type.Int);
	assert(v1 == 42);
	assert(v1 == 42L);

	const v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == 42);

	const v3 = Value(42);
	assert(v1.type == v3.type);
	assert(v1 == v3);
	assert(v3 == 42);

	assert(v1.toString == "42");
}

// bool tests
unittest {
	auto v1 = Value(true);
	assert(v1.type == Type.Bool);
	assert(v1 == true);

	const v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == true);

	assert(v1.toString == "true");

	assert(to!bool(v1) == true);
	assert(v1 == true);
}

unittest {
	const v1 = Value(true);
	assert(v1.type == Type.Bool);
	assert(v1 == true);

	const v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == true);

	assert(v1.toString == "true");

	assert(to!bool(v1) == true);
	assert(v1 == true);
}

// double tests
unittest {
	auto v1 = Value(3.1415926);
	assert(v1.type == Type.Double);
	assert(v1 == 3.1415926);

	const v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == 3.1415926);

	assert(v1.toString == "3.14159");

	assert(to!double(v1) == 3.1415926);
	assert(v1 == 3.1415926);
}

unittest {
	const v1 = Value(3.1415926);
	assert(v1.type == Type.Double);
	assert(v1 == 3.1415926);

	const v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == 3.1415926);

	assert(v1.toString == "3.14159");

	assert(to!double(v1) == 3.1415926);
	assert(v1 == 3.1415926);
}

// list tests
unittest {
	auto l = List(8);
	l ~= Value(123);
	l ~= Value("Hello");
	l ~= Value(3.21);
	l ~= Value(true);

	assert(l.length == 4);

	auto v = Value(l);
	assert(v.type == Type.List);

	assert(l == v);
	assert(v == l);

	const v2 = Value(l);
	assert(v == v2);

	const l2 = to!List(v);
	assert(l2 == l);
}

// map tests
unittest {
	Map m;
	m["key1"] = 1;
	m["key2"] = true;
	m["key3"] = 2.71828;
	m["key4"] = "test";

	auto v1 = Value(m);
	assert(v1.type == Type.Map);

	const v2 = Value(m);
	assert(v2.type == Type.Map);

	assert(v1 == v2);

	const m2 = to!Map(v1);
	assert(m == m2);
}

// null tests
unittest {
	const v1 = Value(null);
	assert(v1.type == Type.Null);
	const v2 = Value(null);
	assert(v2.type == Type.Null);

	assert(v1 == v2);
}

// unknown value test
unittest {
	import std.exception, core.exception;

	auto v = Value(1);
	assert(v.type == Type.Int);

	v.ref_.data.type = mg_value_type.MG_VALUE_TYPE_UNKNOWN;

	assertThrown!AssertError(v.type);

	auto v2 = Value(1);
	v2.ref_.data.type = mg_value_type.MG_VALUE_TYPE_UNKNOWN;

	assertThrown!AssertError(v == v2);

	v.ref_.data.type = cast(mg_value_type)-1;

	assertThrown!AssertError(v.type);

	v2.ref_.data.type = cast(mg_value_type)-1;

	assertThrown!AssertError(v == v2);
}

// comparison tests
unittest {
	const v1 = Value(1);
	assert(v1.type == Type.Int);
	assert(v1 == v1);

	const v2 = Value(2.71828);
	assert(v2.type == Type.Double);
	assert(v1 != v2);
}

// assignment tests
unittest {
	Value v;
	v = 42;
	assert(v == 42);
	v = 2.71828;
	assert(v == 2.71828);
	v = "Hello";
	assert(v == "Hello");
	v = true;
	assert(v == true);

	auto l = List(10);
	v = l;
}
