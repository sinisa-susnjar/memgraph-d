/// Provides a wrapper for a Bolt value.
module memgraph.value;

import std.conv, std.string;

import memgraph.mgclient, memgraph.detail, memgraph.node, memgraph.enums, memgraph.list;
import memgraph.relationship, memgraph.path, memgraph.unboundrelationship, memgraph.date;
import memgraph.time, memgraph.local_time, memgraph.date_time, memgraph.date_time_zone_id;
import memgraph.local_date_time, memgraph.duration, memgraph.point2d, memgraph.point3d;
import memgraph.map;

/// A Bolt value, encapsulating all other values.
struct Value {

	@nogc this(this) {
		if (ptr_)
			ptr_ = mg_value_copy(ptr_);
	}

	/// Destroys any value held.
	@safe @nogc ~this() {
		if (ptr_ != null)
			mg_value_destroy(ptr_);
	}

	/// Creates a Null value.
	this(typeof(null)) { this(mg_value_make_null()); }

	/// Make a new `Value` from a bool.
	this(bool value) { this(mg_value_make_bool(value)); }
	/// Make a new `Value` from a int.
	this(int value) { this(mg_value_make_integer(value)); }
	/// Make a new `Value` from a long.
	this(long value) { this(mg_value_make_integer(value)); }
	/// Make a new `Value` from a double.
	this(double value) { this(mg_value_make_float(value)); }

	/// Constructs a new `Value` from a string.
	this(const string value) {
		this(mg_value_make_string(toStringz(value)));
	}

	/// Constructs a new `Value` from a `List`.
	this(ref List value) {
		// import std.stdio;
		// writefln("Value(List): %s", mg_list_size(value.ptr));
		this(mg_value_make_list(mg_list_copy(value.ptr)));
		// writefln("this(List):  %s", mg_list_size(mg_value_list(ptr_)));
	}

	/// Constructs a new `Value` from a `Map`.
	this(ref Map value) {
		this(mg_value_make_map(mg_map_copy(value.ptr)));
	}

	/// Constructs a new vertex value from the given `vertex`.
	this(const ref Node vertex) {
		this(mg_value_make_node(mg_node_copy(vertex.ptr)));
	}

	/// Constructs a new edge value from the given `edge`.
	this(const ref Relationship edge) {
		this(mg_value_make_relationship(mg_relationship_copy(edge.ptr)));
	}

	/// Constructs an unbounded edge value from the given `edge`.
	this(const ref UnboundRelationship edge) {
		this(mg_value_make_unbound_relationship(mg_unbound_relationship_copy(edge.ptr)));
	}

	/// Constructs a path value from the given `path`.
	this(const ref Path path) {
		this(mg_value_make_path(mg_path_copy(path.ptr)));
	}

	/// Constructs a date value from the given `date`.
	this(const ref Date date) {
		this(mg_value_make_date(mg_date_copy(date.ptr)));
	}

	/// Constructs a time value from the given `time`.
	this(const ref Time time) {
		this(mg_value_make_time(mg_time_copy(time.ptr)));
	}

	/// Constructs a local time value from the given `time`.
	this(const ref LocalTime time) {
		this(mg_value_make_local_time(mg_local_time_copy(time.ptr)));
	}

	/// Constructs a date time value from the given `dateTime`.
	this(const ref DateTime dateTime) {
		this(mg_value_make_date_time(mg_date_time_copy(dateTime.ptr)));
	}

	/// Constructs a date time zone id value from the given `dateTimeZoneId`.
	this(const ref DateTimeZoneId dateTimeZoneId) {
		this(mg_value_make_date_time_zone_id(mg_date_time_zone_id_copy(dateTimeZoneId.ptr)));
	}

	/// Constructs a local date time value from the given `localDateTime`.
	this(const ref LocalDateTime localDateTime) {
		this(mg_value_make_local_date_time(mg_local_date_time_copy(localDateTime.ptr)));
	}

	/// Constructs a duration value from the given `duration`.
	this(const ref Duration duration) {
		this(mg_value_make_duration(mg_duration_copy(duration.ptr)));
	}

	/// Constructs a point 2d value from the given `Point2d`.
	this(const ref Point2d duration) {
		this(mg_value_make_point_2d(mg_point_2d_copy(duration.ptr)));
	}

	/// Constructs a point 3d value from the given `Point3d`.
	this(const ref Point3d duration) {
		this(mg_value_make_point_3d(mg_point_3d_copy(duration.ptr)));
	}

