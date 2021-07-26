/// Provides a wrapper for a Bolt value.
module memgraph.value;

import std.conv, std.string;

import memgraph.mgclient, memgraph.detail, memgraph.node, memgraph.enums, memgraph.list;
import memgraph.relationship;

/// A Bolt value, encapsulating all other values.
struct Value {

	/// Creates a new Value from a copy of the given `Value`.
	/*
	@safe @nogc this(const ref Value other) {
	// this(const ref Value other) {
		// import std.stdio;
		// writefln("this copy ctor: value: %s", other.toString);
		this(mg_value_copy(other.ptr_));
	}
	*/
	this(this) {
		if (ptr_)
			ptr_ = mg_value_copy(ptr_);
	}

	/// Destroys any value held.
	@safe @nogc ~this() {
		if (ptr_ != null)
			mg_value_destroy(ptr_);
	}

	// Creates a Null value.
	// TODO: not sure this is worth the trouble atm
	// this(typeof(null)) { this(mg_value_make_null()); }
	// @disable this();

	/// Make a new `Value` from a bool.
	this(bool value) { this(mg_value_make_bool(value)); }
	/// Make a new `Value` from a int.
	this(int value) { this(mg_value_make_integer(value)); }
	/// Make a new `Value` from a long.
	this(long value) { this(mg_value_make_integer(value)); }
	/// Make a new `Value` from a double.
	this(double value) { this(mg_value_make_float(value)); }

	/// Make a new `Value` from a string.
	this(const string value) {
		this(mg_value_make_string(toStringz(value)));
	}

	/// Make a new `Value` from a `List`.
	this(ref List value) {
		// import std.stdio;
		// writefln("this(List)");
		this(mg_value_make_list(mg_list_copy(value.ptr)));
		// writefln("done this(List)");
	}

	/// \brief Constructs a list value and takes the ownership of the `list`.
	/// \note
	/// Behaviour of accessing the `list` after performing this operation is
	/// considered undefined.
	// this(List &&list);

	/// \brief Constructs a map value and takes the ownership of the `map`.
	/// \note
	/// Behaviour of accessing the `map` after performing this operation is
	/// considered undefined.
	// this(Map &&map);

/* TODO
	/// Constructs a vertex value and takes the ownership of the given `vertex`.
	this(ref Node vertex) {
		this(mg_value_make_node(vertex.ptr));
		// vertex.ptr = null;
	}
*/

	/// Constructs a new vertex value from the given `vertex`.
	this(const ref Node vertex) {
		this(mg_value_make_node(mg_node_copy(vertex.ptr)));
	}

	/// Constructs a new edge value from the given `edge`.
	this(const ref Relationship edge) {
		this(mg_value_make_relationship(mg_relationship_copy(edge.ptr)));
	}

	/// \brief Constructs an unbounded edge value and takes the ownership of the
	/// given `edge`. \note Behaviour of accessing the `edge` after performing
	/// this operation is considered undefined.
	// explicit Value(UnboundRelationship &&edge);

	/// \brief Constructs a path value and takes the ownership of the given
	/// `path`. \note Behaviour of accessing the `path` after performing this
	/// operation is considered undefined.
	// explicit Value(Path &&path);


	/// \brief Constructs a date value and takes the ownership of the given
	/// `date`. \note Behaviour of accessing the `date` after performing this
	/// operation is considered undefined.
	// explicit Value(Date &&date);

	/// \brief Constructs a time value and takes the ownership of the given
	/// `time`. \note Behaviour of accessing the `time` after performing this
	/// operation is considered undefined.
	// explicit Value(Time &&time);

	/// \brief Constructs a LocalTime value and takes the ownership of the given
	/// `localTime`. \note Behaviour of accessing the `localTime` after performing
	/// this operation is considered undefined.
	// explicit Value(LocalTime &&localTime);

	/// \brief Constructs a DateTime value and takes the ownership of the given
	/// `dateTime`. \note Behaviour of accessing the `dateTime` after performing
	/// this operation is considered undefined.
	// explicit Value(DateTime &&dateTime);

	/// \brief Constructs a DateTimeZoneId value and takes the ownership of the
	/// given `dateTimeZoneId`. \note Behaviour of accessing the `dateTimeZoneId`
	/// after performing this operation is considered undefined.
	// explicit Value(DateTimeZoneId &&dateTimeZoneId);

	/// \brief Constructs a LocalDateTime value and takes the ownership of the
	/// given `localDateTime`. \note Behaviour of accessing the `localDateTime`
	/// after performing this operation is considered undefined.
	// explicit Value(LocalDateTime &&localDateTime);

	/// \brief Constructs a Duration value and takes the ownership of the given
	/// `duration`. \note Behaviour of accessing the `duration` after performing
	/// this operation is considered undefined.
	// explicit Value(Duration &&duration);

	/// \brief Constructs a Point2d value and takes the ownership of the given
	/// `point2d`. \note Behaviour of accessing the `point2d` after performing
	/// this operation is considered undefined.
	// explicit Value(Point2d &&point2d);

	/// \brief Constructs a Point3d value and takes the ownership of the given
	/// `point3d`. \note Behaviour of accessing the `point3d` after performing
	/// this operation is considered undefined.
	// explicit Value(Point3d &&point3d);

	// const ConstList ValueList() const;
	// const ConstMap ValueMap() const;

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
		typeid(Relationship):	tuple(Type.Relationship,
									"Relationship(mg_value_relationship(ptr_))", ""),
		typeid(string):			tuple(Type.String,
									"Detail.convertString(mg_value_string(ptr_))", ""),
	];

	/// Cast this value to type `T`.
	auto opCast(T)() const {
		assert(type() == ops[typeid(T)][0]);
		// return to!T(mixin(ops[typeid(T)][1]));
		return mixin(ops[typeid(T)][1]);
	}

	/// Comparison operator for type `T`.
	/// Note: The code asserts that the current value holds a representation of type `T`.
	bool opEquals(T)(const T val) const {
		assert(type() == ops[typeid(T)][0]);
		return mixin(ops[typeid(T)][1]) == val;
	}

	/// Assignment operator for type `T`.
	void opAssign(T)(inout T value) {
		if (ptr_ != null)
			mg_value_destroy(ptr_);
		ptr_ = mixin(ops[typeid(T)][2])(value);
	}

	/// Comparison operator for another `Value`.
	bool opEquals(const ref Value other) const {
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
			case Type.Double:	return to!string(to!double(this));
			case Type.Node:		return to!string(to!Node(this));
			case Type.Bool:		return to!string(to!bool(this));
			case Type.Int:		return to!string(to!int(this));
			case Type.String:	return Detail.convertString(mg_value_string(ptr_));
			case Type.Relationship:		return to!string(to!Relationship(this));
			case Type.List:		return to!string(to!List(this));
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
	@safe @nogc this(const mg_value *const_ptr) {
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
	List l;
	l ~= Value(123);
	l ~= Value("Hello");
	l ~= Value(3.21);
	l ~= Value(true);
	assert(l.length == 4);

	auto v = Value(l);
	assert(v.type == Type.List);

	assert(v == l);

	auto l2 = to!List(v);
	// auto l2 = to!List(List(mg_value_list(v.ptr_)));
}