	// Fr@k repetition :)
	import std.typecons : tuple;
	private static immutable enum auto ops = [
		// D type		memgraph type		opCast/opEquals		opAssign
		typeid(double):			tuple(Type.Double,
									"mg_value_float(ptr_)",
									"mg_value_make_float"),
		typeid(int):			tuple(Type.Int,
									"to!int(mg_value_integer(ptr_))",
									"mg_value_make_integer"),
		typeid(long):			tuple(Type.Int,
									"mg_value_integer(ptr_)",
									"mg_value_make_integer"),
		typeid(bool):			tuple(Type.Bool,
									"to!bool(mg_value_bool(ptr_))",
									"mg_value_make_bool"),
		typeid(Node):			tuple(Type.Node,
									"Node(mg_value_node(ptr_))", ""),
		typeid(List):			tuple(Type.List,
									"List(mg_value_list(ptr_))", ""),
		typeid(Map):			tuple(Type.Map,
									"Map(mg_value_map(ptr_))", ""),
		typeid(Path):			tuple(Type.Path,
									"Path(mg_value_path(ptr_))", ""),
		typeid(Relationship):	tuple(Type.Relationship,
									"Relationship(mg_value_relationship(ptr_))", ""),
		typeid(UnboundRelationship):	tuple(Type.UnboundRelationship,
									"UnboundRelationship(mg_value_unbound_relationship(ptr_))", ""),
		typeid(string):			tuple(Type.String,
									"Detail.convertString(mg_value_string(ptr_))", ""),
		typeid(Date):			tuple(Type.Date,
									"Date(mg_value_date(ptr_))", ""),
		typeid(Time):			tuple(Type.Time,
									"Time(mg_value_time(ptr_))", ""),
		typeid(LocalTime):		tuple(Type.LocalTime,
									"LocalTime(mg_value_local_time(ptr_))", ""),
		typeid(DateTime):		tuple(Type.DateTime,
									"DateTime(mg_value_date_time(ptr_))", ""),
		typeid(DateTimeZoneId):	tuple(Type.DateTimeZoneId,
									"DateTimeZoneId(mg_value_date_time_zone_id(ptr_))", ""),
		typeid(LocalDateTime):	tuple(Type.LocalDateTime,
									"LocalDateTime(mg_value_local_date_time(ptr_))", ""),
		typeid(Duration):		tuple(Type.Duration,
									"Duration(mg_value_duration(ptr_))", ""),
		typeid(Point2d):		tuple(Type.Point2d,
									"Point2d(mg_value_point_2d(ptr_))", ""),
		typeid(Point3d):		tuple(Type.Point3d,
									"Point3d(mg_value_point_3d(ptr_))", ""),
	];

	/// Cast this value to type `T`.
	// auto @nogc opCast(T)() const {
	auto opCast(T)() const {
		/*
		static if (is(T == Value)) {
			return this;
		} else {
		*/
		// import std.stdio;
		// writefln("Value.opCast!%s", T.stringof);
			assert(type() == ops[typeid(T)][0]);
			// return to!T(mixin(ops[typeid(T)][1]));
			return mixin(ops[typeid(T)][1]);
		// }
	}

	/// Comparison operator for type `T`.
	/// Note: The code asserts that the current value holds a representation of type `T`.
	bool opEquals(T)(const T val) const {
		// import std.stdio;
		// writefln("Value.opEquals!%s", T.stringof);
		assert(type() == ops[typeid(T)][0]);
		return mixin(ops[typeid(T)][1]) == val;
	}

	/// Assignment operator for type `T`.
	void opAssign(T)(inout T value) {
		// import std.stdio;
		// writefln("Value.opAssign!%s", T.stringof);
		if (ptr_ != null)
			mg_value_destroy(ptr_);
		ptr_ = mixin(ops[typeid(T)][2])(value);
	}

	/// Comparison operator for another `Value`.
	bool opEquals(const ref Value other) const {
		// import std.stdio;
		// writefln("Value.opEquals");
		return Detail.areValuesEqual(ptr_, other.ptr_);
	}

	/// Assignment operator for another `Value`.
	void opAssign(const Value value) {
		if (ptr_ != null)
			mg_value_destroy(ptr_);
		ptr_ = mg_value_copy(value.ptr);
	}

	/// Assignment operator for a `string`.
	void opAssign(const string value) {
		if (ptr_ != null)
			mg_value_destroy(ptr_);
		ptr_ = mg_value_make_string(toStringz(value));
	}

	/// Return this value as a string.
	/// If the value held is not of type `Type.String`, then
	/// it will be first converted into the appropriate string
	/// representation.
	const (string) toString() const {
		switch (type()) {
			case Type.Double:				return to!string(to!double(this));
			case Type.Node:					return to!string(to!Node(this));
			case Type.Bool:					return to!string(to!bool(this));
			case Type.Int:					return to!string(to!int(this));
			case Type.String:				return Detail.convertString(mg_value_string(ptr_));
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

	/// \pre value type is Type::Relationship
	// const ConstRelationship ValueRelationship() const;
	/// \pre value type is Type::UnboundRelationship
	// const ConstUnboundRelationship ValueUnboundRelationship() const;
	/// \pre value type is Type::Path
	// const ConstPath ValuePath() const;
	/// \pre value type is Type::Date
	// const ConstDate ValueDate() const;
	/// \pre value type is Type::Time
	// const ConstTime ValueTime() const;
	/// \pre value type is Type::LocalTime
	// const ConstLocalTime ValueLocalTime() const;
	/// \pre value type is Type::DateTime
	// const ConstDateTime ValueDateTime() const;
	/// \pre value type is Type::DateTimeZoneId
	// const ConstDateTimeZoneId ValueDateTimeZoneId() const;
	/// \pre value type is Type::LocalDateTime
	// const ConstLocalDateTime ValueLocalDateTime() const;

	/// \pre value type is Type::Duration
	//const ConstDuration ValueDuration() const;
	/// \pre value type is Type::Point2d
	//const ConstPoint2d ValuePoint2d() const;
	/// \pre value type is Type::Point3d
	//const ConstPoint3d ValuePoint3d() const;

	/// Return the type of value being held.
	@property Type type() const {
		// if (ptr_ == null) return Type.Null;
		return Detail.convertType(mg_value_get_type(ptr_));
	}

package:
	/// Constructs an object that becomes the owner of the given `value`.
	/// `value` is destroyed when a `Value` object is destroyed.
	/*
	*/
	@safe @nogc this(mg_value *ptr) {
		assert(ptr != null);
		ptr_ = ptr;
	}

	/// Creates a new Value from a copy of the given `mg_value`.
	// @safe @nogc this(const mg_value *const_ptr) {
	this(const mg_value *const_ptr) {
		// if (const_ptr == null) {
			// import std.stdio;
			// writefln("Oops, trouble!");
		// }
		assert(const_ptr != null);
		this(mg_value_copy(const_ptr));
	}

	auto ptr() inout { return ptr_; }

private:
	mg_value *ptr_;
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

	auto v2 = v1;
	assert(v1.type == v2.type);
	assert(v1 == v2);
	assert(v2 == 42);

	auto v3 = Value(42);
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

	auto v2 = v1;
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

	auto v2 = v1;
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
	// import std.stdio;
	// writefln("l: %s", l.length);

	assert(l.length == 4);

	auto v = Value(l);
	assert(v.type == Type.List);

	// import std.stdio;
	// writefln("v: %s", to!string(v));
	// writefln("l: %s", l);
	assert(l == v);
	assert(v == l);

	auto v2 = Value(l);
	assert(v == v2);

	auto l2 = to!List(v);
	// auto l2 = to!List(List(mg_value_list(v.ptr_)));
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

	auto v2 = Value(m);
	assert(v2.type == Type.Map);

	assert(v1 == v2);

	auto m2 = to!Map(v1);
	assert(m == m2);
}

// null tests
unittest {
	auto v1 = Value(null);
	assert(v1.type == Type.Null);
	auto v2 = Value(null);
	assert(v2.type == Type.Null);

	assert(v1 == v2);
}

// unknown value test
unittest {
	import std.exception, core.exception;

	auto v = Value(1);
	assert(v.type == Type.Int);

	v.ptr_.type = mg_value_type.MG_VALUE_TYPE_UNKNOWN;

	assertThrown!AssertError(v.type);

	auto v2 = Value(1);
	v2.ptr_.type = mg_value_type.MG_VALUE_TYPE_UNKNOWN;

	assertThrown!AssertError(v == v2);

	v.ptr_.type = cast(mg_value_type)-1;

	assertThrown!AssertError(v.type);

	v2.ptr_.type = cast(mg_value_type)-1;

	assertThrown!AssertError(v == v2);
}

// comparison tests
unittest {
	auto v1 = Value(1);
	assert(v1.type == Type.Int);
	assert(v1 == v1);

	auto v2 = Value(2.71828);
	assert(v2.type == Type.Double);
	assert(v1 != v2);
}
